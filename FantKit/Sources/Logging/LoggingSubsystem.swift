import Willow

public enum LoggingSubsystem: String, CaseIterable {
    case appflow
    case devtool
    case general
    case notifications
    case network
    case intents
    case objc
    case ui

    var logger: Logger? {
        guard let subsystemLogger = loggers[self.rawValue] else { return loggers[LoggingSubsystem.general.rawValue] }
        return subsystemLogger
    }

    /// Returns an array of String, that trigger use of the corresponding subsystem.
    /// I.e. .player => ["Play"] causes all Files named *Play* to log to the .player subsystem
    var filenameMatchHeuristicStrings: [String] {
        switch self {
        case .appflow:
            return ["AppDelegate", "SceneDelegate"]
        case .intents:
            return ["Intent"]
        case .notifications:
            return ["Notification"]
        case .devtool:
            return ["DebugSettings"]
        case .network:
            return ["Network", "SyncQueue", "Response"]
        case .ui:
            return ["View.swift", "Cell.swift"]
        default:
            return []
        }
    }

    /// This method tries to guess which subsystem should be used based on the Filename triggering the log
    static func from(filename: String) -> LoggingSubsystem {
        for subsystem in LoggingSubsystem.allCases {
            if !(subsystem.filenameMatchHeuristicStrings.filter { filename.contains($0) }.isEmpty) {
                return subsystem
            }
        }
        return .general
    }
}
