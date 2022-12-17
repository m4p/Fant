import SwiftUI
import ComposableArchitecture
import Dependencies
import Defaults

public struct Settings: ReducerProtocol {
    public struct State: Equatable {
        public init() {
        }
        
    }
    
    public enum Action: Equatable {
        case logout
    }
        
    public init() {}
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .logout:
                Defaults.token = nil
            }
            return .none
        }
    }
}

public struct SettingsView: View {
    let store: StoreOf<Settings>
    @Environment(\.presentationMode) var presentation

    public init(store: StoreOf<Settings>) {
        self.store = store
    }
    
    struct ViewState: Equatable {
        init(state: Settings.State) {
        }
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Text("Coming soon")
            Form {
                Button(action: {
                    viewStore.send(.logout)
                    self.presentation.wrappedValue.dismiss()
                }) {
                    Text("Log out")
                    
                }
            }
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(store: .init(initialState: .init(), reducer: Settings()))
    }
}
