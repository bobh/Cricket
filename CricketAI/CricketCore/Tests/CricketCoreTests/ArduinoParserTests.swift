//
//  ArduinoParserTests.swift
//  CricketCoreTests
//
//  Float32 characteristic decoding: valid values, malformed length, NaN/Inf, range gate.
//

import Testing
import Foundation
@testable import CricketCore

@Suite("Arduino float32 parser")
struct ArduinoParserTests {

    /// Little-endian 4-byte encoding of a Float, as the firmware transmits it.
    private func le(_ value: Float) -> Data {
        var bits = value.bitPattern.littleEndian
        return withUnsafeBytes(of: &bits) { Data($0) }
    }

    @Test("Valid temperature round-trips")
    func validTemperature() {
        #expect(near(ArduinoReadingParser.temperatureCelsius(from: le(21.5)), 21.5))
    }

    @Test("Valid humidity round-trips")
    func validHumidity() {
        #expect(near(ArduinoReadingParser.relativeHumidity(from: le(45.0)), 45.0))
    }

    @Test("Range boundaries are accepted")
    func boundaries() {
        #expect(near(ArduinoReadingParser.temperatureCelsius(from: le(-40.0)), -40.0))
        #expect(near(ArduinoReadingParser.temperatureCelsius(from: le(125.0)), 125.0))
        #expect(near(ArduinoReadingParser.relativeHumidity(from: le(0.0)), 0.0))
        #expect(near(ArduinoReadingParser.relativeHumidity(from: le(100.0)), 100.0))
    }

    @Test("Startup 0.0 placeholder parses (feed-level concern, not parser)")
    func startupZeroParses() {
        #expect(near(ArduinoReadingParser.temperatureCelsius(from: le(0.0)), 0.0))
    }

    @Test("Wrong-length payloads are rejected")
    func wrongLength() {
        #expect(ArduinoReadingParser.temperatureCelsius(from: Data([0x00, 0x00, 0x00])) == nil)
        #expect(ArduinoReadingParser.temperatureCelsius(from: Data([0, 0, 0, 0, 0])) == nil)
        #expect(ArduinoReadingParser.temperatureCelsius(from: Data()) == nil)
    }

    @Test("NaN and infinity are rejected")
    func nonFinite() {
        #expect(ArduinoReadingParser.temperatureCelsius(from: le(.nan)) == nil)
        #expect(ArduinoReadingParser.temperatureCelsius(from: le(.infinity)) == nil)
        #expect(ArduinoReadingParser.temperatureCelsius(from: le(-.infinity)) == nil)
    }

    @Test("Out-of-range values are rejected")
    func outOfRange() {
        #expect(ArduinoReadingParser.temperatureCelsius(from: le(200.0)) == nil)
        #expect(ArduinoReadingParser.temperatureCelsius(from: le(-100.0)) == nil)
        #expect(ArduinoReadingParser.relativeHumidity(from: le(150.0)) == nil)
        #expect(ArduinoReadingParser.relativeHumidity(from: le(-1.0)) == nil)
    }
}

/// Double? proximity check for parser assertions.
func near(_ value: Double?, _ expected: Double, tol: Double = 0.001) -> Bool {
    guard let value else { return false }
    return abs(value - expected) < tol
}
