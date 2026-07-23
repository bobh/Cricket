//
//  TestHelpers.swift
//  CricketCoreTests
//
//  Hardware-free fakes so CricketCore's freshness/availability logic is fully testable
//  without CoreBluetooth or a real App Group (NFR-5).
//

import Foundation
@testable import CricketCore

/// A fake feed that pushes values into a CricketCore sink on demand.
@MainActor
final class FakeSensorFeed: SensorFeed {
    weak var sink: CricketCore?
    private(set) var started = false

    func start() { started = true }

    func emit(_ reading: Reading)     { sink?.ingest(reading) }
    func emitLink(_ state: LinkState) { sink?.updateLink(state) }
    func emitSensorError()            { sink?.noteSensorError() }
}

/// An in-memory ReadingPersisting for round-trip and warm-start tests.
/// `@unchecked Sendable`: guarded by a lock, conforms to the Sendable protocol.
final class InMemoryReadingStore: ReadingPersisting, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Reading?

    init(seed: Reading? = nil) { self.stored = seed }

    func save(_ reading: Reading) {
        lock.lock(); defer { lock.unlock() }
        stored = reading
    }

    func load() -> Reading? {
        lock.lock(); defer { lock.unlock() }
        return stored
    }
}

/// Fixed epoch for deterministic freshness tests.
let testBase = Date(timeIntervalSince1970: 1_000_000)

/// A reading captured `ageSeconds` before `base`.
func makeReading(
    ageSeconds: Double,
    at base: Date = testBase,
    celsius: Double = 21.0,
    relativeHumidity: Double = 45.0,
    source: SensorSource = .arduino,
    pressureHPa: Double? = nil,
    movementCount: Int? = nil
) -> Reading {
    Reading(
        id: UUID(),
        celsius: celsius,
        relativeHumidity: relativeHumidity,
        timestamp: base.addingTimeInterval(-ageSeconds),
        source: source,
        pressureHPa: pressureHPa,
        movementCount: movementCount
    )
}
