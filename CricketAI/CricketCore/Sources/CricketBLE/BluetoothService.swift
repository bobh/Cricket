//
//  BluetoothService.swift
//  CricketBLE
//
//  Arduino (connected-peripheral) SensorFeed. Owns a CBCentralManager, connects to the
//  Cricket peripheral by targeted UUID scan, persists/restores the peripheral, runs a
//  heartbeat keepalive, and feeds validated readings into CricketCore. All decoding uses
//  the pure parsers in CricketCore; this type is the thin CoreBluetooth glue.
//
//  App responsibilities (Stage 3, not here): the `bluetooth-central` background mode and
//  NSBluetoothAlwaysUsageDescription in the app's Info.plist/entitlements.
//

import Foundation
import CoreBluetooth
import CricketCore
#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class BluetoothService: NSObject, SensorFeed {

    public weak var sink: CricketCore?

    // nonisolated computed vars so delegate methods can read them without an actor hop.
    // Computed (not stored) because CBUUID is non-Sendable and can't back a nonisolated let.
    nonisolated private var serviceUUID: CBUUID { CBUUID(string: SensorConstants.serviceUUID) }
    nonisolated private var temperatureUUID: CBUUID { CBUUID(string: SensorConstants.temperatureUUID) }
    nonisolated private var humidityUUID: CBUUID { CBUUID(string: SensorConstants.humidityUUID) }

    private static let restoreIdentifier = "wm6h.CricketAI.arduino"
    private static let peripheralDefaultsKey = "arduinoPeripheralUUID"

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var temperatureCharacteristic: CBCharacteristic?
    private var assembler = ArduinoSampleAssembler()

    private var heartbeatTask: Task<Void, Never>?
    private var isInBackground = false
    private let foregroundHeartbeat: Duration = .seconds(20)
    private let backgroundHeartbeat: Duration = .seconds(60)

    /// Which characteristic a value belongs to — a Sendable stand-in for the non-Sendable
    /// CBUUID, resolved in the nonisolated delegate before hopping to the main actor.
    private enum CharKind: Sendable { case temperature, humidity }

    public override init() {
        super.init()
        #if os(iOS)
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: Self.restoreIdentifier]
        )
        #else
        centralManager = CBCentralManager(delegate: self, queue: nil)
        #endif
        observeLifecycle()
    }

    // MARK: - SensorFeed

    public func start() {
        guard centralManager.state == .poweredOn else { return }
        restoreOrScan()
    }

    // MARK: - Scanning / restore

    private func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        sink?.updateLink(.scanning)
        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    private func restoreOrScan() {
        guard let uuidString = UserDefaults.standard.string(forKey: Self.peripheralDefaultsKey),
              let uuid = UUID(uuidString: uuidString),
              let restored = centralManager.retrievePeripherals(withIdentifiers: [uuid]).first else {
            startScanning()
            return
        }
        peripheral = restored
        restored.delegate = self
        sink?.updateLink(.scanning)
        centralManager.connect(restored, options: nil)
    }

    private func preservePeripheral() {
        guard let peripheral else { return }
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: Self.peripheralDefaultsKey)
    }

    // MARK: - Heartbeat keepalive

    private func startHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let interval = isInBackground ? backgroundHeartbeat : foregroundHeartbeat
                try? await Task.sleep(for: interval)
                guard !Task.isCancelled else { return }
                if let peripheral, let characteristic = temperatureCharacteristic {
                    peripheral.readValue(for: characteristic)
                }
            }
        }
    }

    private func stopHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
    }

    // MARK: - Value handling (main actor)

    private func handleValue(_ data: Data, kind: CharKind) {
        switch kind {
        case .temperature:
            if let celsius = ArduinoReadingParser.temperatureCelsius(from: data) {
                if let sample = assembler.updating(temperatureCelsius: celsius) { emit(sample) }
            } else {
                sink?.noteSensorError()
            }
        case .humidity:
            if let humidity = ArduinoReadingParser.relativeHumidity(from: data) {
                if let sample = assembler.updating(relativeHumidity: humidity) { emit(sample) }
            } else {
                sink?.noteSensorError()
            }
        }
    }

    private func emit(_ sample: SensorSample) {
        sink?.ingest(Reading(
            id: UUID(),
            celsius: sample.celsius,
            relativeHumidity: sample.relativeHumidity,
            timestamp: Date(),
            source: .arduino,
            pressureHPa: sample.pressureHPa,      // nil until firmware exposes LPS22HB
            movementCount: sample.movementCount   // nil until firmware exposes BMI270
        ))
    }

    // MARK: - Link-state mapping

    private func handleStateChange(_ state: CBManagerState) {
        switch state {
        case .poweredOn:            restoreOrScan()
        case .poweredOff:           sink?.updateLink(.bluetoothOff)
        case .unauthorized:         sink?.updateLink(.bluetoothUnauthorized)
        case .unsupported:          sink?.updateLink(.bluetoothUnsupported)
        case .resetting, .unknown:  sink?.updateLink(.disconnected)
        @unknown default:           sink?.updateLink(.disconnected)
        }
    }

    // MARK: - App lifecycle (iOS only; drives heartbeat cadence)

    private func observeLifecycle() {
        #if canImport(UIKit)
        Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.didEnterBackgroundNotification) {
                self?.isInBackground = true
            }
        }
        Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.willEnterForegroundNotification) {
                self?.isInBackground = false
            }
        }
        #endif
    }
}

// MARK: - CBCentralManagerDelegate
//
// The manager is created with `queue: nil`, so CoreBluetooth delivers every callback on
// the main dispatch queue == the main actor. A `@preconcurrency` conformance lets this
// @MainActor class satisfy the (nonisolated) delegate requirements with MainActor methods;
// the compiler inserts a main-thread assertion. This is only sound because of `queue: nil`.

extension BluetoothService: @preconcurrency CBCentralManagerDelegate {

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        handleStateChange(central.state)
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard let uuids = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID],
              uuids.contains(serviceUUID) else { return }
        centralManager.stopScan()
        self.peripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        sink?.updateLink(.connected)
        peripheral.discoverServices([serviceUUID])
        startHeartbeat()
        preservePeripheral()
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        stopHeartbeat()
        sink?.updateLink(.disconnected)
        startScanning()
    }

    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            self?.startScanning()
        }
    }

    #if os(iOS)
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        guard let restored = (dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral])?.first
        else { return }
        peripheral = restored
        restored.delegate = self
    }
    #endif
}

// MARK: - CBPeripheralDelegate

extension BluetoothService: @preconcurrency CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([temperatureUUID, humidityUUID], for: service)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard error == nil, let characteristics = service.characteristics else { return }
        for characteristic in characteristics where
            characteristic.uuid == temperatureUUID || characteristic.uuid == humidityUUID {
            if characteristic.uuid == temperatureUUID { temperatureCharacteristic = characteristic }
            peripheral.readValue(for: characteristic)
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard error == nil, let data = characteristic.value else {
            sink?.noteSensorError()
            return
        }
        if characteristic.uuid == temperatureUUID {
            handleValue(data, kind: .temperature)
        } else if characteristic.uuid == humidityUUID {
            handleValue(data, kind: .humidity)
        }
    }
}
