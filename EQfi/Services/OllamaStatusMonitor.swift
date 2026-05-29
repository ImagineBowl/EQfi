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

    var onStatusChange: (@Sendable (ServiceConnectionStatus) -> Void)?

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

    private func monitorLoop() async {
        var lastStatus: ServiceConnectionStatus?
        while !Task.isCancelled {
            let status = await resolveStatus()
            if status != lastStatus {
                lastStatus = status
                onStatusChange?(status)
            }
            await sleepForPollInterval()
        }
    }

    private func resolveStatus() async -> ServiceConnectionStatus {
        guard await modelResolver.hasUsableModel() else { return .degraded }
        guard let url = Constants.Ollama.tagsURL else { return .disconnected }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 3
        do {
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return .disconnected }
            return (200...299).contains(http.statusCode) ? .connected : .degraded
        } catch {
            return .disconnected
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
