//
//  SystemAudioPermissionHelper.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import AppKit
import Foundation

/// Brings EQfi to the front for permission prompts and opens Privacy settings.
enum SystemAudioPermissionHelper {
    private static let primerShownKey = "eqfi_system_audio_permission_primer_shown"

    /// Activates the app so macOS can show the System Audio Recording prompt.
    static func activateForPermissionPrompt() {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    /// Shows a visible alert before macOS presents the System Audio Recording prompt.
    @MainActor
    static func prepareUserForPermissionPrompt() {
        activateForPermissionPrompt()
        guard !UserDefaults.standard.bool(forKey: primerShownKey) else { return }

        let alert = NSAlert()
        alert.messageText = "Allow System Audio Recording"
        alert.informativeText = """
        EQfi needs permission to capture system audio so it can apply EQ.

        When you continue, macOS should show a permission dialog — click Allow.

        If you do not see a dialog, open System Settings → Privacy & Security → System Audio Recording Only and enable EQfi.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Continue")
        alert.addButton(withTitle: "Open System Settings")
        let response = alert.runModal()
        UserDefaults.standard.set(true, forKey: primerShownKey)
        if response == .alertSecondButtonReturn {
            openSystemAudioRecordingSettings()
        }
    }

    /// Opens the System Settings privacy pane for audio capture permissions.
    static func openSystemAudioRecordingSettings() {
        activateForPermissionPrompt()
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AudioCapture",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        ]
        for candidate in candidates {
            guard let url = URL(string: candidate) else { continue }
            if NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
