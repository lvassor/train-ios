//
//  Session.swift
//  trAInApp
//
//  Created by Claude Code on 2025-10-06.
//

import Foundation

struct Session: Identifiable, Codable {
    var id: String = UUID().uuidString
    let name: String
    let exercises: [Exercise]

    enum CodingKeys: String, CodingKey {
        case name, exercises
    }
}
