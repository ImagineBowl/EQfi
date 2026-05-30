//
//  OllamaStatusMonitor.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Polls Ollama reachability and publishes status changes.
final class OllamaStatusMonitor: @unchecked Sendable {
    private let session: URLSession
    private let modelResolver: OllamaModelResolver
    private var monitorTask: Task<Void, Never>?
    private let pollInterval: TimeInterval

    var onAvailabilityChange: (@Sendable (OllamaAvailability) -> Void)?

    init(
        session: URLSession = .shared,
        modelResolver: OllamaModelResolver = OllamaModelResolver(),
        pollInterval: TimeInterval = Constants.SystemEQ.statusPollSeconds
    ) {
        self.session = session
        self.modelResolver = modelResolver
        self.pollInterval = pollInterval
    }

    /// Starts polling Ollama reachability.
    func startMonitoring() {
        stopMonitoring()
        monitorTask = Task { [weak self] in
            await self?.monitorLoop()
        }
    }

    /// Stops reachability polling.
    func stopMonitoring() {
        monitorTask?.cancel()
        monitorTask = nil
    }

    /// Immediately re-checks Ollama availability (for example after launching it).
    func refreshNow() {
        Task { [weak self] in
            guard let self else { return }
            let availability = await resolveAvailability()
            onAvailabilityChange?(availability)
        }
    }

    private func monitorLoop() async {
        var lastAvailability: OllamaAvailability?
        while !Task.isCancelled {
            let availability = await resolveAvailability()
            if availability != lastAvailability {
                lastAvailability = availability
                onAvailabilityChange?(availability)
            }
            await sleepForPollInterval()
        }
    }

    private func resolveAvailability() async -> OllamaAvailability {
        guard OllamaHelper.isInstalled else { return .notInstalled }
        guard await isServerReachable() else { return .notRunning }
        guard await modelResolver.hasUsableModel() else { return .noModel }
        return .ready
    }

    private func isServerReachable() async -> Bool {
        guard let url = Constants.Ollama.tagsURL else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 3
        do {
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200...299).contains(http.statusCode)
        } catch {
            return false
        }
    }

    private func sleepForPollInterval() async {
        let nanoseconds = UInt64(pollInterval * 1_000_000_000)
        do {
            try await Task.sleep(nanoseconds: nanoseconds)
        } catch {
            return
        }
    }
}
