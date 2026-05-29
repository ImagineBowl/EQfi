//
//  KeychainService.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation
import Security

/// Stores and retrieves secrets from the macOS Keychain.
final class KeychainService: KeychainServiceProtocol, @unchecked Sendable {
    private let serviceName: String

    init(serviceName: String = Constants.Keychain.serviceName) {
        self.serviceName = serviceName
    }

    /// Saves a string value under the given key.
    func save(_ value: String, forKey key: String) throws {
        let data = Data(value.utf8)
        try delete(forKey: key)
        let status = SecItemAdd(buildQuery(forKey: key, data: data) as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }

    /// Reads a string value for the given key.
    func read(forKey key: String) throws -> String? {
        var query = buildQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw KeychainError.readFailed(status: status)
        }
        guard let data = result as? Data, let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return string
    }

    /// Deletes the value stored under the given key.
    func delete(forKey key: String) throws {
        let status = SecItemDelete(buildQuery(forKey: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }

    /// Returns whether Spotify credentials have been stored.
    func hasSpotifyCredentials() -> Bool {
        do {
            let hasID = try read(forKey: Constants.Spotify.clientIDKey) != nil
            let hasSecret = try read(forKey: Constants.Spotify.clientSecretKey) != nil
            return hasID && hasSecret
        } catch {
            return false
        }
    }

    private func buildQuery(forKey key: String, data: Data? = nil) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        if let data { query[kSecValueData as String] = data }
        return query
    }
}
