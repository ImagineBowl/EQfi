//
//  EQSliderView.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import SwiftUI

/// Reusable vertical slider for a single EQ band.
struct EQSliderView: View {
    let band: EQBand
    let onChange: (Float) -> Void

    private let trackHeight: CGFloat = 88
    private let columnWidth: CGFloat = 52

    var body: some View {
        VStack(spacing: 4) {
            Text(String(format: "%+.0f", band.gain))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(height: 12)

            VerticalSlider(
                value: Binding(
                    get: { Double(band.gain) },
                    set: { onChange(Float($0)) }
                ),
                range: Double(Constants.ManualEQ.bandGainMin)...Double(Constants.ManualEQ.bandGainMax),
                trackHeight: trackHeight
            )

            Text("\(band.frequencyLabel)")
                .font(.caption2.monospacedDigit())

            Text(band.shortLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(height: 26)
        }
        .frame(width: columnWidth)
    }
}

/// A vertically oriented slider with a stable layout footprint.
private struct VerticalSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let trackHeight: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Slider(value: $value, in: range)
                .rotationEffect(.degrees(-90))
                .frame(width: geometry.size.height, height: geometry.size.width)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(width: 28, height: trackHeight)
    }
}
