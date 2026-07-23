//
//  FreshnessTests.swift
//  CricketCoreTests
//
//  Fresh vs stale classification against an injectable clock (FR-5, DR-4, NFR-5).
//

import Testing
import Foundation
@testable import CricketCore

@MainActor
@Suite("Freshness classification")
struct FreshnessTests {

    @Test("A recent reading is fresh")
    func recentIsFresh() {
        let core = CricketCore(now: { testBase })
        core.ingest(makeReading(ageSeconds: 60))     // 1 min old, threshold 5 min
        #expect(core.currentConditions().isFresh)
    }

    @Test("A reading exactly at the threshold is still fresh (≤ is fresh)")
    func boundaryIsFresh() {
        let core = CricketCore(now: { testBase })
        core.ingest(makeReading(ageSeconds: 300))    // exactly 300 s, threshold 300 s
        #expect(core.currentConditions().isFresh)
    }

    @Test("A reading one second past the threshold is stale")
    func justPastBoundaryIsStale() {
        let core = CricketCore(now: { testBase })
        core.ingest(makeReading(ageSeconds: 301))
        guard case .stale(_, let age) = core.currentConditions() else {
            Issue.record("expected .stale")
            return
        }
        #expect(age > .seconds(300))
    }

    @Test("Stale result reports the underlying reading and its age")
    func staleCarriesReadingAndAge() {
        let core = CricketCore(now: { testBase })
        let reading = makeReading(ageSeconds: 600)   // 10 min old
        core.ingest(reading)
        let result = core.currentConditions()
        #expect(result.reading == reading)
        if case .stale(_, let age) = result {
            #expect(age >= .seconds(599) && age <= .seconds(601))
        } else {
            Issue.record("expected .stale")
        }
    }

    @Test("A custom freshness threshold is honored")
    func customThreshold() {
        let core = CricketCore(now: { testBase })
        core.freshnessThreshold = .seconds(30)
        core.ingest(makeReading(ageSeconds: 60))     // older than 30 s
        #expect(core.currentConditions().isStale)
    }
}

// Small readability helpers for the assertions above.
private extension ReadingResult {
    var isFresh: Bool { if case .fresh = self { return true }; return false }
    var isStale: Bool { if case .stale = self { return true }; return false }
}
