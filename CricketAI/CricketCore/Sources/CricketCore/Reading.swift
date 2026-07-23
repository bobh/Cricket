//
//  Reading.swift
//  CricketCore
//
//  An accepted, sentinel-filtered environmental reading. Sendable so it can be
//  extracted from a nonisolated CoreBluetooth delegate and handed to the MainActor.
//

import Foundation

/// An accepted, sentinel-filtered environmental reading (DR-1, FR-4).
public struct Reading: Sendable, Equatable, Identifiable, Codable {
    public let id: UUID
    public let celsius: Double
    public let relativeHumidity: Double   // % RH
    public let timestamp: Date            // capture time (DR-1 / FR-4)
    public let source: SensorSource

    // MARK: Optional, source-capability-aware metrics (DR-3, revised 2026-07-23)
    // NOT part of the ⭐acid test (temp + humidity drive ESD/CMOS + material domains).
    // Modeled as Optional so a source/build that can't supply them returns nil — the
    // freshness/disclosure layer then says "pressure unavailable from this source"
    // rather than fabricating a value. Do NOT build agent features on these until a
    // concrete workshop use case (e.g. pressure *trend*) justifies it.

    /// Barometric pressure in hectopascals (hPa). nil when the source doesn't report it.
    public let pressureHPa: Double?

    /// Monotonic disturbance/movement counter. nil when the source doesn't report motion.
    public let movementCount: Int?

    public init(
        id: UUID,
        celsius: Double,
        relativeHumidity: Double,
        timestamp: Date,
        source: SensorSource,
        pressureHPa: Double? = nil,
        movementCount: Int? = nil
    ) {
        self.id = id
        self.celsius = celsius
        self.relativeHumidity = relativeHumidity
        self.timestamp = timestamp
        self.source = source
        self.pressureHPa = pressureHPa
        self.movementCount = movementCount
    }

    /// Derived — never stored.
    public var fahrenheit: Double { celsius * 9.0 / 5.0 + 32.0 }

    /// Which optional metrics this particular reading carries (for dialog/disclosure copy).
    public var hasPressure: Bool { pressureHPa != nil }
    public var hasMotion: Bool { movementCount != nil }
}
