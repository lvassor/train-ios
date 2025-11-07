//
//  Exercise.swift
//  trAInApp
//
//  Created by Claude Code on 2025-10-06.
//

import Foundation

struct Exercise: Identifiable, Codable {
    var id = UUID()
    let name: String
    let icon: String
    let target: String
    let sets: Int
    let repsMin: Int
    let repsMax: Int

    enum CodingKeys: String, CodingKey {
        case name, icon, target, sets, repsMin, repsMax
    }
}
