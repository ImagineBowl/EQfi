//
//  OllamaModelPicker.swift
//  EQfi
//
//  Created by Ahsan Minhas on 06/06/2026.
//

import Foundation

/// Chooses the best Ollama model name from loaded or installed model lists.
enum OllamaModelPicker {
    /// Picks the preferred model from the given names, favoring the Llama family.
    static func selectBest(
        from names: [String],
        prefixes: [String] = Constants.Ollama.modelFallbackPrefixes
    ) -> String? {
        guard !names.isEmpty else { return nil }
        let llamaNames = names.filter { isLlamaFamily($0) }
        let candidates = llamaNames.isEmpty ? names : llamaNames

        for prefix in prefixes {
            if let match = candidates.first(where: { baseName($0) == prefix }) {
                return match
            }
        }
        for prefix in prefixes {
            if let match = candidates.first(where: { baseName($0).hasPrefix(prefix) }) {
                return match
            }
        }
        return candidates.first
    }

    static func baseName(_ name: String) -> String {
        name.split(separator: ":", maxSplits: 1).first.map(String.init) ?? name
    }

    static func isLlamaFamily(_ name: String) -> Bool {
        baseName(name).lowercased().hasPrefix("llama")
    }
}
