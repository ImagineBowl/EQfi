//
//  StatusDotView.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import SwiftUI

/// Colored status indicator for service connectivity.
struct StatusDotView: View {
    let label: String
    let status: ServiceConnectionStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
        }
    }

    private var color: Color {
        switch status {
        case .connected: return .green
        case .degraded: return .yellow
        case .disconnected: return .red
        }
    }
}
