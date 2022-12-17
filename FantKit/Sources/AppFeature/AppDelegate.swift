import ComposableArchitecture
import Foundation
import Logging

public struct AppDelegateReducer: ReducerProtocol {
    
    public typealias State = UserSettings

    public enum Action: Equatable {
        case didFinishLaunching
    }

    public init() {}
    
    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .didFinishLaunching:
            return .none
        }
    }
}
