import Foundation
import Logging
import MastodonSwift
import Post
import Dependencies
import XCTestDynamicOverlay
import Defaults

extension DependencyValues {
    public var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}

extension APIClient: TestDependencyKey {
    public static let previewValue = Self.noop
    
    public static let testValue = Self(
        signInImplementation: XCTUnimplemented("\(Self.self).signInImplementation"),
        homeTimeLineImplementation: XCTUnimplemented("\(Self.self).homeTimeLineImplementation"),
        localTimeLineImplementation: XCTUnimplemented("\(Self.self).localTimeLineImplementation"),
        federatedTimeLineImplementation: XCTUnimplemented("\(Self.self).federatedTimeLineImplementation"),
        newStatusImplementation: {_, _, _, _, _, _, _ in return Post.State.preview}
    )
}

extension APIClient {
    public static let noop = Self(
        signInImplementation: { _, _, _ in
            return nil },
        homeTimeLineImplementation: {_, _, _ in return [.preview, .preview, .preview, .preview]},
        localTimeLineImplementation: {_, _, _, _ in return [.preview, .preview, .preview, .preview]},
        federatedTimeLineImplementation: {_, _, _, _ in return [.preview, .preview, .preview, .preview]},
        newStatusImplementation: {_, _, _, _, _, _, _ in return Post.State.preview}
    )
}

public enum APIError: Swift.Error {
    case notAuthenticated
    case noHostSpecified
}

public protocol FantMastondonClient {
    func getHomeTimeline(maxId: StatusId?, sinceId: StatusId?) async throws -> [Status]
    func getPublicTimeline(isLocal: Bool, maxId: StatusId?, sinceId: StatusId?) async throws -> [Status]
    func getTagTimeline(tag: String, isLocal: Bool, maxId: StatusId?, sinceId: StatusId?) async throws -> [Status]
    func toot(text: String, inReplyToId: String?, mediaIds: [String]?, sensitve: Bool, contentWarning: String, visibility: Mastodon.Statuses.Visibility) async throws -> Status
}

public struct APIClient {
    public init(signInImplementation: @escaping @Sendable (String, String, URL) async throws -> FantMastondonClient?, homeTimeLineImplementation: @escaping @Sendable (String?, String?, FantMastondonClient?) async throws -> [Post.State], localTimeLineImplementation: @escaping @Sendable (URL?, String?, String?, FantMastondonClient?) async throws -> [Post.State], federatedTimeLineImplementation: @escaping @Sendable (URL?, String?, String?, FantMastondonClient?) async throws -> [Post.State], newStatusImplementation: @escaping @Sendable (String, String?, [String]?, Bool, String, Mastodon.Statuses.Visibility, FantMastondonClient?) async throws -> Post.State) {
        self.signInImplementation = signInImplementation
        self.homeTimeLineImplementation = homeTimeLineImplementation
        self.localTimeLineImplementation = localTimeLineImplementation
        self.federatedTimeLineImplementation = federatedTimeLineImplementation
        self.newStatusImplementation = newStatusImplementation
    }
    
    public static var authenticatedClient: FantMastondonClient?
    public static var apps: [URL: MastodonSwift.App] = [:]
    
    public var signInImplementation: @Sendable (String, String, URL) async throws -> FantMastondonClient?
    public var homeTimeLineImplementation: @Sendable (String?, String?, FantMastondonClient?) async throws -> [Post.State]
    public var localTimeLineImplementation: @Sendable (URL?, String?, String?, FantMastondonClient?) async throws -> [Post.State]
    public var federatedTimeLineImplementation: @Sendable (URL?, String?, String?, FantMastondonClient?) async throws -> [Post.State]
    public var newStatusImplementation: @Sendable (String, String?, [String]?, Bool, String, Mastodon.Statuses.Visibility, FantMastondonClient?) async throws -> Post.State
    
    public func signIn(user: String, password: String, host: URL) async throws -> Void {
        APIClient.authenticatedClient = try await signInImplementation(user, password, host)
        return
    }
    
    public func homeTimeLine(maxId: String? = nil, sinceId: String? = nil) async throws -> [Post.State] {
        return try await homeTimeLineImplementation(maxId, sinceId, APIClient.authenticatedClient)
    }
    
    public func localTimeLine(host: URL? = nil, maxId: String? = nil, sinceId: String? = nil) async throws -> [Post.State] {
        return try await localTimeLineImplementation(host, maxId, sinceId, APIClient.authenticatedClient)
    }
    
    public func federatedTimeLine(host: URL? = nil, maxId: String? = nil, sinceId: String? = nil) async throws -> [Post.State] {
        return try await federatedTimeLineImplementation(host, maxId, sinceId, APIClient.authenticatedClient)
    }
    
    public func newStatus(text: String,
                          inReplyToId: String? = nil,
                          mediaIds: [String]? = nil,
                          sensitve: Bool = false,
                          contentWarning: String = "",
                          visibility: Mastodon.Statuses.Visibility = .pub) async throws -> Post.State {
        return try await newStatusImplementation(text, inReplyToId, mediaIds, sensitve, contentWarning, visibility, APIClient.authenticatedClient)
    }
}
