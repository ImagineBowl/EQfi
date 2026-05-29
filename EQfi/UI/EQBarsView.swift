//
//  EQBarsView.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import SwiftUI

/// Mini five-band bar chart for the menubar popover.
struct EQBarsView: View {
    let gains: [Float]
    private let labels = ["Sub", "Bass", "Mid", "Pres", "Bril"]

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(gains.enumerated()), id: \.offset) { index, gain in
                VStack(spacing: 4) {
                    bar(for: gain)
                    Text(labels[index])
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 80)
    }

    private func bar(for gain: Float) -> some View {
        let normalized = CGFloat((gain + 12) / 24)
        return RoundedRectangle(cornerRadius: 3)
            .fill(gain >= 0 ? Color.accentColor : Color.orange)
            .frame(width: 14, height: max(4, normalized * 60))
    }
}
