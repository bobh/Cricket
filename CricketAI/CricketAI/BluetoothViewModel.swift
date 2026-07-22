//
//  BluetoothViewModel.swift
//  CricketIOS
//

import Foundation
import CoreBluetooth
import AppIntents
import UIKit
import WidgetKit

// MARK: - BluetoothViewModel

@MainActor
@Observable
final class BluetoothViewModel: NSObject {

    // MARK: - Observable State

    var temperature: String = "--"
    var humidity: String = "--"
    var connectionStatus: String = "Disconnected"
    var lastUpdated: Date? = nil
    var isActiveSource: Bool = false

    var isBluetoothReady: Bool {
        centralManager?.state == .poweredOn
    }

    // MARK: - BLE UUIDs
    // nonisolated: let constants accessible from delegate extensions without an actor hop

    nonisolated private let environmentalSensingServiceUUID = CBUUID(string: "5971E8F1-BC4D-4A5F-A6FD-3591131A98C6")
    nonisolated private let temperatureCharacteristicUUID   = CBUUID(string: "78B20AF1-E597-40C1-A69C-304205B7E099")
    nonisolated private let humidityCharacteristicUUID      = CBUUID(string: "0BA15AA1-A805-4205-BC82-AF2E4A9364C5")

    // MARK: - Private State

    private let sharedDefaults = UserDefaults(suiteName: "group.wm6h.CricketAI")
    private var centralManager: CBCentralManager!
    private var discoveredPeripheral: CBPeripheral?
    private var temperatureCharacteristic: CBCharacteristic?
    private var humidityCharacteristic: CBCharacteristic?
    private var writeQueue: [Data] = []
    private var isInBackground = false

    private var heartbeatTask: Task<Void, Never>?

    private let foregroundHeartbeatInterval: Duration = .seconds(20)
    private let backgroundHeartbeatInterval: Duration = .seconds(60)

    // MARK: - Init

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        loadStoredValues()
        observeAppLifecycle()
    }

    // MARK: - App Lifecycle

    private func observeAppLifecycle() {
        Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.didEnterBackgroundNotification) {
                guard let self else { return }
                isInBackground = true
                if heartbeatTask != nil { startHeartbeat() }
                preservePeripheralState()
            }
        }
        Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: UIApplication.willEnterForegroundNotification) {
                guard let self else { return }
                isInBackground = false
                if heartbeatTask != nil { startHeartbeat() }
            }
        }
    }

    // MARK: - Stored Values

    private func loadStoredValues() {
        temperature = sharedDefaults?.string(forKey: "temperature") ?? "--"
        humidity    = sharedDefaults?.string(forKey: "humidity")    ?? "--"
    }

    private func saveValues() {
        // Always write Arduino-specific keys for calibration logging
        UserDefaults.standard.set(temperature,      forKey: "arduino_temperature")
        UserDefaults.standard.set(humidity,         forKey: "arduino_humidity")
        UserDefaults.standard.set(connectionStatus, forKey: "arduino_status")
        UserDefaults.standard.set(Date(),           forKey: "arduino_lastUpdated")

        guard isActiveSource else { return }

        // Active sensor writes to generic keys for App Intents
        UserDefaults.standard.set(temperature,      forKey: "currentTemperature")
        UserDefaults.standard.set(humidity,         forKey: "currentHumidity")
        UserDefaults.standard.set(connectionStatus, forKey: "connectionStatus")

        // App Group keys for widget
        sharedDefaults?.set(temperature, forKey: "temperature")
        sharedDefaults?.set(humidity,    forKey: "humidity")
        sharedDefaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()

        donateIntents()
    }

    private func donateIntents() {
        Task {
            do { try await GetLocalTemperatureIntent().donate() } catch { }
            do { try await GetLocalHumidityIntent().donate() } catch { }
        }
    }

    // MARK: - Scanning

    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        connectionStatus = "Scanning for Arduino sensor..."
        centralManager.scanForPeripherals(
            withServices: [environmentalSensingServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard let self, discoveredPeripheral == nil else { return }
            connectionStatus = "No Arduino found. Is it powered on?"
        }
    }

    func showResetMessage() {
        connectionStatus = "Reset Arduino: Press white reset button"
        temperature  = "--"
        humidity     = "--"
        lastUpdated  = nil
    }

    // MARK: - BLE Cache Management

    func clearBLECache() {
        if let peripheral = discoveredPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        discoveredPeripheral      = nil
        temperatureCharacteristic = nil
        humidityCharacteristic    = nil

        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys
            where key.hasPrefix("lastSeen_") || key.hasPrefix("fw_version_") {
            defaults.removeObject(forKey: key)
        }

        temperature      = "--"
        humidity         = "--"
        connectionStatus = "Cache cleared - Restarting scan..."

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            self?.startScanning()
        }
    }

    // MARK: - Peripheral State Persistence

    private func preservePeripheralState() {
        guard let peripheral = discoveredPeripheral else { return }
        UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: "lastConnectedPeripheralUUID")
    }

    func restorePeripheralConnection() {
        guard let uuidString = UserDefaults.standard.string(forKey: "lastConnectedPeripheralUUID"),
              let uuid = UUID(uuidString: uuidString) else {
            startScanning()
            return
        }
        let peripherals = centralManager.retrievePeripherals(withIdentifiers: [uuid])
        if let peripheral = peripherals.first {
            discoveredPeripheral = peripheral
            peripheral.delegate  = self
            centralManager.connect(peripheral, options: nil)
            connectionStatus = "Reconnecting to Arduino..."
        } else {
            startScanning()
        }
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let interval = isInBackground ? backgroundHeartbeatInterval : foregroundHeartbeatInterval
                try? await Task.sleep(for: interval)
                guard !Task.isCancelled else { return }
                sendHeartbeat()
            }
        }
    }

    private func stopHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
    }

    private func sendHeartbeat() {
        guard let peripheral = discoveredPeripheral,
              let characteristic = temperatureCharacteristic else { return }
        peripheral.readValue(for: characteristic)
    }

    // MARK: - Write Flow Control

    func writeValue(_ data: Data, withResponse: Bool = false) {
        guard let peripheral = discoveredPeripheral,
              let characteristic = temperatureCharacteristic else { return }
        if withResponse {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        } else if peripheral.canSendWriteWithoutResponse {
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        } else {
            writeQueue.append(data)
        }
    }

    /*
    func setLEDColor(_ color: LEDColor) {
        writeValue(Data([color.rawValue]), withResponse: false)
    }
     */

    // MARK: - Data Parsing

    /// Parses Arduino IEEE 754 float32 temperature (4 bytes, little-endian).
    nonisolated private func parseTemperature(from data: Data) -> Float? {
        guard data.count == 4 else { return nil }
        let value = data.withUnsafeBytes { $0.load(as: Float.self) }
        return value.isFinite ? value : nil
    }

    /// Parses Arduino IEEE 754 float32 humidity (4 bytes, little-endian).
    nonisolated private func parseHumidity(from data: Data) -> Float? {
        guard data.count == 4 else { return nil }
        let value = data.withUnsafeBytes { $0.load(as: Float.self) }
        return value.isFinite ? value : nil
    }

    // MARK: - BLE State Handling

    private func handleStateChange(_ state: CBManagerState) {
        switch state {
        case .poweredOn:
            connectionStatus = "Scanning for Arduino sensor..."
            if UserDefaults.standard.string(forKey: "lastConnectedPeripheralUUID") != nil {
                restorePeripheralConnection()
            } else {
                centralManager.scanForPeripherals(
                    withServices: [environmentalSensingServiceUUID],
                    options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
                )
            }
        case .poweredOff:
            connectionStatus = "Bluetooth is off - Enable in Settings"
            temperature = "--"
            humidity    = "--"
        case .unauthorized:
            connectionStatus = "Bluetooth access denied - Check Privacy settings"
            temperature = "--"
            humidity    = "--"
        case .unsupported:
            connectionStatus = "This device doesn't support Bluetooth Low Energy"
            temperature = "--"
            humidity    = "--"
        case .resetting:
            connectionStatus = "Bluetooth resetting..."
        case .unknown:
            connectionStatus = "Bluetooth state unknown - waiting..."
        @unknown default:
            connectionStatus = "Unexpected Bluetooth state"
        }
    }
}

