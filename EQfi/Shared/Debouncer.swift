//
//  Debouncer.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Delays repeated calls so only the last invocation runs after a quiet period.
final class Debouncer: @unchecked Sendable {
    private let delay: TimeInterval
    private let queue: DispatchQueue
    private var workItem: DispatchWorkItem?

    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }

    /// Schedules an action, cancelling any previously pending invocation.
    func call(_ action: @escaping @Sendable () -> Void) {
        workItem?.cancel()
        let item = DispatchWorkItem(block: action)
        workItem = item
        queue.asyncAfter(deadline: .now() + delay, execute: item)
    }

    /// Cancels any pending debounced action.
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}
