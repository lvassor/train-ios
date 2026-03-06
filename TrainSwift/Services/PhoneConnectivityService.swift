//
//  PhoneConnectivityService.swift
//  TrainSwift
//
//  iPhone-side WatchConnectivity service.
//  Sends workout state to Watch and receives set updates back.
//

import Foundation
import WatchConnectivity
import Combine

@MainActor
class PhoneConnectivityService: NSObject, ObservableObject {
    static let shared = PhoneConnectivityService()

    @Published var isWatchReachable = false

    private var session: WCSession?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // Callback when Watch sends a set update
    var onSetUpdate: ((WatchSetUpdate) -> Void)?

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Send Workout State

    func sendWorkoutState(_ state: WatchWorkoutState) {
        guard let session = session,
              session.isReachable,
              let data = try? encoder.encode(state) else { return }

        let message: [String: Any] = [
            WatchMessageKey.workoutState: data
        ]
        session.sendMessage(message, replyHandler: nil) { error in
            AppLogger.logWorkout("Watch send error: \(error.localizedDescription)", level: .error)
        }
    }

    // MARK: - Send Rest Timer

    func sendRestStarted(seconds: Int) {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [
            WatchMessageKey.restStarted: true,
            WatchMessageKey.restSeconds: seconds
        ]
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }

    // MARK: - Send Workout Ended

    func sendWorkoutEnded() {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [
            WatchMessageKey.workoutEnded: true
        ]
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }

    // MARK: - Sync via Application Context (background delivery)

    func syncWorkoutContext(_ state: WatchWorkoutState) {
        guard let session = session,
              let data = try? encoder.encode(state) else { return }

        try? session.updateApplicationContext([
            WatchMessageKey.workoutState: data
        ])
    }
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityService: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.isWatchReachable = session.isReachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchReachable = session.isReachable
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        // Handle set updates from Watch
        if let data = message[WatchMessageKey.setUpdate] as? Data {
            let decoder = JSONDecoder()
            if let update = try? decoder.decode(WatchSetUpdate.self, from: data) {
                Task { @MainActor in
                    self.onSetUpdate?(update)
                }
            }
        }
    }
}
