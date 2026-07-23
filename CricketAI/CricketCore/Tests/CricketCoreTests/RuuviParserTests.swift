//
//  RuuviParserTests.swift
//  CricketCoreTests
//
//  RuuviTag advertisement decoding against canonical spec vectors, invalid sentinels,
//  and a regression for the RAWv2 Int16 overflow (data[3] > 127) that trapped the
//  shipping parser.
//

import Testing
import Foundation
@testable import CricketCore

@Suite("RuuviTag parser")
struct RuuviParserTests {

    private func d(_ bytes: [UInt8]) -> Data { Data(bytes) }

    // Canonical RAWv2 (format 5) vector from the Ruuvi spec, prefixed with company id 0x0499.
    // Decodes to 24.3 °C, 53.49 %RH, 1000.44 hPa, movement 66.
    private let rawV2: [UInt8] = [
        0x99, 0x04,                                     // company id 0x0499 (LE)
        0x05, 0x12, 0xFC, 0x53, 0x94, 0xC3, 0x7C,       // format, temp, humidity, pressure
        0x00, 0x04, 0xFF, 0xFC, 0x04, 0x0C, 0xAC,       // accel X/Y/Z
        0x36, 0x42, 0x00, 0xCD, 0xCB, 0xB8,             // power, movement(0x42=66), seq
        0x33, 0x4C, 0x88, 0x4F,                         // ...remainder
    ]

    // Canonical RAWv1 (format 3) vector: 20.5 %RH, 26.3 °C, 102766 Pa.
    private let rawV1: [UInt8] = [
        0x99, 0x04,
        0x03, 0x29, 0x1A, 0x1E, 0xCE, 0x1E, 0xFC, 0x18, 0xF9, 0x42, 0x02, 0xCA, 0x0B, 0x53,
    ]

    @Test("RAWv2 decodes temperature, humidity, pressure, and movement")
    func rawV2Valid() throws {
        let s = try #require(RuuviReadingParser.sample(fromManufacturerData: d(rawV2)))
        #expect(near(s.celsius, 24.3))
        #expect(near(s.relativeHumidity, 53.49, tol: 0.01))
        #expect(near(s.pressureHPa, 1000.44, tol: 0.01))
        #expect(s.movementCount == 66)
    }

    @Test("RAWv1 decodes temperature, humidity, pressure; no movement")
    func rawV1Valid() throws {
        let s = try #require(RuuviReadingParser.sample(fromManufacturerData: d(rawV1)))
        #expect(near(s.celsius, 26.3))
        #expect(near(s.relativeHumidity, 20.5))
        #expect(near(s.pressureHPa, 1027.66, tol: 0.01))
        #expect(s.movementCount == nil)
    }

    @Test("Wrong manufacturer id is rejected")
    func wrongManufacturer() {
        var bytes = rawV2
        bytes[0] = 0x4C; bytes[1] = 0x00                // Apple, not Ruuvi
        #expect(RuuviReadingParser.sample(fromManufacturerData: d(bytes)) == nil)
    }

    @Test("Unsupported format is rejected")
    func unsupportedFormat() {
        var bytes = rawV2
        bytes[2] = 0x04                                 // neither RAWv1 nor RAWv2
        #expect(RuuviReadingParser.sample(fromManufacturerData: d(bytes)) == nil)
    }

    @Test("Truncated advertisements are rejected")
    func truncated() {
        #expect(RuuviReadingParser.sample(fromManufacturerData: d([0x99, 0x04, 0x05])) == nil)
        #expect(RuuviReadingParser.sample(fromManufacturerData: d([0x99])) == nil)
        #expect(RuuviReadingParser.sample(fromManufacturerData: Data()) == nil)
    }

    @Test("RAWv2 invalid temperature sentinel (0x8000) → nil")
    func rawV2InvalidTemp() {
        var bytes = rawV2
        bytes[3] = 0x80; bytes[4] = 0x00
        #expect(RuuviReadingParser.sample(fromManufacturerData: d(bytes)) == nil)
    }

    @Test("RAWv2 invalid humidity sentinel (0xFFFF) → nil")
    func rawV2InvalidHumidity() {
        var bytes = rawV2
        bytes[5] = 0xFF; bytes[6] = 0xFF
        #expect(RuuviReadingParser.sample(fromManufacturerData: d(bytes)) == nil)
    }

    @Test("RAWv2 invalid pressure sentinel (0xFFFF) → sample present, pressure nil")
    func rawV2InvalidPressure() throws {
        var bytes = rawV2
        bytes[7] = 0xFF; bytes[8] = 0xFF
        let s = try #require(RuuviReadingParser.sample(fromManufacturerData: d(bytes)))
        #expect(s.pressureHPa == nil)
        #expect(near(s.celsius, 24.3))               // core fields still decode
    }

    @Test("REGRESSION: RAWv2 negative temperature (data[3] > 127) does not trap and decodes")
    func rawV2NegativeTemperatureNoTrap() throws {
        // -4.0 °C = raw -800 = Int16 bit pattern 0xFCE0 → data[3]=0xFC (252 > 127).
        // The shipping `Int16(data[3]) << 8` trapped here.
        var bytes = rawV2
        bytes[3] = 0xFC; bytes[4] = 0xE0
        let s = try #require(RuuviReadingParser.sample(fromManufacturerData: d(bytes)))
        #expect(near(s.celsius, -4.0))
    }
}
