//
//  RealtimeAudioAnalyzer.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Accelerate
import Foundation

/// Lightweight FFT-based analyzer for adaptive EQ (runs off the audio thread).
final class RealtimeAudioAnalyzer: @unchecked Sendable {
    private let fftSize: Int
    private let sampleRate: Double
    private var window: [Float]
    private var fftReal: [Float]
    private var fftImag: [Float]
    private var magnitudes: [Float]
    private var fftSetup: vDSP_DFT_Setup?

    init(
        fftSize: Int = Constants.AdaptiveEQ.fftSize,
        sampleRate: Double = Constants.SystemEQ.defaultSampleRate
    ) {
        self.fftSize = fftSize
        self.sampleRate = sampleRate
        window = [Float](repeating: 0, count: fftSize)
        fftReal = [Float](repeating: 0, count: fftSize)
        fftImag = [Float](repeating: 0, count: fftSize)
        magnitudes = [Float](repeating: 0, count: fftSize / 2)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            vDSP_Length(fftSize),
            vDSP_DFT_Direction.FORWARD
        )
    }

    deinit {
        if let fftSetup {
            vDSP_DFT_DestroySetup(fftSetup)
        }
    }

    /// Analyzes the latest mono PCM block and returns normalized features.
    func analyze(samples: inout [Float], frameCount: Int) -> AudioFeatures? {
        guard frameCount >= fftSize, let fftSetup else { return nil }

        let timeDomainRMS = rootMeanSquare(of: samples)
        let peak = peakAmplitude(of: samples)
        let rmsDB = decibels(from: timeDomainRMS)
        let crestFactorDB = crestFactorDecibels(peak: peak, rms: timeDomainRMS)

        samples.withUnsafeMutableBufferPointer { buffer in
            vDSP_vmul(buffer.baseAddress!, 1, window, 1, buffer.baseAddress!, 1, vDSP_Length(fftSize))
        }

        samples.withUnsafeBufferPointer { timeDomain in
            fftReal.withUnsafeMutableBufferPointer { real in
                fftImag.withUnsafeMutableBufferPointer { imag in
                    guard let timeBase = timeDomain.baseAddress,
                          let realBase = real.baseAddress,
                          let imagBase = imag.baseAddress else { return }
                    realBase.update(from: timeBase, count: fftSize)
                    imagBase.initialize(repeating: 0, count: fftSize)
                    vDSP_DFT_Execute(fftSetup, realBase, imagBase, realBase, imagBase)
                }
            }
        }

        let scale = 1 / Float(fftSize)
        for index in 0..<magnitudes.count {
            let real = fftReal[index]
            let imag = fftImag[index]
            magnitudes[index] = sqrt((real * real) + (imag * imag)) * scale
        }

        let binWidth = sampleRate / Double(fftSize)
        let spectralTotal = magnitudes.reduce(0, +)
        let bass = normalizedBandEnergy(fromHz: 20, toHz: 250, relativeTo: spectralTotal)
        let treble = normalizedBandEnergy(fromHz: 6_000, toHz: 20_000, relativeTo: spectralTotal)
        let harshness = normalizedBandEnergy(fromHz: 2_000, toHz: 5_000, relativeTo: spectralTotal)
        let centroid = spectralCentroid(binWidth: binWidth)

        return AudioFeatures(
            bassEnergy: bass,
            trebleEnergy: treble,
            rmsLoudnessDB: rmsDB,
            spectralCentroidHz: centroid,
            dynamicRangeDB: crestFactorDB,
            harshness: harshness,
            capturedAt: Date()
        )
    }

    private func rootMeanSquare(of samples: [Float]) -> Float {
        var rms: Float = 0
        samples.withUnsafeBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            vDSP_rmsqv(baseAddress, 1, &rms, vDSP_Length(fftSize))
        }
        return rms
    }

    private func peakAmplitude(of samples: [Float]) -> Float {
        var peak: Float = 0
        samples.withUnsafeBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            vDSP_maxmgv(baseAddress, 1, &peak, vDSP_Length(fftSize))
        }
        return peak
    }

    private func crestFactorDecibels(peak: Float, rms: Float) -> Float {
        guard rms > 1e-7 else { return 0 }
        return 20 * log10(max(peak / rms, 1))
    }

    private func bandEnergy(fromHz low: Double, toHz high: Double) -> Float {
        let binWidth = sampleRate / Double(fftSize)
        let start = max(0, Int(low / binWidth))
        let end = min(magnitudes.count - 1, Int(high / binWidth))
        guard end >= start else { return 0 }
        return magnitudes[start...end].reduce(0, +)
    }

    private func normalizedBandEnergy(fromHz low: Double, toHz high: Double, relativeTo total: Float) -> Float {
        let energy = bandEnergy(fromHz: low, toHz: high)
        guard total > 0 else { return 0 }
        return min(max(energy / total, 0), 1)
    }

    private func spectralCentroid(binWidth: Double) -> Float {
        var weighted: Float = 0
        var total: Float = 0
        for index in 1..<magnitudes.count {
            let frequency = Float(Double(index) * binWidth)
            let magnitude = magnitudes[index]
            weighted += frequency * magnitude
            total += magnitude
        }
        guard total > 0 else { return 0 }
        return weighted / total
    }

    private func decibels(from rms: Float) -> Float {
        20 * log10(max(rms, 1e-7))
    }
}
