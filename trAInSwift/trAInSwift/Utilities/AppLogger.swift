//
//  AppLogger.swift
//  trAInSwift
//
//  Unified logging utility using OSLog
//

import Foundation
import OSLog

/// Centralized logging utility for the app
/// Replaces scattered print() statements with structured logging
struct AppLogger {

    // MARK: - Log Categories

    static let auth = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.train.app", category: "Authentication")
    static let workout = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.train.app", category: "Workout")
    static let program = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.train.app", category: "Program")
    static let database = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.train.app", category: "Database")
    static let ui = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.train.app", category: "UI")
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.train.app", category: "Network")

    // MARK: - Convenience Methods

    /// Log authentication events
    static func logAuth(_ message: String, level: LogLevel = .info) {
        log(message, to: auth, level: level)
    }

    /// Log workout-related events
    static func logWorkout(_ message: String, level: LogLevel = .info) {
        log(message, to: workout, level: level)
    }

    /// Log program generation events
    static func logProgram(_ message: String, level: LogLevel = .info) {
        log(message, to: program, level: level)
    }

    /// Log database operations
    static func logDatabase(_ message: String, level: LogLevel = .info) {
        log(message, to: database, level: level)
    }

    /// Log UI events
    static func logUI(_ message: String, level: LogLevel = .info) {
        log(message, to: ui, level: level)
    }

    // MARK: - Private Helpers

    private static func log(_ message: String, to logger: Logger, level: LogLevel) {
        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .notice:
            logger.notice("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        case .fault:
            logger.fault("\(message)")
        }
    }
}

// MARK: - Log Level

enum LogLevel {
    case debug
    case info
    case notice
    case warning
    case error
    case fault
}
