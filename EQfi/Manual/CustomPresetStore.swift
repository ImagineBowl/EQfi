//
//  CustomPresetStore.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Persists user-created EQ presets in UserDefaults.
final class CustomPresetStore: CustomPresetStoreProtocol, @unchecked Sendable {
    private let defaults: UserDefaults
    private let storageKey: String
    private let lock = NSLock()

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = Constants.UserDefaultsKeys.customPresets
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    /// Saves a preset under the given name.
    func save(preset: EQPreset, name: String) throws {
        var presets = loadAllRaw()
        if presets[name] != nil, preset.name != name {
            throw CustomPresetError.duplicateName(name: name)
        }
        presets[name] = preset
        try persist(presets)
    }

    /// Loads a preset by name.
    func load(named name: String) throws -> EQPreset {
        let presets = loadAllRaw()
        guard let preset = presets[name] else {
            throw CustomPresetError.notFound(name: name)
        }
        return preset
    }

    /// Deletes a preset by name.
    func delete(named name: String) throws {
        var presets = loadAllRaw()
        guard presets.removeValue(forKey: name) != nil else {
            throw CustomPresetError.notFound(name: name)
        }
        try persist(presets)
    }

    /// Returns all saved custom presets.
    func allPresets() -> [EQPreset] {
        loadAllRaw().values.sorted { $0.name < $1.name }
    }

    private func loadAllRaw() -> [String: EQPreset] {
        lock.lock()
        defer { lock.unlock() }
        guard let data = defaults.data(forKey: storageKey) else { return [:] }
        do {
            return try JSONDecoder().decode([String: EQPreset].self, from: data)
        } catch {
            return [:]
        }
    }

    private func persist(_ presets: [String: EQPreset]) throws {
        do {
            let data = try JSONEncoder().encode(presets)
            lock.lock()
            defaults.set(data, forKey: storageKey)
            lock.unlock()
        } catch {
            throw CustomPresetError.encodingFailed(error.localizedDescription)
        }
    }
}
