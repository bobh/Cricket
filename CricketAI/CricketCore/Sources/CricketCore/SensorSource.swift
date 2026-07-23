//
//  SensorSource.swift
//  CricketCore
//
//  Where a reading originated. Raw values match the existing app-group convention.
//

/// Where a reading originated (FR-4).
public enum SensorSource: String, Sendable, Codable, CaseIterable {
    case arduino = "BLE"
    case ruuvi   = "Ruuvi"

    /// Arbitration weight when more than one source is live. Higher wins.
    /// Product decision: always prefer RuuviTag (more reliable commercial sensor);
    /// fall back to Arduino only when the Ruuvi reading has gone stale.
    public var priority: Int {
        switch self {
        case .ruuvi:   return 1
        case .arduino: return 0
        }
    }
}
