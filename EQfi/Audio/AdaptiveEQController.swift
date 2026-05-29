//
//  AdaptiveEQController.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import AVFoundation
import Foundation

/// Coordinates capture-side sampling, analysis, and smoothed adaptive EQ updates.
@available(macOS 14.2, *)
final class AdaptiveEQController: @unchecked Sendable {
    private let sampleQueue = AnalysisSampleQueue()
    private let analyzer: RealtimeAudioAnalyzer
    private let modifier = AdaptiveEQModifier()
    private let smoother = EQParameterSmoother()
    private var featureSmoother = AudioFeatureSmoother()
    private let analysisQueue = DispatchQueue(
        label: Constants.AdaptiveEQ.analysisQueueLabel,
        qos: .utility
    )
    private var timer: DispatchSourceTimer?
    private weak var eqUnit: AVAudioUnitEQ?
    private weak var mixer: AVAudioMixerNode?
    private var baseProfile = EQManualProfile.flat()
    private var channelCount = Int(Constants.SystemEQ.channelCount)
    private var isEnabled = true
    private var monoScratch: [Float]
    private var lastLoggedFeatures: AudioFeatures?
    private(set) var latestFeatures: AudioFeatures?

    init(sampleRate: Double) {
        analyzer = RealtimeAudioAnalyzer(sampleRate: sampleRate)
        monoScratch = [Float](repeating: 0, count: Constants.AdaptiveEQ.fftSize)
    }

    /// Attaches to the running EQ engine nodes.
    func attach(eqUnit: AVAudioUnitEQ, mixer: AVAudioMixerNode, channelCount: Int) {
        self.eqUnit = eqUnit
        self.mixer = mixer
        self.channelCount = max(channelCount, 1)
        startTimer()
    }

    /// Detaches and stops adaptive processing.
    func detach() {
        timer?.cancel()
        timer = nil
        eqUnit = nil
        mixer = nil
    }

    /// Enables or disables adaptive modifications while keeping the base profile.
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            featureSmoother.reset()
            applyGains(baseProfile.bands.map(\.gain), masterGain: baseProfile.masterGain)
        }
    }

    /// Stores the genre/base EQ layer used for adaptive offsets.
    func updateBaseProfile(_ profile: EQManualProfile) {
        baseProfile = profile
        smoother.reset(to: profile.bands.map(\.gain))
        featureSmoother.reset()
        lastLoggedFeatures = nil
        guard let eqUnit, let mixer else { return }
        DispatchQueue.main.async {
            EQBandConfigurator.apply(profile: profile, to: eqUnit, mixer: mixer)
        }
    }

    /// Enqueues samples from the capture path (must stay lightweight).
    func enqueueSamples(_ samples: UnsafePointer<Float>, count: Int) {
        sampleQueue.enqueue(samples, count: count)
    }

    private func startTimer() {
        timer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: analysisQueue)
        timer.schedule(
            deadline: .now() + Constants.AdaptiveEQ.analysisInterval,
            repeating: Constants.AdaptiveEQ.analysisInterval
        )
        timer.setEventHandler { [weak self] in
            self?.tick()
        }
        timer.resume()
        self.timer = timer
    }

    private func tick() {
        let frames = sampleQueue.copyLatestMono(into: &monoScratch, channelCount: channelCount)
        guard frames >= Constants.AdaptiveEQ.fftSize,
              let rawFeatures = analyzer.analyze(samples: &monoScratch, frameCount: frames) else {
            return
        }

        latestFeatures = rawFeatures
        guard isEnabled else { return }

        guard rawFeatures.rmsLoudnessDB >= Constants.AdaptiveEQ.silenceGateDB else {
            driftTowardBaseProfile()
            return
        }

        let features = featureSmoother.process(rawFeatures)
        latestFeatures = features
        logIfMeaningfulChange(features)

        let target = modifier.modifiedBands(base: baseProfile, features: features)
        let smoothed = smoother.step(toward: target)
        applyGains(smoothed, masterGain: baseProfile.masterGain)
    }

    private func driftTowardBaseProfile() {
        let baseGains = baseProfile.bands.map(\.gain)
        let smoothed = smoother.step(toward: baseGains)
        applyGains(smoothed, masterGain: baseProfile.masterGain)
    }

    private func logIfMeaningfulChange(_ features: AudioFeatures) {
        guard shouldLog(features) else { return }
        lastLoggedFeatures = features
        PipelineLogger.adaptiveFeaturesUpdated(features)
    }

    private func shouldLog(_ features: AudioFeatures) -> Bool {
        guard let lastLoggedFeatures else { return true }
        let threshold = Constants.AdaptiveEQ.logChangeThreshold
        return abs(features.bassEnergy - lastLoggedFeatures.bassEnergy) >= threshold
            || abs(features.trebleEnergy - lastLoggedFeatures.trebleEnergy) >= threshold
            || abs(features.harshness - lastLoggedFeatures.harshness) >= threshold
            || abs(features.rmsLoudnessDB - lastLoggedFeatures.rmsLoudnessDB) >= 2
            || abs(features.spectralCentroidHz - lastLoggedFeatures.spectralCentroidHz) >= 250
            || abs(features.dynamicRangeDB - lastLoggedFeatures.dynamicRangeDB) >= 1.5
    }

    private func applyGains(_ gains: [Float], masterGain: Float) {
        guard let eqUnit, let mixer else { return }
        DispatchQueue.main.async {
            EQBandConfigurator.applyGains(gains, masterGain: masterGain, to: eqUnit, mixer: mixer)
        }
    }
}

private extension EQManualProfile {
    static func flat() -> EQManualProfile {
        EQManualProfile(bands: EQBand.standardBands, masterGain: 0, presetName: "Flat")
    }
}
