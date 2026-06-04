//
//  SystemEQLogger.swift
//  EQfi
//
//  Created by Ahsan Minhas on 04/06/2026.
//

import AVFoundation
import CoreAudio
import Foundation
import os

/// Console logging for the native system-wide EQ engine and Core Audio tap.
enum SystemEQLogger {
    private static let log = Logger(subsystem: "com.Imaginebowl.EQfi", category: "SystemEQ")
    private static let prefix = "[EQfi SystemEQ]"

    static func engineStarting(outputDeviceUID: String) {
        let message = "Starting engine (output device UID: \(outputDeviceUID))"
        log.info("\(message, privacy: .public)")
        print("\(prefix) \(message)")
    }

    static func engineStarted(format: AVAudioFormat) {
        let message = "Engine started — \(describe(format: format))"
        log.info("\(message, privacy: .public)")
        print("\(prefix) \(message)")
    }

    static func engineStartFailed(_ error: Error, context: String? = nil) {
        let detail = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        let message = context.map { "\($0): \(detail)" } ?? detail
        log.error("Engine start failed: \(message, privacy: .public)")
        print("\(prefix) ERROR: \(message)")
        if let systemEQ = error as? SystemEQError {
            log.error("SystemEQError case: \(String(describing: systemEQ), privacy: .public)")
            print("\(prefix) ERROR type: \(systemEQ)")
        }
    }

    static func tapFormatResolvedFromASBD(format: AVAudioFormat) {
        let message = "Resolved tap format via ASBD fallback — \(describe(format: format))"
        log.notice("\(message, privacy: .public)")
        print("\(prefix) \(message)")
    }

    static func tapFormatRejected(status: OSStatus, streamDescription: AudioStreamBasicDescription) {
        let asbd = describe(streamDescription: streamDescription)
        let message = "Unsupported tap audio format (status \(status)): \(asbd)"
        log.error("\(message, privacy: .public)")
        print("\(prefix) ERROR: \(message)")
    }

    static func tapStepFailed(_ step: String, error: Error) {
        engineStartFailed(error, context: step)
    }

    private static func describe(format: AVAudioFormat) -> String {
        let rate = format.sampleRate
        let channels = format.channelCount
        let interleaved = format.isInterleaved ? "interleaved" : "non-interleaved"
        return String(
            format: "%.0f Hz, %u ch, %@, %@",
            rate,
            channels,
            String(describing: format.commonFormat),
            interleaved
        )
    }

    private static func describe(streamDescription: AudioStreamBasicDescription) -> String {
        let formatID = fourCharCodeString(streamDescription.mFormatID)
        return String(
            format: "sampleRate=%.3f channels=%u bits=%u bytesPerFrame=%u formatID=%@ flags=0x%x",
            streamDescription.mSampleRate,
            streamDescription.mChannelsPerFrame,
            streamDescription.mBitsPerChannel,
            streamDescription.mBytesPerFrame,
            formatID,
            streamDescription.mFormatFlags
        )
    }

    private static func fourCharCodeString(_ code: UInt32) -> String {
        let bytes: [UInt8] = [
            UInt8((code >> 24) & 0xff),
            UInt8((code >> 16) & 0xff),
            UInt8((code >> 8) & 0xff),
            UInt8(code & 0xff)
        ]
        let characters = bytes.map { byte -> Character in
            (32...126).contains(byte) ? Character(UnicodeScalar(byte)) : "?"
        }
        return String(characters)
    }
}
