//
//  SpotifyTokenManager.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Manages Spotify client-credentials token lifecycle.
final class SpotifyTokenManager: @unchecked Sendable {
    private let keychain: KeychainServiceProtocol
    private let session: URLSession
    private let lock = NSLock()
    private var accessToken: String?
    private var expiryDate: Date?

    init(keychain: KeychainServiceProtocol, session: URLSession = .shared) {
        self.keychain = keychain
        self.session = session
    }

    /// Returns a valid access token, refreshing when expired.
    func validToken() async throws -> String {
        if let token = cachedTokenIfValid() { return token }
        return try await fetchNewToken()
    }

    /// Forces a token refresh regardless of current expiry.
    func forceRefresh() async throws -> String {
        invalidateCache()
        return try await fetchNewToken()
    }

    private func cachedTokenIfValid() -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let token = accessToken, let expiry = expiryDate, expiry > Date() else {
            return nil
        }
        return token
    }

    private func invalidateCache() {
        lock.lock()
        accessToken = nil
        expiryDate = nil
        lock.unlock()
    }

    private func fetchNewToken() async throws -> String {
        let credentials = try loadCredentials()
        let token = try await requestToken(clientID: credentials.id, clientSecret: credentials.secret)
        cacheToken(token)
        return token.accessToken
    }

    private func loadCredentials() throws -> (id: String, secret: String) {
        guard let id = try keychain.read(forKey: Constants.Spotify.clientIDKey),
              let secret = try keychain.read(forKey: Constants.Spotify.clientSecretKey) else {
            throw SpotifyError.missingCredentials
        }
        return (id, secret)
    }

    private func cacheToken(_ token: SpotifyTokenResponse) {
        lock.lock()
        accessToken = token.accessToken
        expiryDate = Date().addingTimeInterval(TimeInterval(token.expiresIn))
        lock.unlock()
    }

    private func requestToken(clientID: String, clientSecret: String) async throws -> SpotifyTokenResponse {
        guard let url = Constants.Spotify.tokenURL else { throw SpotifyError.tokenFetchFailed }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let credentials = "\(clientID):\(clientSecret)"
        guard let credData = credentials.data(using: .utf8) else {
            throw SpotifyError.tokenFetchFailed
        }
        request.setValue("Basic \(credData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        request.httpBody = Data("grant_type=client_credentials".utf8)
        return try await performTokenRequest(request)
    }

    private func performTokenRequest(_ request: URLRequest) async throws -> SpotifyTokenResponse {
        do {
            let (data, response) = try await session.data(for: request)
            try validateHTTPResponse(response)
            return try decodeToken(from: data)
        } catch let error as SpotifyError {
            throw error
        } catch {
            throw SpotifyError.networkFailed(error.localizedDescription)
        }
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw SpotifyError.tokenFetchFailed
        }
        guard http.statusCode == 200 else {
            throw SpotifyError.invalidResponse(statusCode: http.statusCode)
        }
    }

    private func decodeToken(from data: Data) throws -> SpotifyTokenResponse {
        do {
            return try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
        } catch {
            throw SpotifyError.decodingFailed(error.localizedDescription)
        }
    }
}
