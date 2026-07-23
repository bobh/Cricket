//
//  PersistenceTests.swift
//  CricketCoreTests
//
//  Persistence round-trip and cold-launch warm-start (FR-8 fallback, DR-0).
//

import Testing
import Foundation
@testable import CricketCore

@MainActor
@Suite("Persistence & warm-start")
struct PersistenceTests {

    @Test("Ingesting a reading persists it to the store")
    func ingestPersists() {
        let store = InMemoryReadingStore()
        let core = CricketCore(now: { testBase }, persistence: store)
        let reading = makeReading(ageSeconds: 5)
        core.ingest(reading)
        #expect(store.load() == reading)
    }

    @Test("A new core warm-starts from the persisted last-known reading")
    func warmStartFromPersistence() {
        let seed = makeReading(ageSeconds: 30)
        let store = InMemoryReadingStore(seed: seed)
        let core = CricketCore(now: { testBase }, persistence: store)
        #expect(core.latest == seed)
        #expect(core.currentConditions().reading == seed)
    }

    @Test("Reading survives an encode/decode round-trip with optional metrics")
    func codableRoundTrip() throws {
        let original = makeReading(
            ageSeconds: 12,
            pressureHPa: 1013.2,
            movementCount: 7
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Reading.self, from: data)
        #expect(decoded == original)
        #expect(decoded.pressureHPa == 1013.2)
        #expect(decoded.movementCount == 7)
    }

    @Test("nil optional metrics survive the round-trip as nil")
    func codableRoundTripNilMetrics() throws {
        let original = makeReading(ageSeconds: 12)   // pressure/motion nil
        let decoded = try JSONDecoder().decode(
            Reading.self,
            from: try JSONEncoder().encode(original)
        )
        #expect(decoded.pressureHPa == nil)
        #expect(decoded.movementCount == nil)
    }
}
