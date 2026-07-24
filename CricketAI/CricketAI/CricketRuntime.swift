//
//  CricketRuntime.swift
//  CricketAI
//
//  Composition root for the live app process. Owns the single CricketCore (source of
//  truth) plus both SensorFeed conformers, wires the feeds' sinks to the core, and
//  starts acquisition. SwiftUI observes `core`; the feeds run behind the scenes.
//
//  App Intents that run out-of-process do NOT use this object — they read the last-known
//  reading from the shared App Group via a transient CricketCore (see CricketAppIntents).
//

import SwiftUI
import CricketCore
import CricketBLE

@MainActor
@Observable
final class CricketRuntime {
    /// The single source of truth the UI and in-process readers observe.
    let core: CricketCore

    private let arduino: BluetoothService
    private let ruuvi: RuuviService

    init() {
        // Persist to the shared App Group so out-of-process App Intents stay warm.
        core = CricketCore(persistence: AppGroupReadingStore())
        arduino = BluetoothService()
        ruuvi = RuuviService()
        arduino.sink = core
        ruuvi.sink = core
    }

    /// Begin acquisition. Each feed also self-starts when Bluetooth powers on, so this is
    /// idempotent and safe to call whenever the app becomes active.
    func start() {
        arduino.start()
        ruuvi.start()
    }
}
