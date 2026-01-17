import Foundation
import os.log

public enum LogCategory: String {
    case app = "App"
    case audio = "Audio"
    case transcription = "Transcription"
    case model = "Model"
    case clipboard = "Clipboard"
    case accessibility = "Accessibility"
    case ui = "UI"
}

public final class Logger: @unchecked Sendable {
    public static let shared = Logger()

    private let subsystem = "com.kin-yee.spezhe"
    private let loggers: [LogCategory: os.Logger]

    private init() {
        var tempLoggers: [LogCategory: os.Logger] = [:]
        for category in [LogCategory.app, .audio, .transcription, .model, .clipboard, .accessibility, .ui] {
            tempLoggers[category] = os.Logger(subsystem: subsystem, category: category.rawValue)
        }
        loggers = tempLoggers
    }

    private func logger(for category: LogCategory) -> os.Logger {
        loggers[category] ?? os.Logger(subsystem: subsystem, category: category.rawValue)
    }

    public func debug(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger(for: category).debug("[\(fileName):\(line)] \(function) - \(message)")
    }

    public func info(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger(for: category).info("[\(fileName):\(line)] \(function) - \(message)")
    }

    public func warning(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger(for: category).warning("[\(fileName):\(line)] \(function) - \(message)")
    }

    public func error(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger(for: category).error("[\(fileName):\(line)] \(function) - \(message)")
    }

    public func fault(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger(for: category).fault("[\(fileName):\(line)] \(function) - \(message)")
    }
}

// Convenience global functions
public func logDebug(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, category: category, file: file, function: function, line: line)
}

public func logInfo(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.info(message, category: category, file: file, function: function, line: line)
}

public func logWarning(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.warning(message, category: category, file: file, function: function, line: line)
}

public func logError(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, category: category, file: file, function: function, line: line)
}
