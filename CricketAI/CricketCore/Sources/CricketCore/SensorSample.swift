//
//  SensorSample.swift
//  CricketCore
//
//  The decoded numeric fields a parser produces from one packet — with NO id or
//  timestamp. A SensorFeed promotes a SensorSample to a `Reading` by stamping the
//  capture time, a fresh id, and the source. Keeping the parser output free of
//  Date/UUID keeps parsing pure and deterministically testable.
//

/// Decoded sensor fields from a single packet, before promotion to a `Reading`.
public struct SensorSample: Sendable, Equatable {
    public let celsius: Double
    public let relativeHumidity: Double
    public let pressureHPa: Double?     // nil when the format/source doesn't carry it
    public let movementCount: Int?      // nil when the format/source doesn't carry it

    public init(
        celsius: Double,
        relativeHumidity: Double,
        pressureHPa: Double? = nil,
        movementCount: Int? = nil
    ) {
        self.celsius = celsius
        self.relativeHumidity = relativeHumidity
        self.pressureHPa = pressureHPa
        self.movementCount = movementCount
    }
}
