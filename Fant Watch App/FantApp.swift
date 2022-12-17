import SwiftUI
import Logging
import AppFeature
import ComposableArchitecture

@main   
struct Fant_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            AppView(store: self.appDelegate.store)
        }
    }
}

final class AppDelegate: NSObject, ObservableObject, WKApplicationDelegate {
    let store = Store(
        initialState: AppReducer.State(),
        reducer: AppReducer()
    )
    
    var viewStore: ViewStore<Void, AppReducer.Action> {
        ViewStore(self.store.stateless)
    }

    func applicationDidFinishLaunching() {
        LoggingConfiguration.configure()
        self.viewStore.send(.appDelegate(.didFinishLaunching))
    }
}
