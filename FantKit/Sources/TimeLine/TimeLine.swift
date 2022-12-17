import SwiftUI
import ComposableArchitecture
import Post
import Dependencies
import APIClient
import Defaults
import Logging

public struct TimeLine: ReducerProtocol {
    
    public struct State: Equatable, Identifiable {
        public var id: UUID = UUID()
        public var posts: IdentifiedArrayOf<Post.State> = []
        public var host: URL?
        public var type: TimeLineType
        
        var loading: Bool = false
        var canLoadMore: Bool = true
        
        public enum TimeLineType: Equatable {
            case home
            case local(URL)
            case federated(URL)
            
            public var title: String {
                switch self {
                case .home:
                    return "Home"
                case .federated(let host):
                    if Defaults.host == host {
                        return "Federated"
                    } else {
                        return host.host ?? ""
                    }
                case .local(let host):
                    if Defaults.host == host {
                        return "Local"
                    } else {
                        return host.host  ?? ""
                    }
                }
            }
            
            func getPosts(apiClient: APIClient, sinceId: String? = nil, maxId: String? = nil) async throws -> [Post.State] {
                switch self {
                case .home:
                    return try await apiClient.homeTimeLine(maxId: maxId, sinceId: sinceId)
                case .local(let host):
                    return try await apiClient.localTimeLine(host: host, maxId: maxId, sinceId: sinceId)
                case .federated(let host):
                    return try await apiClient.federatedTimeLine(host: host, maxId: maxId, sinceId: sinceId)
                }
            }
        }
        
        public init(host: URL? = nil, type: TimeLineType) {
            self.host = host
            self.posts = []
            self.type = type
            self.id = UUID()
        }
        
        public static var preview: Self {
            return .init(host: URL(string: "https://xoxo.zone")!, type: .home)
        }
    }
    
    public enum Action: Equatable {
        case noop
        case newPosts(IdentifiedArrayOf<Post.State>, Bool = true)
        case post(id: Post.State.ID, action: Post.Action)
        case load(sinceId: String?, maxId: String?)
    }
    
    @Dependency(\.apiClient) var apiClient
    
    public init() {}
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .noop:
                return .none
            case .load(let sinceId, let maxId):
                guard !state.loading else { return .none }
                state.loading = true
                return .run {[timeLineType = state.type, oldPosts = state.posts] send in
                    if let posts = try? await timeLineType.getPosts(apiClient: apiClient, sinceId: sinceId, maxId: maxId) {
                        var newPosts = oldPosts
                        if maxId != nil {
                            posts.forEach { newPosts.updateOrAppend($0) }
                        } else {
                            posts.reversed().forEach { newPosts.updateOrInsert($0, at: 0) }
                        }
                        await send(.newPosts(newPosts, maxId != nil))
                    }
                }
            case .newPosts(let posts, let bottom):
                if bottom, state.posts.count == posts.count {
                    state.canLoadMore = false
                }
                state.posts = posts
                state.loading = false
                return .none
            case .post:
                return .none
            }
        }
        .forEach(\.posts, action: /Action.post) {
            Post()
        }
    }
}

public struct TimeLineView: View {
    let store: StoreOf<TimeLine>
    
    public init(store: StoreOf<TimeLine>) {
        self.store = store
    }
    
    struct ViewState: Equatable {
        var posts: [Post.State]
        var loading: Bool
        var canLoadMore: Bool
        init(state: TimeLine.State) {
            self.posts = state.posts.elements
            self.loading = state.loading
            self.canLoadMore = state.canLoadMore
        }
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView {
                LazyVStack {
                    Spacer()
                        .onAppear{
                            let firstId = viewStore.posts.first?.id
                            viewStore.send(.load(sinceId: firstId, maxId: nil))
                        }
                    if viewStore.loading {
                        ProgressView()
                            .padding()
                    }
                    ForEachStore(
                        self.store.scope(state: \.posts, action: TimeLine.Action.post(id:action:))
                    ) { post in
                        PostView(store: post)
                    }
                    if viewStore.canLoadMore, !viewStore.posts.isEmpty {
                        ProgressView()
                            .padding()
                            .onAppear{
                                let lastId = viewStore.posts.last?.id
                                viewStore.send(.load(sinceId: nil, maxId: lastId))
                            }
                    }
                }
            }
        }
    }
}

struct TimeLineView_Previews: PreviewProvider {
    static var previews: some View {
        TimeLineView(store: .init(initialState: .preview,
                                  reducer: TimeLine()))
        .previewDevice(PreviewDevice(rawValue: "Apple Watch Ultra (49mm)"))
        .navigationBarTitle(Text("Home"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
