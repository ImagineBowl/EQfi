//
//  ManualEQViewModel.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// UI state and actions for manual eight-band EQ control.
@MainActor
@Observable
final class ManualEQViewModel {
    var bands: [EQBand] = EQBand.standardBands
    var selectedPreset: EQPreset?
    var masterGain: Float = 0
    var customPresets: [EQPreset] = []

    private let manualEQ: ManualEQServiceProtocol
    private let presetStore: CustomPresetStoreProtocol

    init(manualEQ: ManualEQServiceProtocol, presetStore: CustomPresetStoreProtocol) {
        self.manualEQ = manualEQ
        self.presetStore = presetStore
        reloadCustomPresets()
    }

    /// Applies a preset to the current band state and sends it to eqMac.
    func applyPreset(_ preset: EQPreset) {
        bands = preset.bands
        masterGain = preset.masterGain
        selectedPreset = preset
        Task {
            do {
                try await manualEQ.applyBands(bands, masterGain: masterGain)
            } catch {
                return
            }
        }
    }

    /// Updates a single band gain and debounces the eqMac update.
    func updateBand(index: Int, gain: Float) {
        guard bands.indices.contains(index) else { return }
        bands[index].gain = clampGain(gain)
        selectedPreset = nil
        manualEQ.applyBandsDebounced(bands, masterGain: masterGain)
    }

    /// Updates master gain and debounces the eqMac update.
    func updateMasterGain(_ gain: Float) {
        masterGain = clampMaster(gain)
        selectedPreset = nil
        manualEQ.applyBandsDebounced(bands, masterGain: masterGain)
    }

    /// Saves the current band state as a named custom preset.
    func saveCurrentAsPreset(name: String) {
        let preset = EQPreset.custom(name: name, bands: bands, masterGain: masterGain)
        do {
            try presetStore.save(preset: preset, name: name)
            reloadCustomPresets()
            selectedPreset = preset
        } catch {
            return
        }
    }

    /// Deletes a custom preset by name.
    func deleteCustomPreset(named name: String) {
        do {
            try presetStore.delete(named: name)
            reloadCustomPresets()
        } catch {
            return
        }
    }

    /// Resets all bands and master gain to flat.
    func resetToFlat() {
        applyPreset(ManualEQPresetProvider.preset(named: "Flat") ?? flatFallback())
    }

    /// Seeds manual bands from the current AI or eqMac profile.
    func adoptProfile(_ profile: EQManualProfile) {
        bands = profile.bands
        masterGain = profile.masterGain
        selectedPreset = nil
    }

    /// Reloads custom presets from persistent storage.
    func reloadCustomPresets() {
        customPresets = presetStore.allPresets()
    }

    private func flatFallback() -> EQPreset {
        EQPreset(name: "Flat", bands: EQBand.standardBands, masterGain: 0, isBuiltIn: true)
    }

    private func clampGain(_ gain: Float) -> Float {
        min(max(gain, Constants.ManualEQ.bandGainMin), Constants.ManualEQ.bandGainMax)
    }

    private func clampMaster(_ gain: Float) -> Float {
        min(max(gain, Constants.ManualEQ.masterGainMin), Constants.ManualEQ.masterGainMax)
    }
}
