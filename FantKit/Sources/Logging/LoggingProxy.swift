import Foundation
import os.signpost
import Willow

extension LogLevel {
    var enabled: Bool {
        // supported logging levels: debug, info, event, warn, error
        let disabledLevels = ProcessInfo.processInfo.environment["LOGGING_DISABLED_LEVELS"]?.lowercased() ?? ""
        return !disabledLevels.contains(self.description.lowercased())
    }
}

public struct LoggingProxy {

    public func trace(file: String = #file, function: String = #function, line: Int = #line, subsystem: LoggingSubsystem? = nil) {
        event("", file: file, function: function, line: line, subsystem: subsystem)
    }

    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line, subsystem: LoggingSubsystem? = nil) {
        guard LogLevel.debug.enabled else { return }
        #if DEBUG
        logger(forSubsystem: subsystem, fallbackFilename: file)?.debugMessage(self.format(message: message, file: file, function: function, line: line))
        #endif
    }

    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line, subsystem: LoggingSubsystem? = nil) {
        guard LogLevel.info.enabled else { return }
        let message = self.format(message: message, file: file, function: function, line: line)
        logger(forSubsystem: subsystem, fallbackFilename: file)?.infoMessage(message)
    }

    public func event(_ message: String, file: String = #file, function: String = #function, line: Int = #line, subsystem: LoggingSubsystem? = nil) {
        guard LogLevel.event.enabled else { return }
        let message = self.format(message: message, file: file, function: function, line: line)
        logger(forSubsystem: subsystem, fallbackFilename: file)?.eventMessage(message)
    }

    public func warn(_ message: String, file: String = #file, function: String = #function, line: Int = #line, subsystem: LoggingSubsystem? = nil) {
        guard LogLevel.warn.enabled else { return }
        let message = self.format(message: message, file: file, function: function, line: line)
        logger(forSubsystem: subsystem, fallbackFilename: file)?.warnMessage(message)
    }

    public func error(_ message: String, _ error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line, subsystem: LoggingSubsystem? = nil) {
        guard LogLevel.error.enabled else { return }
        if let error = error {
            logger(forSubsystem: subsystem, fallbackFilename: file)?.errorMessage(self.format(message: "\(message): \(error)", file: file, function: function, line: line))
        } else {
            logger(forSubsystem: subsystem, fallbackFilename: file)?.errorMessage(self.format(message: message, file: file, function: function, line: line))
        }
    }

    /// Create a signpost that shows up in Instruments' Points of Interest instrument
    public func pointOfInterest(_ type: OSSignpostType = .event, name: StaticString = #function) {
        #if DEBUG
        os_signpost(type, log: OSLog(subsystem: "dev.lovinggrace.signpost", category: "PointsOfInterest"), name: name)
        #endif
    }

    private func format(message: String, file: String, function: String, line: Int) -> String {
        #if DEBUG
        return "\(message) [\(sourceFileName(filePath: file)) \(function):\(line)]"
        #else
        // logging filenames and lines is discouraged in os_log()
        return message
        #endif
    }

    private func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return (components.isEmpty ? "" : components.last) ?? ""
    }

    private func logger(forSubsystem subsystem: LoggingSubsystem?, fallbackFilename filename: String) -> Willow.Logger? {
        if let subsystem = subsystem {
            return subsystem.logger
        } else {
            return LoggingSubsystem.from(filename: filename).logger
        }
    }
}
