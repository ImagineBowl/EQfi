//
//  ManualEQPanelView.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import SwiftUI

/// Manual eight-band EQ controls with preset picker and master gain.
struct ManualEQPanelView: View {
    @Bindable var manualViewModel: ManualEQViewModel
    @State private var presetName = ""
    @State private var showSavePrompt = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PresetPickerView(manualViewModel: manualViewModel)
            bandSliders
            masterGainControl
            actionButtons
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .alert("Save Preset", isPresented: $showSavePrompt) {
            TextField("Preset name", text: $presetName)
            Button("Save") { savePreset() }
            Button("Cancel", role: .cancel) { presetName = "" }
        }
    }

    private var bandSliders: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(Array(manualViewModel.bands.enumerated()), id: \.element.id) { index, _ in
                EQSliderView(band: manualViewModel.bands[index]) { gain in
                    manualViewModel.updateBand(index: index, gain: gain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 6)
    }

    private var masterGainControl: some View {
        HStack(spacing: 8) {
            Text("Master")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)
            Slider(
                value: Binding(
                    get: { Double(manualViewModel.masterGain) },
                    set: { manualViewModel.updateMasterGain(Float($0)) }
                ),
                in: Double(Constants.ManualEQ.masterGainMin)...Double(Constants.ManualEQ.masterGainMax)
            )
            Text(String(format: "%+.1f dB", manualViewModel.masterGain))
                .font(.caption.monospacedDigit())
                .frame(width: 52, alignment: .trailing)
        }
    }

    private var actionButtons: some View {
        HStack {
            Button("Reset to Flat") { manualViewModel.resetToFlat() }
            Spacer()
            Button("Save Custom Preset") { showSavePrompt = true }
        }
    }

    private func savePreset() {
        let trimmed = presetName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        manualViewModel.saveCurrentAsPreset(name: trimmed)
        presetName = ""
    }
}
