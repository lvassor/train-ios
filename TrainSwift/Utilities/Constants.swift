//
//  Constants.swift
//  TrainSwift
//
//  App-wide constants to avoid magic numbers and strings
//

import Foundation

// MARK: - Timing Constants

enum TimingConstants {
    /// Debounce delay for user input (500ms)
    static let debounceDelay: UInt64 = 500_000_000 // nanoseconds

    /// Default animation duration
    static let animationDuration: TimeInterval = 0.3

    /// Spring animation response
    static let springResponse: Double = 0.4

    /// Spring animation damping
    static let springDamping: Double = 0.8
}

// MARK: - Workout Constants

enum WorkoutConstants {
    /// Default rest time between sets (seconds)
    static let defaultRestSeconds: Int = 90

    /// Minimum sets required to evaluate progression prompt
    static let minimumSetsForPrompt: Int = 3

    /// Default number of sets per exercise
    static let defaultSetsPerExercise: Int = 3

    /// Default rep range minimum
    static let defaultRepMin: Int = 8

    /// Default rep range maximum
    static let defaultRepMax: Int = 12
}

// MARK: - UI Constants

enum UIConstants {
    /// Maximum lines for exercise name display
    static let exerciseNameMaxLines: Int = 2

    /// Progress view scale factor
    static let progressViewScale: CGFloat = 1.5

    /// Icon size for small icons
    static let smallIconSize: CGFloat = 16

    /// Icon size for medium icons
    static let mediumIconSize: CGFloat = 20

    /// Icon size for large icons
    static let largeIconSize: CGFloat = 32

    /// Icon size for extra large icons
    static let xlargeIconSize: CGFloat = 48
}

// MARK: - Validation Constants

enum ValidationConstants {
    /// Minimum password length
    static let minPasswordLength: Int = 6

    /// Minimum age for users
    static let minUserAge: Int = 18

    /// Maximum age for users
    static let maxUserAge: Int = 80
}
