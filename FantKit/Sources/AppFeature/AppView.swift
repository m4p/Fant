import ComposableArchitecture
import SwiftUI
import Logging
import TimeLine
import APIClient
import SignIn
import Compose
import Settings
import Constants
import Defaults

public struct AppReducer: ReducerProtocol {
    
    public struct State: Equatable {
        @BindingState public var userSettings: UserSettings
        
        var signIn: SignIn.State
        var compose: Compose.State
        var settings: Settings.State
        var loading: Bool = true
        var timeLines: IdentifiedArrayOf<TimeLine.State> = []
        
        public init() {
            self.userSettings = UserSettings()
            self.signIn = SignIn.State()
            self.compose = Compose.State()
            self.settings = Settings.State()
            self.timeLines = []
            self.loading = signIn.needsToSignIn
        }
    }
    
    public enum Action: Equatable {
        case appDelegate(AppDelegateReducer.Action)
        case signIn(SignIn.Action)
        case compose(Compose.Action)
        case settings(Settings.Action)
        case timeLine(id: TimeLine.State.ID, action: TimeLine.Action)
        case checkAuth
    }
    
    @Dependency(\.date.now) var now
    @Dependency(\.apiClient) var apiClient
    
    public init() {}
    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.userSettings, action: /Action.appDelegate) {
            AppDelegateReducer()
        }
        Scope(state: \.signIn, action: /Action.signIn) {
            SignIn()
        }
        Scope(state: \.compose, action: /Action.compose) {
            Compose()
        }
        Scope(state: \.settings, action: /Action.settings) {
            Settings()
        }
        Reduce { state, action in
            switch action {
            case .appDelegate(.didFinishLaunching):
                return .run { send in
                    await send(.signIn(.check))
                }
            case .signIn(.signedIn):
                if let host = Defaults.host {
                    state.timeLines = [TimeLine.State(type: .home),
                                       TimeLine.State(type: .local(host)),
                                       TimeLine.State(type: .federated(host))]
                }
                state.loading = false
                return .none
            case .checkAuth:
                if !Defaults.hasToken {
                    return .run { send in
                        await send(.signIn(.check))
                    }
                }
                return .none
            default:
                return .none
            }
        }
        .forEach(\.timeLines, action: /Action.timeLine) {
            TimeLine()
        }
    }
}

public struct AppView: View {
    let store: StoreOf<AppReducer>
    
    public init(store: StoreOf<AppReducer>) {
        self.store = store
    }
    
    struct ViewState: Equatable {
        var loading: Bool
        var timelines: [TimeLine.State]
        var signIn: SignIn.State
        
        init(state: AppReducer.State) {
            self.loading = state.loading
            self.timelines = state.timeLines.elements
            self.signIn = state.signIn
        }
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: ViewState.init) { viewStore in
            NavigationView {
                if viewStore.signIn.needsToSignIn {
                    SignInView(store: self.store.scope(
                        state: \.signIn,
                        action: AppReducer.Action.signIn
                    ))
                } else if viewStore.state.loading {
                    ProgressView()
                } else {
                    List {
                        NavigationLink(
                            destination: ComposeView(store: self.store.scope(
                                state: \.compose,
                                action: AppReducer.Action.compose
                            ))
                            .navigationBarTitle(Text(MainMenuListItemType.compose.title))
                            .navigationBarTitleDisplayMode(.inline),
                            label: { MainMenuListItem(type: .compose) }
                        )
                        
                        ForEachStore(
                            self.store.scope(
                                state: \.timeLines,
                                action: AppReducer.Action.timeLine(id:action:)
                            ),
                            content: { store in
                                let timeLineViewStore = ViewStore<TimeLine.State, TimeLine.Action>(store)
                                NavigationLink(
                                    destination: TimeLineView(store: store)
                                        .navigationBarTitle(Text(timeLineViewStore.type.title))
                                        .navigationBarTitleDisplayMode(.inline)
                                        .onAppear{ viewStore.send(AppReducer.Action.timeLine(id: timeLineViewStore.id, action: .load(sinceId: nil, maxId: nil)))
                                        }
                                    ,
                                    label: { MainMenuListItem(type: .timeline(timeLineViewStore.type)) }
                                )
                                
                            }
                        )
                        
                        NavigationLink(
                            destination: SettingsView(store: self.store.scope(
                                state: \.settings,
                                action: AppReducer.Action.settings
                            ))
                            .navigationBarTitle(Text(MainMenuListItemType.settings.title))
                            .navigationBarTitleDisplayMode(.inline),
                            label: { MainMenuListItem(type: .settings) }
                        )
                    }
                    .navigationBarTitle(Text(Constants.appName))
                }
            }
            .onAppear {
                viewStore.send(.checkAuth)
            }
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(
            store: .init(
                initialState: .init(),
                reducer: AppReducer()
            )
        )
    }
}
