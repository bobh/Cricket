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
}
