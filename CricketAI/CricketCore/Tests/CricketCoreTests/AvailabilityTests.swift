//
//  AvailabilityTests.swift
//  CricketCoreTests
//
//  Unavailable-reason mapping and the sensor-error path (FR-6, FR-7, AB-2).
//

import Testing
import Foundation
@testable import CricketCore

@MainActor
@Suite("Availability & unavailable reasons")
struct AvailabilityTests {

    @Test("No reading yet, idle link → neverConnected")
    func freshInstallIsNeverConnected() {
        let core = CricketCore(now: { testBase })
        #expect(core.currentConditions() == .unavailable(.neverConnected))
    }

    @Test("Link-state maps to the matching unavailable reason when no reading is cached",
          arguments: [
            (LinkState.bluetoothOff,          UnavailableReason.bluetoothOff),
            (LinkState.bluetoothUnauthorized, UnavailableReason.bluetoothUnauthorized),
            (LinkState.bluetoothUnsupported,  UnavailableReason.bluetoothUnsupported),
            (LinkState.disconnected,          UnavailableReason.disconnected),
            (LinkState.scanning,              UnavailableReason.neverConnected),
            (LinkState.connected,             UnavailableReason.neverConnected),
          ])
    func linkStateMapsToReason(state: LinkState, expected: UnavailableReason) {
        let core = CricketCore(now: { testBase })
        core.updateLink(state)
        #expect(core.currentConditions() == .unavailable(expected))
    }

    @Test("Sensor error with no prior reading → unavailable(.sensorError)")
    func sensorErrorSurfacesWhenNoReading() {
        let core = CricketCore(now: { testBase })
        core.noteSensorError()
        #expect(core.currentConditions() == .unavailable(.sensorError))
    }

    @Test("Sensor error after a good reading still serves the last-known reading")
    func sensorErrorDoesNotClobberLastGood() {
        let core = CricketCore(now: { testBase })
        let good = makeReading(ageSeconds: 30)
        core.ingest(good)
        core.noteSensorError()
        #expect(core.currentConditions().reading == good)
    }

    @Test("A fresh ingest clears a prior sensor-error state")
    func ingestClearsSensorError() {
        let core = CricketCore(now: { testBase })
        core.noteSensorError()
        core.ingest(makeReading(ageSeconds: 10))
        #expect(core.currentConditions().reading != nil)
        // Drop the reading? We can't; but reason is gone because latest != nil.
        #expect(core.currentConditions() != .unavailable(.sensorError))
    }
}