// MARK: - CBCentralManagerDelegate
// All methods are nonisolated — CoreBluetooth calls them from its internal queue.
// State is extracted before the Task hop to avoid sending non-Sendable CoreBluetooth
// objects across the actor boundary.

extension BluetoothViewModel: CBCentralManagerDelegate {

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        Task { @MainActor [weak self] in
            self?.handleStateChange(state)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID],
              serviceUUIDs.contains(environmentalSensingServiceUUID) else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            centralManager.stopScan()
            discoveredPeripheral = peripheral
            peripheral.delegate  = self
            centralManager.connect(peripheral, options: nil)
            connectionStatus = "Connecting to Arduino..."
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            connectionStatus = "Connected to Arduino"
            peripheral.discoverServices(nil)
            startHeartbeat()
            preservePeripheralState()
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        let message = error.map { "Disconnected: \($0.localizedDescription)" } ?? "Disconnected"
        Task { @MainActor [weak self] in
            guard let self else { return }
            stopHeartbeat()
            connectionStatus = message
            centralManager.scanForPeripherals(
                withServices: [environmentalSensingServiceUUID],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
            )
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            connectionStatus = "Connection failed"
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                self?.startScanning()
            }
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothViewModel: CBPeripheralDelegate {

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard error == nil, let characteristics = service.characteristics else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            for characteristic in characteristics {
                if characteristic.uuid == temperatureCharacteristicUUID {
                    temperatureCharacteristic = characteristic
                    peripheral.readValue(for: characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                } else if characteristic.uuid == humidityCharacteristicUUID {
                    humidityCharacteristic = characteristic
                    peripheral.readValue(for: characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error {
            let message = "Update error: \(error.localizedDescription)"
            Task { @MainActor [weak self] in self?.connectionStatus = message }
            return
        }
        guard let data = characteristic.value else { return }

        // Copy Sendable values before crossing to @MainActor
        let uuid     = characteristic.uuid
        let dataCopy = data

        Task { @MainActor [weak self] in
            guard let self else { return }
            if uuid == temperatureCharacteristicUUID {
                if let value = parseTemperature(from: dataCopy) {
                    temperature  = String(format: "%.1f °C", value)
                    lastUpdated  = Date()
                    if isActiveSource { connectionStatus = "Connected to Arduino" }
                    saveValues()
                } else {
                    temperature = "--"
                    if isActiveSource { connectionStatus = "Sensor error (temperature)" }
                }
            } else if uuid == humidityCharacteristicUUID {
                if let value = parseHumidity(from: dataCopy) {
                    humidity    = String(format: "%.1f %%", value)
                    lastUpdated = Date()
                    if isActiveSource { connectionStatus = "Connected to Arduino" }
                    saveValues()
                } else {
                    humidity = "--"
                    if isActiveSource { connectionStatus = "Sensor error (humidity)" }
                }
            }
        }
    }

    nonisolated func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            while !writeQueue.isEmpty && peripheral.canSendWriteWithoutResponse {
                let data = writeQueue.removeFirst()
                if let characteristic = temperatureCharacteristic {
                    peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
                }
            }
        }
    }
}
