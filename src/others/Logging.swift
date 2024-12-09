
import Foundation
import os.log

enum LogLevel: Int, Sendable {
    case off
    case error
    case warn
    case info
    case debug
}

enum Log {
    static let level: LogLevel = .debug

    static func d(_ message: String, _ values: Any?..., file: StaticString = #file, line: UInt = #line) {
        log(.debug, message, values, file, line)
    }

    static func i(_ message: String, _ values: Any?..., file: StaticString = #file, line: UInt = #line) {
        log(.info, message, values, file, line)
    }
    
    static func w(_ message: String, _ values: Any?..., file: StaticString = #file, line: UInt = #line) {
        log(.warn, message, values, file, line)
    }

    static func e(_ message: String, _ values: Any?..., file: StaticString = #file, line: UInt = #line) {
        log(.error, message, values, file, line)
    }

    // Internal

    private static let formatter = LogFormatter()
    private static let consoleLogger = ConsoleLogger()

    private static func log(_ level: LogLevel, _ message: String, _ values: [Any?], _ file: StaticString, _ line: UInt) {
        guard level.rawValue <= Log.level.rawValue else { return }
        let values = values.compactMap { $0 }
        let text = formatter.format(level, message, values, file, line)
        consoleLogger.log(text, at: level)
    }
}

private final class ConsoleLogger: Sendable {
    private let logger = OSLog(subsystem: AppIdentifier, category: "App")

    func log(_ text: String, at level: LogLevel) {
        #if DEBUG
        if isDebuggerAttached() {
            print(text)
            return
        }
        #endif

        let type: OSLogType
        switch level {
        case .info: type = .default
        case .debug: type = .info
        default: type = .error
        }

        os_log("%{public}@", log: logger, type: type, text)
    }
}

private final class LogFormatter: Sendable {
    private let dateFormatter = DateFormatter()

    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
    }
    
    func format(_ level: LogLevel, _ message: String, _ values: [Any], _ file: StaticString, _ line: UInt) -> String {
        let date = dateFormatter.string(from: Date())
        let thread = Thread.isMainThread ? "" : " <\(threadId)>"
        let file = URL(fileURLWithPath: file.description).deletingPathExtension().lastPathComponent
        let extra = values.isEmpty ? "" : " [" + values.map { String(describing: $0) }.joined(separator: ", ") + "]"
        return String(format: "%@ %@%@ [%@:%d]  %@%@", date, level.tag, thread, file, line, message, extra)
    }
    
    private var threadId: UInt64 {
        var threadId: UInt64 = 0
        pthread_threadid_np(nil, &threadId)
        return threadId
    }
}

extension LogLevel {
    var tag: String {
        switch self {
        case .off: return "-"
        case .error: return "E"
        case .warn: return "W"
        case .info: return "I"
        case .debug: return "D"
        }
    }
}

#if DEBUG
private func isDebuggerAttached() -> Bool {
    var mib = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var result = kinfo_proc()
    var size = MemoryLayout.size(ofValue: result)
    guard sysctl(&mib, UInt32(mib.count), &result, &size, nil, 0) == EXIT_SUCCESS else { return false }
    return result.kp_proc.p_flag & P_TRACED != 0
}
#endif
