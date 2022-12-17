import Foundation
import Willow

struct LoggingEmojiModifier: LogModifier {

    var timestamp: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SS"
        return dateFormatter.string(from: Date())
    }

    let name: String

    func modifyMessage(_ message: String, with logLevel: LogLevel) -> String {
        let logLevelEmoji: String
        switch logLevel {
        case .debug:
            logLevelEmoji = "🐞"
        case .info:
            logLevelEmoji = "💡"
        case .event:
            logLevelEmoji = "🗓"
        case .warn:
            logLevelEmoji = "⚠️"
        case .error:
            logLevelEmoji = "⛔️"
        default:
            logLevelEmoji = "✏️"
        }
        return "🐘 \(logLevelEmoji) [\(name)] [\(timestamp)] => \(message)"
    }
}
