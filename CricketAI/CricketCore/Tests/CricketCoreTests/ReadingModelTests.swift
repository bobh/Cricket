//
//  ReadingModelTests.swift
//  CricketCoreTests
//
//  Pure value semantics of Reading: derived Fahrenheit + optional-metric disclosure flags.
//

import Testing
import Foundation
@testable import CricketCore

@Suite("Reading model")
struct ReadingModelTests {

    @Test("Fahrenheit is derived correctly")
    func fahrenheitConversion() {
        let r = makeReading(ageSeconds: 0, celsius: 21.0)
        #expect(abs(r.fahrenheit - 69.8) < 0.0001)
    }

    @Test("Fahrenheit handles 0 °C and negative temperatures")
    func fahrenheitEdges() {
        #expect(abs(makeReading(ageSeconds: 0, celsius: 0).fahrenheit - 32.0) < 0.0001)
        #expect(abs(makeReading(ageSeconds: 0, celsius: -40).fahrenheit - -40.0) < 0.0001)
    }

    @Test("hasPressure / hasMotion reflect present optional metrics")
    func disclosureFlagsPresent() {
        let r = makeReading(ageSeconds: 0, pressureHPa: 1008.0, movementCount: 3)
        #expect(r.hasPressure)
        #expect(r.hasMotion)
    }

    @Test("hasPressure / hasMotion are false when metrics are absent")
    func disclosureFlagsAbsent() {
        let r = makeReading(ageSeconds: 0)
        #expect(!r.hasPressure)
        #expect(!r.hasMotion)
    }
}
