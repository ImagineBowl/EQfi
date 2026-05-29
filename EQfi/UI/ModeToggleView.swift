//
//  ModeToggleView.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import SwiftUI

/// Toggle switch for AI and Manual operating modes.
struct ModeToggleView: View {
    @Bindable var viewModel: EQViewModel

    var body: some View {
        Picker("Mode", selection: Binding(
            get: { viewModel.mode },
            set: { viewModel.setMode($0) }
        )) {
            ForEach(EQfiMode.allCases, id: \.self) { mode in
                Text(mode.displayName).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}
