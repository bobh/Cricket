//
//  SourceArbitrationTests.swift
//  CricketCoreTests
//
//  Source priority: prefer RuuviTag when its reading is live; fall back to Arduino
//  only when the Ruuvi reading has gone stale (AI-direction decision).
//

import Testing
import Foundation
@testable import CricketCore

@MainActor
@Suite("Source arbitration")
struct SourceArbitrationTests {

    @Test("First reading from any source is accepted")
    func firstReadingWins() {
        let core = CricketCore(now: { testBase })
        core.ingest(makeReading(ageSeconds: 0, source: .arduino))
        #expect(core.latest?.source == .arduino)
    }

    @Test("Ruuvi replaces a live Arduino reading (Ruuvi preferred)")
    func ruuviBeatsArduino() {
        let core = CricketCore(now: { testBase })
        core.ingest(makeReading(ageSeconds: 0, source: .arduino))
        core.ingest(makeReading(ageSeconds: 0, source: .ruuvi))
        #expect(core.latest?.source == .ruuvi)
    }

    @Test("Arduino does NOT replace a fresh Ruuvi reading")
    func arduinoYieldsToFreshRuuvi() {
        let core = CricketCore(now: { testBase })
        core.ingest(makeReading(ageSeconds: 30, source: .ruuvi))   // fresh (< 300 s)
        core.ingest(makeReading(ageSeconds: 0, source: .arduino))
        #expect(core.latest?.source == .ruuvi)
    }

    @Test("Arduino DOES replace a stale Ruuvi reading (fallback)")
    func arduinoFallsBackWhenRuuviStale() {
        let core = CricketCore(now: { testBase })
        core.ingest(makeReading(ageSeconds: 600, source: .ruuvi))  // stale (> 300 s)
        core.ingest(makeReading(ageSeconds: 0, source: .arduino))
        #expect(core.latest?.source == .arduino)
    }

    @Test("Same-source readings always update")
    func sameSourceUpdates() {
        let core = CricketCore(now: { testBase })
        let first = makeReading(ageSeconds: 30, source: .ruuvi)
        let second = makeReading(ageSeconds: 0, source: .ruuvi)
        core.ingest(first)
        core.ingest(second)
        #expect(core.latest == second)
    }

    @Test("A losing lower-priority reading still marks the link connected")
    func losingReadingStillConnects() {
        let core = CricketCore(now: { testBase })
        core.ingest(makeReading(ageSeconds: 30, source: .ruuvi))
        core.updateLink(.scanning)
        core.ingest(makeReading(ageSeconds: 0, source: .arduino))   // loses arbitration
        #expect(core.linkState == .connected)
        #expect(core.latest?.source == .ruuvi)
    }
}
