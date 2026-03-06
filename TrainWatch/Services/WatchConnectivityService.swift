//
//  WatchConnectivityService.swift
//  TrainWatch
//
//  Watch-side WatchConnectivity service.
//  Receives workout state from iPhone and sends set updates back.
//

import Foundation
import WatchConnectivity
import Combine

@MainActor
class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()

    @Published var workoutState: WatchWorkoutState?
    @Published var isPhoneReachable = false
    @Published var restSecondsRemaining: Int?
    @Published var restEndDate: Date?

    private var session: WCSession?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Send Set Update to iPhone

    func sendSetUpdate(_ update: WatchSetUpdate) {
        guard let session = session,
              session.isReachable,
              let data = try? encoder.encode(update) else { return }

        let message: [String: Any] = [
            WatchMessageKey.setUpdate: data
        ]
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }

    // MARK: - Request Sync

    func requestSync() {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [
            WatchMessageKey.action: WatchAction.requestSync.rawValue
        ]
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.isPhoneReachable = session.isReachable

            // Check for application context on activation
            if let data = session.receivedApplicationContext[WatchMessageKey.workoutState] as? Data,
               let state = try? JSONDecoder().decode(WatchWorkoutState.self, from: data) {
                self.workoutState = state
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isPhoneReachable = session.isReachable
            if session.isReachable {
                self.requestSync()
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        let decoder = JSONDecoder()

        Task { @MainActor in
            // Workout state sync
            if let data = message[WatchMessageKey.workoutState] as? Data,
               let state = try? decoder.decode(WatchWorkoutState.self, from: data) {
                self.workoutState = state
            }

            // Rest timer
            if message[WatchMessageKey.restStarted] as? Bool == true,
               let seconds = message[WatchMessageKey.restSeconds] as? Int {
                self.restSecondsRemaining = seconds
                self.restEndDate = Date().addingTimeInterval(Double(seconds))
            }

            // Workout ended
            if message[WatchMessageKey.workoutEnded] as? Bool == true {
                self.workoutState = nil
                self.restSecondsRemaining = nil
                self.restEndDate = nil
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        if let data = applicationContext[WatchMessageKey.workoutState] as? Data,
           let state = try? JSONDecoder().decode(WatchWorkoutState.self, from: data) {
            Task { @MainActor in
                self.workoutState = state
            }
        }
    }
}
