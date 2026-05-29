//
//  SystemEQStatusMonitor.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Monitors native EQ engine health and publishes status changes.
final class SystemEQStatusMonitor: @unchecked Sendable {
    private let systemEQ: SystemEQServiceProtocol
    private var monitorTask: Task<Void, Never>?
    private let pollInterval: TimeInterval

    var onStatusChange: (@Sendable (ServiceConnectionStatus) -> Void)?

    init(
        systemEQ: SystemEQServiceProtocol,
        pollInterval: TimeInterval = Constants.SystemEQ.statusPollSeconds
    ) {
        self.systemEQ = systemEQ
        self.pollInterval = pollInterval
    }

    /// Starts polling EQ engine status.
    func startMonitoring() {
        stopMonitoring()
        monitorTask = Task { [weak self] in
            await self?.monitorLoop()
        }
    }

    /// Stops polling EQ engine status.
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
        let active = await systemEQ.isActive()
        return active ? .connected : .disconnected
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
