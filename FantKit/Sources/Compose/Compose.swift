import SwiftUI
import ComposableArchitecture
import Dependencies
import APIClient
import Post
import Logging

public struct Compose: ReducerProtocol {
    public struct State: Equatable {
        var text: String
        var visibility: Post.State.Visibility
        var dismiss: Bool = false
        
        public init() {
            self.text = ""
            self.visibility = .publicly
            self.dismiss = false
        }
        
    }
    
    public enum Action: Equatable {
        case toot
        case dismiss
        case visibilityChanged(Post.State.Visibility)
        case textChanged(String)
    }
    
    @Dependency(\.apiClient) var apiClient
    
    public init() {}
    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .textChanged(let newText):
                state.text = newText
            case .visibilityChanged(let newVisibilty):
                state.visibility = newVisibilty
                log.debug("New visibility \(newVisibilty)")
            case .toot:
                state.dismiss = false
                return .run { [text = state.text, vis = state.visibility.apiValue] send in
                    let post = try await apiClient.newStatus(text: text, visibility: vis)
                    log.debug("Send post: \(post)")
                    await send(.dismiss)
                }
            case .dismiss:
                state.dismiss = true
                log.debug("Should dismiss")
            }
            
            return .none
        }
    }
}

public struct ComposeView: View {
    public init(store: StoreOf<Compose>) {
        self.store = store
    }
    
    let store: StoreOf<Compose>
    @Environment(\.presentationMode) var presentation
    
    struct ViewState: Equatable {
        var text: String
        var dismiss: Bool
        var visibility: Post.State.Visibility
        init(state: Compose.State) {
            text = state.text
            visibility = state.visibility
            dismiss = state.dismiss
        }
    }
    
    public var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(alignment: .leading) {
                Text("Compose new post:")
                TextField("Title", text: viewStore.binding(
                    get: \.text,
                    send: Compose.Action.textChanged
                ),  axis: .horizontal)
                .lineLimit(1...4)
                Spacer()
                HStack {
                    Picker("", selection: viewStore.binding(
                        get: \.visibility,
                        send: Compose.Action.visibilityChanged
                    )) {
                        ForEach (Post.State.Visibility.allCases, id: \.self) { visibility in
                            Text(visibility.title)
                        }
                    }
                    Button("Post") {
                        viewStore.send(.toot)
                    }
                }
            }
            .onChange(of: viewStore.state.dismiss) { dismiss in
                if dismiss {
                    self.presentation.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct ComposeView_Previews: PreviewProvider {
    static var previews: some View {
        ComposeView(store: .init(initialState: .init(), reducer: Compose()))
            .previewDevice(PreviewDevice(rawValue: "Apple Watch Ultra (49mm)"))
    }
}
