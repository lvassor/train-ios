//
//  Programme.swift
//  trAInApp
//
//  Created by Claude Code on 2025-10-06.
//

import Foundation

struct Programme: Codable {
    let name: String
    let days: [String: Session]

    var sortedDays: [(key: String, value: Session)] {
        days.sorted { Int($0.key) ?? 0 < Int($1.key) ?? 0 }
    }
}
