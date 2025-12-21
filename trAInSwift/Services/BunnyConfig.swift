//
//  BunnyConfig.swift
//  trAInSwift
//
//  Secure configuration for Bunny.net streaming and storage services
//  API keys should be stored in environment variables or Keychain, NOT in code
//

import Foundation

/// Configuration for Bunny.net CDN services
///
/// SECURITY BEST PRACTICES:
/// 1. Never commit API keys to source control
/// 2. Use environment variables for development
/// 3. Use Keychain storage for production builds
/// 4. For Stream API, use signed URLs with short expiry times
///
/// SETUP INSTRUCTIONS:
/// 1. Add your Bunny Library ID and API Key to a .xcconfig file (not tracked in git)
/// 2. Or set environment variables BUNNY_LIBRARY_ID and BUNNY_API_KEY
/// 3. For release builds, store in Keychain using KeychainService
///
struct BunnyConfig {

    // MARK: - Configuration Keys

    private static let libraryIdKey = "bunny_library_id"
    private static let apiKeyKey = "bunny_api_key"

    // MARK: - Public Configuration

    /// Bunny.net Stream Library ID (public, safe to embed in app)
    /// This is needed for iframe embeds and HLS playback URLs
    static let libraryId: String = "568658"

    /// Bunny.net API Key (private, for signed URLs)
    /// WARNING: Only use for generating signed URLs server-side or in secure contexts
    static var apiKey: String? {
        // First check Info.plist (from .xcconfig) - NOT RECOMMENDED for API keys
        if let key = Bundle.main.infoDictionary?["BUNNY_API_KEY"] as? String, !key.isEmpty {
            return key
        }

        // Then check environment variable (for development)
        if let key = ProcessInfo.processInfo.environment["BUNNY_API_KEY"], !key.isEmpty {
            return key
        }

        // Finally check Keychain (recommended for production)
        if let key = try? KeychainService.shared.retrieveAPIKey(for: apiKeyKey) {
            return key
        }

        return nil
    }

    // MARK: - URL Builders

    /// Base URL for Bunny.net Stream iframe embeds
    static let streamEmbedBaseURL = "https://iframe.mediadelivery.net/embed"

    /// Base URL for Bunny.net Storage/Pull Zone (images)
    static let storageBaseURL = "https://train-strength.b-cdn.net"

    /// Generate video embed URL for a given video GUID
    /// - Parameter videoGuid: The Bunny.net video GUID
    /// - Returns: URL for iframe embedding
    static func videoEmbedURL(for videoGuid: String) -> URL? {
        URL(string: "\(streamEmbedBaseURL)/\(libraryId)/\(videoGuid)")
    }

    /// Generate video playback URL (HLS) for native player
    /// - Parameter videoGuid: The Bunny.net video GUID
    /// - Returns: URL for HLS playback
    static func videoPlaybackURL(for videoGuid: String) -> URL? {
        URL(string: "https://vz-\(libraryId).b-cdn.net/\(videoGuid)/playlist.m3u8")
    }

    /// Stream CDN ID for thumbnail delivery (different from library ID)
    static let streamCdnId: String = "e5fdd1e5"

    /// Generate thumbnail URL for a video
    /// - Parameters:
    ///   - videoGuid: The Bunny.net video GUID
    ///   - thumbnailName: Thumbnail filename (default: thumbnail.jpg)
    /// - Returns: URL for video thumbnail
    static func videoThumbnailURL(for videoGuid: String, thumbnailName: String = "thumbnail.jpg") -> URL? {
        URL(string: "https://vz-\(streamCdnId)-cce.b-cdn.net/\(videoGuid)/\(thumbnailName)")
    }

    /// Generate image URL from storage/pull zone
    /// - Parameter filename: The image filename
    /// - Returns: URL for the image
    static func imageURL(for filename: String) -> URL? {
        URL(string: "\(storageBaseURL)/\(filename)")
    }

    // MARK: - Keychain Storage (for production)

    /// Store Bunny credentials in Keychain (call during app setup/onboarding)
    static func storeCredentials(libraryId: String, apiKey: String?) throws {
        try KeychainService.shared.saveAPIKey(libraryId, for: libraryIdKey)
        if let apiKey = apiKey {
            try KeychainService.shared.saveAPIKey(apiKey, for: apiKeyKey)
        }
        print("✅ Bunny credentials stored in Keychain")
    }

    /// Clear stored credentials from Keychain
    static func clearCredentials() throws {
        try? KeychainService.shared.deleteAPIKey(for: libraryIdKey)
        try? KeychainService.shared.deleteAPIKey(for: apiKeyKey)
        print("✅ Bunny credentials cleared from Keychain")
    }
}

// MARK: - KeychainService Extension for API Keys

extension KeychainService {

    private static let apiKeyService = "com.trainapp.apikeys"

    func saveAPIKey(_ key: String, for identifier: String) throws {
        try? deleteAPIKey(for: identifier)

        guard let keyData = key.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainService.apiKeyService,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }

    func retrieveAPIKey(for identifier: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainService.apiKeyService,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unknown(status)
        }

        guard let keyData = result as? Data,
              let key = String(data: keyData, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return key
    }

    func deleteAPIKey(for identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainService.apiKeyService,
            kSecAttrAccount as String: identifier
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
}
