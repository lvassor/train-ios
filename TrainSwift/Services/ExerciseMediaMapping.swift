//
//  ExerciseMediaMapping.swift
//  TrainSwift
//
//  Facade for exercise video lookups — all exercises are Bunny Stream videos.
//  GUIDs are loaded from the exercise_videos DB table into an in-memory cache
//  at startup (via ExerciseDatabaseManager).
//

import Foundation

enum ExerciseMediaMapping {

    /// Look up the Bunny Stream GUID for an exercise
    static func videoGuid(for exerciseId: String) -> String? {
        ExerciseDatabaseManager.shared.videoGuid(for: exerciseId)
    }

    /// Thumbnail URL for an exercise (nil if no video mapped)
    static func thumbnailURL(for exerciseId: String) -> URL? {
        guard let guid = videoGuid(for: exerciseId) else { return nil }
        return BunnyConfig.videoThumbnailURL(for: guid)
    }

    /// Embed URL for playing a video in an iframe
    static func videoEmbedURL(for exerciseId: String) -> URL? {
        guard let guid = videoGuid(for: exerciseId) else { return nil }
        return BunnyConfig.videoEmbedURL(for: guid)
    }
}
