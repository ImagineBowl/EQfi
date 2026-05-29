//
//  AudioRingBuffer.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Single-producer single-consumer interleaved float ring buffer for realtime audio.
final class AudioRingBuffer: @unchecked Sendable {
    private var storage: [Float]
    private var readIndex = 0
    private var writeIndex = 0
    private var storedSamples = 0
    private let capacity: Int
    private let lock = NSLock()

    init(frameCapacity: Int, channelCount: Int) {
        capacity = max(frameCapacity * channelCount, 1)
        storage = Array(repeating: 0, count: capacity)
    }

    /// Number of interleaved samples currently buffered.
    var availableSamples: Int {
        lock.lock()
        defer { lock.unlock() }
        return storedSamples
    }

    /// Clears all buffered audio.
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        readIndex = 0
        writeIndex = 0
        storedSamples = 0
    }

    /// Writes interleaved samples into the ring buffer, dropping the oldest samples on overflow.
    func write(_ samples: UnsafePointer<Float>, count: Int) {
        guard count > 0 else { return }
        lock.lock()
        defer { lock.unlock() }

        for index in 0..<count {
            storage[writeIndex] = samples[index]
            writeIndex = (writeIndex + 1) % capacity
            if storedSamples < capacity {
                storedSamples += 1
            } else {
                readIndex = (readIndex + 1) % capacity
            }
        }
    }

    /// Reads interleaved samples, zero-filling when the buffer does not have enough data.
    @discardableResult
    func read(into destination: UnsafeMutablePointer<Float>, count: Int) -> Int {
        guard count > 0 else { return 0 }
        lock.lock()
        defer { lock.unlock() }

        let samplesToRead = min(count, storedSamples)
        for index in 0..<samplesToRead {
            destination[index] = storage[readIndex]
            readIndex = (readIndex + 1) % capacity
        }
        storedSamples -= samplesToRead

        if samplesToRead < count {
            for index in samplesToRead..<count {
                destination[index] = 0
            }
        }
        return samplesToRead
    }
}
