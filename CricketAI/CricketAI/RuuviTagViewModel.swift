//
//  RuuviTagViewModel.swift
//  CricketIOS
//

import Foundation
import CoreBluetooth
import AppIntents
import WidgetKit

// MARK: - RuuviTagViewModel

@MainActor
@Observable
final class RuuviTagViewModel: NSObject {

    // MARK: - Observable State

    var temperature: String = "--"
    var humidity: String = "--"
    var connectionStatus: String = "Disconnected"
    var lastUpdated: Date? = nil
    var isActiveSource: Bool = false

    // MARK: - Private State

    private let sharedDefaults = UserDefaults(suiteName: "group.wm6h.CricketAI")
    private var centralManager: CBCentralManager!
    private var lastSeen: Date? = nil

    private var freshnessTask: Task<Void, Never>?

    // MARK: - Init

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        loadStoredValues()
    }

    // MARK: - Stored Values

    private func loadStoredValues() {
        temperature = sharedDefaults?.string(forKey: "temperature") ?? "--"
        humidity    = sharedDefaults?.string(forKey: "humidity")    ?? "--"
    }

    private func saveValues() {
        // Always write RuuviTag-specific keys for calibration logging
        UserDefaults.standard.set(temperature,      forKey: "ruuvi_temperature")
        UserDefaults.standard.set(humidity,         forKey: "ruuvi_humidity")
        UserDefaults.standard.set(connectionStatus, forKey: "ruuvi_status")
        UserDefaults.standard.set(Date(),           forKey: "ruuvi_lastUpdated")

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

    // MARK: - Freshness Monitoring

    /// Polls every 5 seconds; marks stale if no advertisement received within 10 seconds.
    private func startFreshnessTimer() {
        freshnessTask?.cancel()
        freshnessTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled, let self else { return }
                if let last = lastSeen, Date().timeIntervalSince(last) > 10 {
                    connectionStatus = "No recent data from RuuviTag"
                }
            }
        }
    }

    private func stopFreshnessTimer() {
        freshnessTask?.cancel()
        freshnessTask = nil
    }

    // MARK: - Parsing

    /// Pure computation — parses manufacturer data and returns formatted strings, or nil on failure.
    nonisolated private func parseRuuviRawFormat(_ data: Data) -> (temperature: String, humidity: String)? {
        guard data.count >= 6 else { return nil }

        let format = data[2]
        let temperatureC: Double
        let humidityPct: Double

        if format == 0x03 {
            // RAWv1 — docs.ruuvi.com/communication/bluetooth-advertisements/data-format-3-rawv1
            guard data.count >= 8 else { return nil }
            // Bytes 3-4: temperature (signed short) in 0.01 °C, little-endian
            let tempRaw = Int16(bitPattern: UInt16(data[3]) | (UInt16(data[4]) << 8))
            temperatureC = Double(tempRaw) / 100.0
            // Bytes 5-6: humidity (unsigned short) in 0.01 %, little-endian
            let humRaw = UInt16(data[5]) | (UInt16(data[6]) << 8)
            humidityPct = Double(humRaw) / 100.0

        } else if format == 0x05 {
            // RAWv2 — docs.ruuvi.com/communication/bluetooth-advertisements/data-format-5-rawv2
            guard data.count >= 14 else { return nil }
            // Bytes 3-4: temperature (signed short) in 0.005 °C, big-endian
            let tempRaw = Int16(data[3]) << 8 | Int16(data[4])
            temperatureC = Double(tempRaw) * 0.005
            // Bytes 5-6: humidity (unsigned short) in 0.0025 %, big-endian
            let humRaw = UInt16(data[5]) << 8 | UInt16(data[6])
            humidityPct = Double(humRaw) * 0.0025

        } else {
            return nil
        }

        return (
            String(format: "%.1f °C", temperatureC),
            String(format: "%.1f %%", humidityPct)
        )
    }
}

// MARK: - CBCentralManagerDelegate
// All methods are nonisolated — CoreBluetooth calls them from its internal queue.

extension RuuviTagViewModel: CBCentralManagerDelegate {

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        Task { @MainActor [weak self] in
            guard let self else { return }
            if state == .poweredOn {
                connectionStatus = "Scanning for RuuviTag..."
                centralManager.scanForPeripherals(
                    withServices: nil,
                    options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
                )
                startFreshnessTimer()
            } else {
                connectionStatus = "Bluetooth not available"
                stopFreshnessTimer()
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
              manufacturerData.count >= 6,
              manufacturerData.prefix(2) == Data([0x99, 0x04]),
              let parsed = parseRuuviRawFormat(manufacturerData) else { return }

        // parsed is (String, String) — Sendable — safe to cross to @MainActor
        Task { @MainActor [weak self] in
            guard let self else { return }
            lastSeen    = Date()
            lastUpdated = Date()
            temperature = parsed.temperature
            humidity    = parsed.humidity
            if isActiveSource { connectionStatus = "Receiving data from RuuviTag" }
            saveValues()
        }
    }
}
