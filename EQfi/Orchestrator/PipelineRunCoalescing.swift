//
//  PipelineRunCoalescing.swift
//  EQfi
//
//  Created by Ahsan Minhas on 06/06/2026.
//

import Foundation

/// Decides whether a new pipeline request should await an existing in-flight run.
enum PipelineRunCoalescing {
    static func shouldAwaitExistingRun(force: Bool, inFlightKey: String?, newKey: String?) -> Bool {
        guard !force, let inFlightKey, let newKey else { return false }
        return inFlightKey == newKey
    }
}
