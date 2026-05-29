//
//  CustomPresetStoreProtocol.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Persists user-created manual EQ presets.
protocol CustomPresetStoreProtocol: Sendable {
    /// Saves a preset under the given name.
    func save(preset: EQPreset, name: String) throws

    /// Loads a preset by name.
    func load(named name: String) throws -> EQPreset

    /// Deletes a preset by name.
    func delete(named name: String) throws

    /// Returns all saved custom presets.
    func allPresets() -> [EQPreset]
}
