//
//  EQfiMode.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Operating mode for EQfi: AI-driven or manual 8-band control.
enum EQfiMode: String, Codable, Sendable, CaseIterable {
    case ai
    case manual

    /// SF Symbol name displayed in the menubar for this mode.
    var menuBarSymbolName: String {
        switch self {
        case .ai: return "waveform.and.magnifyingglass"
        case .manual: return "slider.horizontal.3"
        }
    }

    /// User-facing label for mode toggle UI.
    var displayName: String {
        switch self {
        case .ai: return "AI"
        case .manual: return "Manual"
        }
    }
}
