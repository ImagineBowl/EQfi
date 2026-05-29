//
//  ServiceConnectionStatus.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Connection health for external services shown as status dots in the menubar.
enum ServiceConnectionStatus: Sendable, Equatable {
    case connected
    case degraded
    case disconnected
}
