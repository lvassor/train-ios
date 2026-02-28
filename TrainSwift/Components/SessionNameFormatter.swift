//
//  SessionNameFormatter.swift
//  TrainSwift
//
//  Shared utility for session name formatting
//

import Foundation

struct SessionNameFormatter {
    /// Returns an abbreviation for a session name (e.g., "Push" -> "P", "Upper Body" -> "U")
    static func abbreviation(for sessionName: String) -> String {
        switch sessionName.lowercased() {
        case "push": return "P"
        case "pull": return "Pu"
        case "legs": return "L"
        case "upper", "upper body": return "U"
        case "lower", "lower body": return "Lo"
        case "full body": return "FB"
        default: return String(sessionName.prefix(1)).uppercased()
        }
    }
}
