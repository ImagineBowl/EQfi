//
//  UpdateCheckerService.swift
//  EQfi
//
//  Created by Ahsan Minhas on 11/06/2026.
//

import Foundation

/// Polls GitHub Releases for newer EQfi builds.
final class UpdateCheckerService: UpdateCheckerServiceProtocol, @unchecked Sendable {
    private let session: URLSession
    private let defaults: UserDefaults
    private let currentVersionProvider: @Sendable () -> String

    init(
        session: URLSession = .shared,
        defaults: UserDefaults = .standard,
        currentVersionProvider: @escaping @Sendable () -> String = { AppVersion.current }
    ) {
        self.session = session
        self.defaults = defaults
        self.currentVersionProvider = currentVersionProvider
    }

    /// Returns update info when a newer release is available, otherwise `nil`.
    func checkForUpdateIfNeeded() async -> AppUpdateInfo? {
        guard shouldPerformCheck else { return nil }
        defer { recordCheckAttempt() }

        do {
            let release = try await fetchLatestRelease()
            let remoteVersion = AppVersion.normalized(release.tagName)
            guard AppVersion.isNewer(remoteVersion, than: currentVersionProvider()) else { return nil }
            guard !isDismissed(remoteVersion) else { return nil }
            guard let releasePageURL = URL(string: release.htmlURL) else { return nil }

            return AppUpdateInfo(
                version: remoteVersion,
                releasePageURL: releasePageURL,
                downloadURL: preferredDownloadURL(from: release.assets),
                releaseNotes: release.body?.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        } catch {
            return nil
        }
    }

    /// Records that the user dismissed a specific release version.
    func dismiss(version: String) {
        defaults.set(AppVersion.normalized(version), forKey: Constants.UserDefaultsKeys.dismissedUpdateVersion)
    }

    private var shouldPerformCheck: Bool {
        guard let lastCheck = defaults.object(forKey: Constants.UserDefaultsKeys.lastUpdateCheckDate) as? Date else {
            return true
        }
        return Date().timeIntervalSince(lastCheck) >= Constants.UpdateChecker.checkIntervalSeconds
    }

    private func recordCheckAttempt() {
        defaults.set(Date(), forKey: Constants.UserDefaultsKeys.lastUpdateCheckDate)
    }

    private func isDismissed(_ version: String) -> Bool {
        let dismissed = defaults.string(forKey: Constants.UserDefaultsKeys.dismissedUpdateVersion) ?? ""
        return dismissed == AppVersion.normalized(version)
    }

    private func fetchLatestRelease() async throws -> GitHubReleaseResponse {
        guard let url = Constants.UpdateChecker.latestReleaseURL else {
            throw UpdateCheckerError.invalidConfiguration
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Constants.UpdateChecker.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = Constants.UpdateChecker.requestTimeoutSeconds

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw UpdateCheckerError.invalidResponse(statusCode: -1)
        }
        guard http.statusCode == 200 else {
            throw UpdateCheckerError.invalidResponse(statusCode: http.statusCode)
        }
        return try JSONDecoder().decode(GitHubReleaseResponse.self, from: data)
    }

    private func preferredDownloadURL(from assets: [GitHubReleaseAsset]) -> URL? {
        let preferredNames = assets.filter { asset in
            let name = asset.name.lowercased()
            return name.hasSuffix(".dmg") || name.hasSuffix(".zip")
        }
        let match = preferredNames.first ?? assets.first
        guard let urlString = match?.browserDownloadURL else { return nil }
        return URL(string: urlString)
    }
}

private struct GitHubReleaseResponse: Decodable {
    let tagName: String
    let htmlURL: String
    let body: String?
    let assets: [GitHubReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case body
        case assets
    }
}

struct GitHubReleaseAsset: Decodable, Sendable {
    let name: String
    let browserDownloadURL: String

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}
