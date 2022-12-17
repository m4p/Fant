import SwiftUI
import ComposableArchitecture
import Dependencies
import APIClient
import Logging
import Defaults

public struct SignIn: ReducerProtocol {
    public struct State: Equatable {
        public init(email: String = Defaults.email,
                    password: String = Defaults.password,
                    host: URL = Defaults.host!,
                    needsToSignIn: Bool = !Defaults.hasToken) {
            
            self.email = email
            self.password = password
            self.host = host
            self.needsToSignIn = needsToSignIn
            self.canSignIn = validate()
        }
        
        var email: String = ""
        var password: String = ""
        var host: URL
        
        public var needsToSignIn: Bool = true
        public var canSignIn: Bool = false
        
        func validate() -> Bool {
            guard !email.isEmpty,
                  !password.isEmpty else { return false}
            return true
        }
    }
    
    public enum Action: Equatable {
        case signIn
        case signedIn
        case check
        case hostChanged(String)
        case emailChanged(String)
        case passwordChanged(String)
    }
    
    @Dependency(\.apiClient) var apiClient
    
    public init() {}
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .signIn:
                return .run { [host = state.host, email = state.email, password = state.password] send in
                    do {
                        try await apiClient.signIn(user: email,
                                                   password: password,
                                                   host: host)
                        Defaults.host = host
                        Defaults.password = password
                        Defaults.email = email
                        await send(.signedIn)
                    } catch {
                        log.error("Error while signing in", error)
                        log.error("This is currently most likely to 2FA being enabled. Disable temporarily to login.")
                        // TODO: Alert user
                    }
                }
            case .signedIn:
                state.needsToSignIn = false
            case .hostChanged(let host):
                var hostString = host
                if !hostString.hasPrefix("http") {
                    hostString = "https://" + hostString
                }
                if let url = URL(string: hostString) { state.host = url }
                state.canSignIn = state.validate()
            case .emailChanged(let email):
                state.email = email
                state.canSignIn = state.validate()
            case .passwordChanged(let password):
                state.password = password
                state.canSignIn = state.validate()
            case .check:
                log.debug("Needs to Signin: \(state.needsToSignIn)")
                return .run { [needsInteractiveSignIn = state.needsToSignIn] send in
                    if !needsInteractiveSignIn {
                        await send(.signIn)
                    }
                }
            }
            
            return .none
        }
    }
}

public struct SignInView: View {
    let store: StoreOf<SignIn>
    
    public init(store: StoreOf<SignIn>) {
        self.store = store
    }
    
    struct ViewState: Equatable {
        var email: String
        var password: String
        var host: String
        var canSignIn: Bool

        init(state: SignIn.State) {
            self.email = state.email
            self.host = state.host.absoluteString
            self.password = state.password
            self.canSignIn = state.canSignIn
        }
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack {
                    Text("Please sign in")
                    TextField("Host", text: viewStore.binding(get: { $0.host.absoluteString }, send: SignIn.Action.hostChanged))
                    TextField("Email", text: viewStore.binding(get: { $0.email }, send: SignIn.Action.emailChanged))
                    SecureField("Password", text: viewStore.binding(get: { $0.password }, send: SignIn.Action.passwordChanged))
                    Button(action: { viewStore.send(.signIn)}) {
                        Text("Sign In")
                    }.disabled(!viewStore.canSignIn)
                        .padding(.vertical, 15)
                }
            }
            .onAppear {
                viewStore.send(.check)
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(store: .init(initialState: .init(),
                                reducer: SignIn()))
    }
}
