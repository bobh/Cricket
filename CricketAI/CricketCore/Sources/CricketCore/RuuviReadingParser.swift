//
//  RuuviReadingParser.swift
//  CricketCore
//
//  Pure decoding of RuuviTag manufacturer advertisements (advertisement-only source).
//  Offsets are into the full manufacturer data, which begins with the little-endian
//  company id 0x0499 (bytes 0x99 0x04); the Ruuvi format byte is therefore at index 2.
//
//  Supports RAWv2 (format 5, the current tag — carries pressure + movement) and RAWv1
//  (format 3 — temp/humidity/pressure, no movement). Offsets follow the Ruuvi spec;
//  the shipping RuuviTagViewModel had wrong RAWv1 offsets and a RAWv2 Int16 overflow.
//

import Foundation

public enum RuuviReadingParser {

    /// Decode a RuuviTag manufacturer-data advertisement into a SensorSample.
    /// - Returns: a sample if the company id matches, the format is supported, and the
    ///   required temp/humidity fields are valid; otherwise nil. Optional pressure/motion
    ///   are populated when the format carries them and they are not the invalid sentinel.
    public static func sample(fromManufacturerData data: Data) -> SensorSample? {
        // Re-index from 0 so subscripts are stable regardless of the Data's slice origin.
        let b = [UInt8](data)
        guard b.count >= 3,
              b[0] == SensorConstants.ruuviManufacturerPrefix[0],
              b[1] == SensorConstants.ruuviManufacturerPrefix[1] else { return nil }

        switch b[2] {
        case SensorConstants.ruuviFormatRAWv2: return decodeRAWv2(b)
        case SensorConstants.ruuviFormatRAWv1: return decodeRAWv1(b)
        default: return nil
        }
    }

    // MARK: - RAWv2 (format 5), big-endian

    private static func decodeRAWv2(_ b: [UInt8]) -> SensorSample? {
        guard b.count >= 18 else { return nil }   // through movement counter at index 17

        // Temperature: Int16 ×0.005 °C; 0x8000 == invalid.
        let tempRaw = Int16(bitPattern: u16BE(b[3], b[4]))
        guard tempRaw != Int16(bitPattern: 0x8000) else { return nil }
        let celsius = Double(tempRaw) * 0.005

        // Humidity: UInt16 ×0.0025 %RH; 0xFFFF == invalid.
        let humRaw = u16BE(b[5], b[6])
        guard humRaw != 0xFFFF else { return nil }
        let humidity = Double(humRaw) * 0.0025

        guard SensorConstants.temperatureRangeC.contains(celsius),
              SensorConstants.humidityRangePct.contains(humidity) else { return nil }

        // Pressure: UInt16 + 50000 Pa → hPa; 0xFFFF == invalid → optional stays nil.
        let presRaw = u16BE(b[7], b[8])
        let pressureHPa: Double? = presRaw == 0xFFFF ? nil : (Double(presRaw) + 50000.0) / 100.0

        // Movement counter: UInt8 (a counter — any value is meaningful).
        let movement = Int(b[17])

        return SensorSample(
            celsius: celsius,
            relativeHumidity: humidity,
            pressureHPa: pressureHPa,
            movementCount: movement
        )
    }

    // MARK: - RAWv1 (format 3), big-endian

    private static func decodeRAWv1(_ b: [UInt8]) -> SensorSample? {
        guard b.count >= 8 else { return nil }     // through pressure at indices 6..7

        // Humidity: UInt8 ×0.5 %RH.
        let humidity = Double(b[3]) * 0.5

        // Temperature: b[4] integer part (bit7 = sign), b[5] fraction in 1/100 °C.
        let magnitude = Double(b[4] & 0x7F) + Double(b[5]) / 100.0
        let celsius = (b[4] & 0x80) != 0 ? -magnitude : magnitude

        guard SensorConstants.temperatureRangeC.contains(celsius),
              SensorConstants.humidityRangePct.contains(humidity) else { return nil }

        // Pressure: UInt16 + 50000 Pa → hPa; treat 0xFFFF as unavailable.
        let presRaw = u16BE(b[6], b[7])
        let pressureHPa: Double? = presRaw == 0xFFFF ? nil : (Double(presRaw) + 50000.0) / 100.0

        // RAWv1 carries no movement counter.
        return SensorSample(
            celsius: celsius,
            relativeHumidity: humidity,
            pressureHPa: pressureHPa,
            movementCount: nil
        )
    }

    // MARK: - Helpers

    private static func u16BE(_ hi: UInt8, _ lo: UInt8) -> UInt16 {
        (UInt16(hi) << 8) | UInt16(lo)
    }
}
