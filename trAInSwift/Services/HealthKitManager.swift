//
//  HealthKitManager.swift
//  trAInSwift
//
//  HealthKit integration for syncing user body stats and workout data
//

import Foundation
import HealthKit
import SwiftUI
import Combine

struct HealthData {
    let age: Int?
    let gender: HKBiologicalSex?
    let height: Double? // in cm
    let weight: Double? // in kg
    let dateOfBirth: Date?
}

@MainActor
class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()

    @Published var isAvailable = HKHealthStore.isHealthDataAvailable()
    @Published var hasPermission = false
    @Published var healthData: HealthData?
    @Published var permissionDenied = false

    // Data types we want to read
    private let readDataTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()

        if let heightType = HKObjectType.quantityType(forIdentifier: .height) {
            types.insert(heightType)
        }
        if let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weightType)
        }
        if let dateOfBirthType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) {
            types.insert(dateOfBirthType)
        }
        if let biologicalSexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex) {
            types.insert(biologicalSexType)
        }

        return types
    }()

    // Data types we want to write (for workout syncing)
    private let writeDataTypes: Set<HKSampleType> = {
        var types = Set<HKSampleType>()

        let workoutType = HKObjectType.workoutType()
        types.insert(workoutType)
        if let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergyType)
        }

        return types
    }()

    /// Request permission to access HealthKit data
    func requestPermission() async -> Bool {
        guard isAvailable else {
            permissionDenied = true
            return false
        }

        do {
            try await healthStore.requestAuthorization(toShare: writeDataTypes, read: readDataTypes)

            // Check if we actually got permission for the data we need
            let heightPermission = healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .height)!)
            let weightPermission = healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: .bodyMass)!)

            hasPermission = heightPermission == .sharingAuthorized || weightPermission == .sharingAuthorized
            permissionDenied = heightPermission == .sharingDenied && weightPermission == .sharingDenied

            if hasPermission {
                await fetchHealthData()
            }

            return hasPermission
        } catch {
            print("HealthKit permission error: \(error)")
            permissionDenied = true
            return false
        }
    }

    /// Fetch available health data from HealthKit
    func fetchHealthData() async {
        guard isAvailable && hasPermission else { return }

        do {
            // Fetch characteristics (age, gender) - these don't require queries
            let dateOfBirth = try? healthStore.dateOfBirthComponents().date
            let biologicalSex = try? healthStore.biologicalSex().biologicalSex

            // Calculate age from date of birth
            let age: Int?
            if let dob = dateOfBirth {
                let ageComponents = Calendar.current.dateComponents([.year], from: dob, to: Date())
                age = ageComponents.year
            } else {
                age = nil
            }

            // Fetch most recent height and weight
            let height = await fetchMostRecent(.height, unit: HKUnit.meterUnit(with: .centi))
            let weight = await fetchMostRecent(.bodyMass, unit: HKUnit.gramUnit(with: .kilo))

            healthData = HealthData(
                age: age,
                gender: biologicalSex,
                height: height,
                weight: weight,
                dateOfBirth: dateOfBirth
            )

        } catch {
            print("HealthKit fetch error: \(error)")
        }
    }

    /// Fetch the most recent value for a quantity type
    private func fetchMostRecent(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: quantityType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, _ in
            // This closure runs on a background queue
        }

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("HealthKit query error: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    /// Check if we can skip height/weight questions
    func canSkipHeightWeight() -> Bool {
        guard let data = healthData else { return false }
        return data.height != nil && data.weight != nil
    }

    /// Check if we have enough data to skip age/gender questions
    func canSkipAgeGender() -> Bool {
        guard let data = healthData else { return false }
        return data.age != nil && data.gender != nil
    }

    /// Save a workout session to HealthKit
    func saveWorkout(startDate: Date, endDate: Date, totalEnergyBurned: Double) async -> Bool {
        guard isAvailable && hasPermission else { return false }

        // Create workout
        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: startDate,
            end: endDate,
            duration: endDate.timeIntervalSince(startDate),
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: totalEnergyBurned),
            totalDistance: nil,
            metadata: [HKMetadataKeyWorkoutBrandName: "trAIn"]
        )

        return await withCheckedContinuation { continuation in
            healthStore.save(workout) { success, error in
                if let error = error {
                    print("HealthKit save workout error: \(error)")
                }
                continuation.resume(returning: success)
            }
        }
    }

    /// Convert HKBiologicalSex to string for our model
    func biologicalSexToString(_ sex: HKBiologicalSex) -> String {
        switch sex {
        case .male:
            return "Male"
        case .female:
            return "Female"
        default:
            return "Other / Prefer not to say"
        }
    }
}