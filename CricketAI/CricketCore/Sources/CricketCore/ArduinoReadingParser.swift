//
//  ArduinoReadingParser.swift
//  CricketCore
//
//  Pure decoding of the Cricket firmware's custom float32 characteristics.
//  Temperature and humidity arrive as SEPARATE characteristics, so each is decoded
//  independently; the feed combines the latest of each into a SensorSample/Reading.
//
//  Validity contract (FR-3): the firmware never transmits a sentinel — on a bad read
//  it retains the last good value. So the only defenses needed are length, NaN/Inf,
//  and a physical-plausibility gate.
//

import Foundation

public enum ArduinoReadingParser {

    /// Decode a temperature characteristic payload (IEEE-754 float32, little-endian, °C).
    /// - Returns: Celsius, or nil if the payload is malformed or physically implausible.
    public static func temperatureCelsius(from data: Data) -> Double? {
        guard let value = float32LE(data),
              SensorConstants.temperatureRangeC.contains(Double(value)) else { return nil }
        return Double(value)
    }

    /// Decode a humidity characteristic payload (IEEE-754 float32, little-endian, %RH).
    /// - Returns: relative humidity, or nil if malformed or out of range.
    public static func relativeHumidity(from data: Data) -> Double? {
        guard let value = float32LE(data),
              SensorConstants.humidityRangePct.contains(Double(value)) else { return nil }
        return Double(value)
    }

    // MARK: - Private

    /// Decode exactly 4 bytes as a little-endian Float, rejecting NaN/Inf.
    /// Uses `loadUnaligned` to avoid the alignment hazard of `load(as:)`.
    private static func float32LE(_ data: Data) -> Float? {
        guard data.count == 4 else { return nil }
        let bits = data.withUnsafeBytes { raw in
            raw.loadUnaligned(as: UInt32.self)
        }
        let value = Float(bitPattern: UInt32(littleEndian: bits))
        guard value.isFinite else { return nil }   // rejects NaN and ±Inf
        return value
    }
}
