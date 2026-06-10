//
//  AppVersion.swift
//  EQfi
//
//  Created by Ahsan Minhas on 11/06/2026.
//

import Foundation

/// Reads and compares EQfi bundle versions.
enum AppVersion {
    /// Current app version from `CFBundleShortVersionString`.
    static var current: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    /// Returns whether `remote` is strictly newer than `local` using semver-style comparison.
    static func isNewer(_ remote: String, than local: String) -> Bool {
        compare(remote, local) == .orderedDescending
    }

    /// Normalizes release tags like `v1.0.0` to `1.0.0`.
    static func normalized(_ version: String) -> String {
        var value = version.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.lowercased().hasPrefix("v") {
            value.removeFirst()
        }
        return value
    }

    private static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = components(of: lhs)
        let right = components(of: rhs)
        let count = max(left.count, right.count)
        for index in 0..<count {
            let leftValue = index < left.count ? left[index] : 0
            let rightValue = index < right.count ? right[index] : 0
            if leftValue < rightValue { return .orderedAscending }
            if leftValue > rightValue { return .orderedDescending }
        }
        return .orderedSame
    }

    private static func components(of version: String) -> [Int] {
        normalized(version)
            .split(separator: ".")
            .map { Int($0.filter(\.isNumber)) ?? 0 }
    }
}
