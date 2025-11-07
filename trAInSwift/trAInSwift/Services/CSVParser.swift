//
//  CSVParser.swift
//  trAInApp
//
//  Simple CSV parser for exercise database
//

import Foundation

class CSVParser {
    static func parseExerciseDatabase(from filename: String) -> [ExerciseDBEntry] {
        guard let filepath = Bundle.main.path(forResource: filename, ofType: "csv") else {
            print("CSV file not found: \(filename).csv")
            return []
        }

        do {
            let contents = try String(contentsOfFile: filepath, encoding: .utf8)
            return parseCSV(contents)
        } catch {
            print("Error reading CSV file: \(error)")
            return []
        }
    }

    private static func parseCSV(_ csvString: String) -> [ExerciseDBEntry] {
        var exercises: [ExerciseDBEntry] = []

        let rows = csvString.components(separatedBy: "\n")
        guard !rows.isEmpty else { return [] }

        // First row is header
        let headers = parseCSVRow(rows[0])

        // Parse remaining rows
        for i in 1..<rows.count {
            let row = rows[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !row.isEmpty else { continue }

            let values = parseCSVRow(row)
            guard values.count == headers.count else {
                print("Row \(i) has incorrect number of columns")
                continue
            }

            // Create dictionary from headers and values
            var rowDict: [String: String] = [:]
            for (index, header) in headers.enumerated() {
                rowDict[header] = values[index]
            }

            let exercise = ExerciseDBEntry(csvRow: rowDict)
            exercises.append(exercise)
        }

        print("Loaded \(exercises.count) exercises from CSV")
        return exercises
    }

    private static func parseCSVRow(_ row: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var insideQuotes = false

        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                values.append(currentValue.trimmingCharacters(in: .whitespaces))
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }

        // Add the last value
        values.append(currentValue.trimmingCharacters(in: .whitespaces))

        return values
    }
}
