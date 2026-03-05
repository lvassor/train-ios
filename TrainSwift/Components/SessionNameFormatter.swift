//
//  SessionNameFormatter.swift
//  TrainSwift
//
//  Shared utility for session name formatting
//

import Foundation

struct SessionNameFormatter {
    /// Returns an abbreviation for a session name (e.g., "Push" -> "PU", "Upper Body" -> "UB")
    static func abbreviation(for sessionName: String) -> String {
        switch sessionName.lowercased() {
        case "push": return "PU"
        case "pull": return "PL"
        case "legs": return "LG"
        case "upper", "upper body": return "UB"
        case "lower", "lower body": return "LB"
        case "full body": return "FB"
        default: return String(sessionName.prefix(2)).uppercased()
        }
    }
}
