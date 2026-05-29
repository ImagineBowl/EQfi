//
//  ModePreferenceServiceProtocol.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Persists and retrieves the user's selected operating mode.
protocol ModePreferenceServiceProtocol: Sendable {
    /// Returns the saved mode, defaulting to AI when unset.
    func loadMode() -> EQfiMode

    /// Persists the selected operating mode.
    func saveMode(_ mode: EQfiMode)
}
