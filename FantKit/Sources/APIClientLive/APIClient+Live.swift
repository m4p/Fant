import Foundation
import APIClient
import Dependencies
import MastodonSwift
import Logging
import Post
import Defaults
import Constants

extension MastodonClient {
    func createApp(scopes: Scopes) async throws ->  MastodonSwift.App {
        return try await self.createApp(named: Constants.appName, scopes: scopes, website: Constants.appWebsite)
    }
}

extension APIClient {
    static func app(host: URL, scopes: Scopes = ["read"]) async throws -> (MastodonClient, MastodonSwift.App) {
        let client = MastodonClient(baseURL: host)
        if let app = APIClient.apps[host] {
            return (client, app)
        } else {
            let app = try await client.createApp(scopes: scopes)
            // TODO: Make thread safe
            // APIClient.apps[host] = app
            return (client, app)
        }
    }
}

extension APIClient: DependencyKey {
    public static let liveValue = Self(signInImplementation: { user, password, host  in
        do {
            let scopes = ["read", "write", "follow"]
            let (client, app) = try await APIClient.app(host: host, scopes: scopes)
            if let token = Defaults.token {
                return FantMastodonClient(baseURL: host,token: token)
            } else {
                let response = try await client.getToken(withApp: app, username: user, password: password, scope: scopes)
                let authClient = FantMastodonClient(baseURL: host, token: response.token)
                Defaults.token = response.token
                return authClient
            }
        } catch {
            log.error("Error signing in.", error)
            Defaults.token = nil
            throw(error)
        }
    }, homeTimeLineImplementation: { maxId, sinceId, authenticatedClient in
        guard let authenticatedClient else { throw( APIError.notAuthenticated )}
        let timeline = try await authenticatedClient.getHomeTimeline(maxId: maxId, sinceId: sinceId)
        return timeline.map{ Post.State(status: $0) }
    }, localTimeLineImplementation: {host, maxId, sinceId, authenticatedClient in
        // TODO: Figure out how to get local timelines from different instance
        guard let authenticatedClient else { throw( APIError.notAuthenticated )}
        guard let host else { throw APIError.noHostSpecified }
        let (client, app) = try await APIClient.app(host: host)
        let timeline = try await authenticatedClient.getPublicTimeline(isLocal: true, maxId: maxId, sinceId: sinceId)
        return timeline.map{ Post.State(status: $0) }
    }, federatedTimeLineImplementation: {host, maxId, sinceId, authenticatedClient in
        // TODO: Figure out how to get local timelines from different instance
        guard let authenticatedClient else { throw( APIError.notAuthenticated )}
        guard let host else { throw APIError.noHostSpecified }
        let (client, app) = try await APIClient.app(host: host)
        let timeline = try await authenticatedClient.getPublicTimeline(isLocal: false, maxId: maxId, sinceId: sinceId)
        return timeline.map{ Post.State(status: $0) }
    }, newStatusImplementation: { text, inReplyToId, mediaIds, sensitve, contentWarning, visibility, authenticatedClient in
        guard let authenticatedClient else { throw( APIError.notAuthenticated )}
        let status = try await authenticatedClient.toot(text: text, inReplyToId: inReplyToId, mediaIds: mediaIds, sensitve: sensitve, contentWarning: contentWarning, visibility: visibility)
        return Post.State(status: status)
    }
    )
}

public extension Post.State {
    init(status: Status) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let isBoost = status.reblog != nil
        
        let author = Account(name: status.account?.username ?? "",
                             mastondonId: status.account?.acct ?? "",
                             avatarURL: status.account?.avatar)
        
        var boostAuthor: Account? = nil
        var attachments = status.mediaAttachments
        if let boostAccount = status.reblog?.account {
            boostAuthor = Account(name: boostAccount.username,
                                  mastondonId: boostAccount.acct,
                                  avatarURL: boostAccount.avatar)
        }
        if let boostedAttachments = status.reblog?.mediaAttachments {
            attachments = boostedAttachments
        }
    
        let images = attachments.filter({ $0.type == .image }).compactMap{ $0.previewUrl }
        log.debug("\(dump(status))")

        self.init(id: status.id,
                  author: isBoost ? boostAuthor ?? author : author,
                  booster: isBoost ? author : nil,
                  postText: isBoost ? status.reblog?.content ?? status.content : status.content,
                  dateCreated: formatter.date(from: status.createdAt) ?? .now,
                  images: images,
                  visibility: status.visibility.converted)
    }
}

public extension Status.Visibility {
    var converted: Post.State.Visibility {
        switch self {
        case .pub:
            return .publicly
        case .unlisted:
            return .unlisted
        case .priv:
            return .privatly
        case .direct:
            return .direct
        }
    }
}
