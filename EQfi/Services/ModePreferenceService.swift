//
//  ModePreferenceService.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Persists the user's AI / Manual mode selection in UserDefaults.
final class ModePreferenceService: ModePreferenceServiceProtocol, @unchecked Sendable {
    private let defaults: UserDefaults
    private let modeKey: String

    init(
        defaults: UserDefaults = .standard,
        modeKey: String = Constants.UserDefaultsKeys.operatingMode
    ) {
        self.defaults = defaults
        self.modeKey = modeKey
    }

    /// Returns the saved mode, defaulting to AI when unset.
    func loadMode() -> EQfiMode {
        guard let raw = defaults.string(forKey: modeKey),
              let mode = EQfiMode(rawValue: raw) else {
            return .ai
        }
        return mode
    }

    /// Persists the selected operating mode.
    func saveMode(_ mode: EQfiMode) {
        defaults.set(mode.rawValue, forKey: modeKey)
    }
}
