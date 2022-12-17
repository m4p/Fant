import Foundation
import Willow

public var loggers: [String: Logger] = [:]

public var log = LoggingProxy()

public enum LoggingConfiguration {

    public static func configure() {
        for subsystem in LoggingSubsystem.allCases {
            let subsystemName = subsystem.rawValue
            #if DEBUG
            loggers[subsystemName] = buildDebugLogger(name: subsystemName.capitalized)
            // Disable logger if there is a matching envirmonent variable
            loggers[subsystemName]?.enabled = ProcessInfo.processInfo.environment["LOGGING_\(subsystemName.uppercased())"] != "disable"
            #else
            loggers[subsystemName] = buildReleaseLogger(name: subsystemName.capitalized)
            loggers[subsystemName]?.enabled = true
            #endif
        }
    }

    private static func buildDebugLogger(name: String) -> Logger {
        let emojiModifier = LoggingEmojiModifier(name: name)
        let consoleWriter = ConsoleWriter(modifiers: [emojiModifier])

        return Logger(logLevels: [.all], writers: [consoleWriter], executionMethod: .synchronous(lock: NSRecursiveLock()))
    }

    private static func buildReleaseLogger(name: String) -> Logger {
        let osLogWriter = OSLogWriter(subsystem: "com.deutschegrammophon.DG-Stage", category: name)
        let appLogLevels: LogLevel = [.event, .info, .warn, .error]
        let asynchronousExecution: Logger.ExecutionMethod = .asynchronous(
            queue: DispatchQueue(label: "com.deutschegrammophon.DG-Stage.logging", qos: .utility)
        )

        return Logger(logLevels: appLogLevels, writers: [osLogWriter], executionMethod: asynchronousExecution)
    }
}
