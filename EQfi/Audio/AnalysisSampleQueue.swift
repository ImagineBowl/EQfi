//
//  AnalysisSampleQueue.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Lock-protected sample queue from the capture path to the analysis thread.
final class AnalysisSampleQueue: @unchecked Sendable {
    private var storage: [Float]
    private var writeIndex = 0
    private var stored = 0
    private let capacity: Int
    private let lock = NSLock()

    init(capacity: Int = Constants.AdaptiveEQ.sampleQueueCapacity) {
        self.capacity = max(capacity, 1)
        storage = Array(repeating: 0, count: self.capacity)
    }

    /// Enqueues interleaved samples from the realtime capture path (non-blocking).
    func enqueue(_ samples: UnsafePointer<Float>, count: Int) {
        guard count > 0 else { return }
        lock.lock()
        for index in 0..<count {
            storage[writeIndex] = samples[index]
            writeIndex = (writeIndex + 1) % capacity
            if stored < capacity {
                stored += 1
            }
        }
        lock.unlock()
    }

    /// Copies the most recent samples into mono output for analysis.
    func copyLatestMono(into destination: inout [Float], channelCount: Int) -> Int {
        lock.lock()
        defer { lock.unlock() }
        guard stored > 0, channelCount > 0 else { return 0 }

        let framesAvailable = stored / channelCount
        let framesNeeded = destination.count
        let framesToCopy = min(framesAvailable, framesNeeded)
        guard framesToCopy > 0 else { return 0 }

        let samplesNeeded = framesToCopy * channelCount
        let start = (writeIndex - samplesNeeded + capacity) % capacity

        for frame in 0..<framesToCopy {
            var mono: Float = 0
            for channel in 0..<channelCount {
                let sampleIndex = (start + frame * channelCount + channel) % capacity
                mono += storage[sampleIndex]
            }
            destination[frame] = mono / Float(channelCount)
        }
        return framesToCopy
    }
}
