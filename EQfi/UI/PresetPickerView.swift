//
//  PresetPickerView.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import SwiftUI

/// Dropdown picker for built-in and custom EQ presets.
struct PresetPickerView: View {
    @Bindable var manualViewModel: ManualEQViewModel

    private static let customSelection = "Custom"

    var body: some View {
        HStack(spacing: 10) {
            Text("Preset")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)

            Picker("Preset", selection: presetSelection) {
                Text("Custom").tag(Self.customSelection)
                Section("Built-in") {
                    ForEach(ManualEQPresetProvider.builtInPresets()) { preset in
                        Text(preset.name).tag(preset.name)
                    }
                }
                if !manualViewModel.customPresets.isEmpty {
                    Section("Custom") {
                        ForEach(manualViewModel.customPresets) { preset in
                            Text(preset.name)
                                .tag(preset.name)
                                .contextMenu {
                                    Button("Delete", role: .destructive) {
                                        manualViewModel.deleteCustomPreset(named: preset.name)
                                    }
                                }
                        }
                    }
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var presetSelection: Binding<String> {
        Binding(
            get: { manualViewModel.selectedPreset?.name ?? Self.customSelection },
            set: { applyPreset(named: $0) }
        )
    }

    private func applyPreset(named name: String) {
        guard name != Self.customSelection else { return }
        if let builtIn = ManualEQPresetProvider.preset(named: name) {
            manualViewModel.applyPreset(builtIn)
            return
        }
        if let custom = manualViewModel.customPresets.first(where: { $0.name == name }) {
            manualViewModel.applyPreset(custom)
        }
    }
}
