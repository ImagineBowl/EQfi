//
//  OllamaHelper.swift
//  EQfi
//
//  Created by Ahsan Minhas on 29/05/2026.
//

import AppKit
import Foundation

/// Detects a local Ollama install and opens or starts it.
enum OllamaHelper {
    private static let appBundlePath = Constants.Ollama.appBundlePath
    private static let cliSearchPaths = Constants.Ollama.cliSearchPaths

    /// Returns whether Ollama is installed as the macOS app or CLI binary.
    static var isInstalled: Bool {
        appBundleURL != nil || cliBinaryPath != nil
    }

    /// Opens the Ollama download page in the default browser.
    static func openDownloadPage() {
        guard let url = Constants.Ollama.downloadURL else { return }
        NSWorkspace.shared.open(url)
    }

    /// Launches the Ollama app or starts `ollama serve` when only the CLI is installed.
    static func startOllama() {
        if let appURL = appBundleURL {
            NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
            return
        }
        guard let binaryPath = cliBinaryPath else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = ["serve"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
    }

    private static var appBundleURL: URL? {
        guard FileManager.default.fileExists(atPath: appBundlePath) else { return nil }
        return URL(fileURLWithPath: appBundlePath)
    }

    private static var cliBinaryPath: String? {
        cliSearchPaths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }
}
