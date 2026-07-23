//
//  SensorConstants.swift
//  CricketCore
//
//  BLE identifiers and physical-plausibility ranges shared by the pure parsers.
//  UUIDs are plain strings here; CBUUID construction stays in the app-target feed
//  so this module has no CoreBluetooth dependency and stays hardware-free testable.
//

public enum SensorConstants {

    // MARK: Arduino custom Environmental Sensing service (float32)
    public static let serviceUUID     = "5971E8F1-BC4D-4A5F-A6FD-3591131A98C6"
    public static let temperatureUUID = "78B20AF1-E597-40C1-A69C-304205B7E099"
    public static let humidityUUID    = "0BA15AA1-A805-4205-BC82-AF2E4A9364C5"

    /// Fallback advertised name used when the peripheral advertises no service UUIDs.
    public static let arduinoFallbackName = "Nano33BLE_Sensor"

    // MARK: RuuviTag manufacturer advertisement
    /// Company identifier 0x0499, little-endian in the advertisement (bytes 0x99 0x04).
    public static let ruuviManufacturerPrefix: [UInt8] = [0x99, 0x04]
    public static let ruuviFormatRAWv1: UInt8 = 0x03
    public static let ruuviFormatRAWv2: UInt8 = 0x05

    // MARK: Physical-plausibility gates (FR-3)
    /// Accepted temperature range in °C. Outside → rejected (nil), never fabricated.
    public static let temperatureRangeC: ClosedRange<Double> = -40.0...125.0
    /// Accepted relative-humidity range in %RH.
    public static let humidityRangePct: ClosedRange<Double> = 0.0...100.0
}
