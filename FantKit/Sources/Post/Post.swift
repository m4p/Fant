import SwiftUI
import ComposableArchitecture
import HTML2Markdown
import Logging
import WatchKit
import Kingfisher
import ImageCDN
import MastodonSwift

public struct Post: ReducerProtocol {
    public struct State: Equatable, Identifiable {
        public var id: String
        public var postText: String
        public var dateCreated: Date
        public var booster: Account?
        public var author: Account
        public var visiblity: Visibility = .publicly
        public var imageAttachments: [URL] = []
        
        public struct Account: Equatable {
            public init(name: String, mastondonId: String, avatarURL: URL? = nil) {
                self.name = name
                self.mastondonId = mastondonId
                self.avatarURL = avatarURL
            }
            
            public var name: String
            public var mastondonId: String
            public var avatarURL: URL?
        }
        
        public enum Visibility: CaseIterable {
            case publicly
            case unlisted
            case privatly
            case direct
        }
        
        public init(id: String = UUID().uuidString,
                    author: Account,
                    booster: Account? = nil,
                    postText: String,
                    dateCreated: Date = .now,
                    images: [URL] = [],
                    visibility: Visibility = .publicly) {
            self.id = id
            self.author = author
            self.booster = booster
            self.postText = postText
            self.dateCreated = dateCreated
            self.imageAttachments = images
            self.visiblity = visibility
        }
        
        public static var preview: Self {
            return .init(author: .init(name: "map",
                                       mastondonId: "@map@xoxo.zone"),
                         postText: "Test 1 2 3 4")
        }
    }
    
    public enum Action: Equatable {
        case fav
        case boost
    }
    
    public init() {}
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .boost:
                return .none
            case .fav:
                return .none
            }
        }
    }
}

public struct PostView: View {
    let store: StoreOf<Post>
    
    public init(store: StoreOf<Post>) {
        self.store = store
    }
    
    struct ViewState: Equatable {
        let author: Post.State.Account
        let booster: Post.State.Account?
        let postText: AttributedString
        let dateString: String
        let imageAttachments: [URL]
        let visibility: Post.State.Visibility
        init(state: Post.State) {
            self.author = state.author
            self.booster = state.booster
            let postText = try? state.postText.htmlToString()
            self.postText = postText ?? "Error while parsing HTML"
            self.dateString = state.dateCreated.timeAgo()
            self.imageAttachments = state.imageAttachments
            self.visibility = state.visiblity
        }
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: ViewState.init) { viewStore in
            VStack(alignment: .leading, spacing: 5) {
                if let booster = viewStore.booster {
                    HStack {
                        Text("\(booster.name) boosted:")
                            .font(.footnote)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text(viewStore.author.name)
                            .font(.footnote)
                            .lineLimit(1)
                        Text(viewStore.author.mastondonId)
                            .font(.footnote)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    KFImage
                        .url(viewStore.author.avatarURL?.resized(width: 32))
                        .placeholder {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                        }
                        .resizable()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                }
                Text(viewStore.postText)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                HStack {
                    Text(viewStore.dateString)
                        .font(.footnote)
                    viewStore.visibility.image
                        .resizable()
                        .frame(width: 10.0, height: 10.0)
                }
                if !viewStore.imageAttachments.isEmpty {
                    HStack {
                        VStack{
                            LazyImage(images: viewStore.imageAttachments, index: 0)
                            LazyImage(images: viewStore.imageAttachments, index: 3)
                        }
                        VStack{
                            LazyImage(images: viewStore.imageAttachments, index: 1)
                            LazyImage(images: viewStore.imageAttachments, index: 2)
                        }
                    }
                    .frame(maxHeight: 100)
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                    .padding(.vertical)
                }
            }
            .padding()
            .background(.quaternary)
            .cornerRadius(10)
            .onLongPressGesture {
                log.debug("Long Press")
                WKInterfaceDevice.current().play(WKHapticType.notification)
                
                //TODO: Context menu: fav, bookmark, reply, boost
            }
        }
    }
}

public struct LazyImage: View {
    @State var images: [URL]
    @State var index: Int
    public var body: some View {
        if images.count > index {
            KFImage
                .url(images[index].resized(width: 300))
                .placeholder {
                    ProgressView()
                }
                .resizable()
                .scaledToFill()
                .frame(alignment: .center)
                .aspectRatio(contentMode: .fill)
                .clipped()
        }
    }
}


struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView(store:.init(
            initialState: .preview,
            reducer: Post()
        ))
        .previewDevice(PreviewDevice(rawValue: "Apple Watch Ultra (49mm)"))
    }
}


extension Date {
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension String {
    func htmlToString() throws -> AttributedString {
        let dom = try HTMLParser().parse(html: self)
        let markdown = dom.toMarkdown(options: .unorderedListBullets)
        
        return try AttributedString(markdown: markdown)
    }
}

public extension Post.State.Visibility {
    var image: Image {
        switch self {
        case .publicly:
            return Image(systemName: "globe")
        case .unlisted:
            return Image(systemName: "lock.open")
        case .privatly:
            return Image(systemName: "lock")
        case .direct:
            return Image(systemName: "mail")
        }
    }
    
    var title: String {
        switch self {
        case .publicly:
            return "Public"
        case .unlisted:
            return "Unlisted"
        case .privatly:
            return "Followers"
        case .direct:
            return "Direct"
        }
    }
    
    var apiValue: Mastodon.Statuses.Visibility {
        switch self {
        case .publicly:
            return .pub
        case .unlisted:
            return .unlisted
        case .privatly:
            return .priv
        case .direct:
            return .direct
        }
    }
}
