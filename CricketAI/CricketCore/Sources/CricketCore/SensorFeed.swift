//
//  SensorFeed.swift
//  CricketCore
//
//  Contract implemented in Phase 1 by BluetoothService (Arduino, connected) and
//  RuuviService (advertisement-only). Both push Sendable values into CricketCore.
//  Phase 0 defines only the seam — no concrete feed here.
//

/// A source of readings that feeds a `CricketCore` sink on the main actor.
///
/// Background acquisition (FR-8): the BLE implementation configures `CBCentralManager`
/// with a restoration identifier and the `bluetooth-central` background mode so readings
/// continue while the app is backgrounded. That lives in the Phase 1 conformer, not here.
@MainActor
public protocol SensorFeed: AnyObject {
    /// Begin (or resume) acquisition. Restores a persisted peripheral UUID if present.
    func start()

    /// The sink this feed pushes data and link-state changes into.
    var sink: CricketCore? { get set }
}
