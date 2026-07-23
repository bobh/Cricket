//
//  RuuviService.swift
//  CricketBLE
//
//  RuuviTag (advertisement-only) SensorFeed. Scans with duplicates enabled to receive
//  repeated advertisements, decodes each with the pure RuuviReadingParser, and feeds the
//  result into CricketCore. No connection is made, and no freshness timer is kept —
//  freshness now lives in CricketCore (the old RuuviTagViewModel poll is retired).
//

import Foundation
import CoreBluetooth
import CricketCore

@MainActor
public final class RuuviService: NSObject, SensorFeed {

    public weak var sink: CricketCore?

    private var centralManager: CBCentralManager!

    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    public func start() {
        guard centralManager.state == .poweredOn else { return }
        beginScanning()
    }

    private func beginScanning() {
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    private func handleStateChange(_ state: CBManagerState) {
        switch state {
        case .poweredOn:            beginScanning()
        case .poweredOff:           sink?.updateLink(.bluetoothOff)
        case .unauthorized:         sink?.updateLink(.bluetoothUnauthorized)
        case .unsupported:          sink?.updateLink(.bluetoothUnsupported)
        case .resetting, .unknown:  break        // transient; don't override a live source
        @unknown default:           break
        }
    }

    private func ingest(_ sample: SensorSample) {
        sink?.ingest(Reading(
            id: UUID(),
            celsius: sample.celsius,
            relativeHumidity: sample.relativeHumidity,
            timestamp: Date(),
            source: .ruuvi,
            pressureHPa: sample.pressureHPa,
            movementCount: sample.movementCount
        ))
    }
}

// MARK: - CBCentralManagerDelegate
//
// `queue: nil` delivers callbacks on the main queue == the main actor; a `@preconcurrency`
// conformance lets this @MainActor class satisfy the delegate requirements directly.

extension RuuviService: @preconcurrency CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        handleStateChange(central.state)
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
              let sample = RuuviReadingParser.sample(fromManufacturerData: manufacturerData) else { return }
        ingest(sample)
    }
}
