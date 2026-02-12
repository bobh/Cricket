import Foundation
import CoreBluetooth
import Combine
import AppIntents

class RuuviTagViewModel: NSObject, ObservableObject, CBCentralManagerDelegate {
    private let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.CricketMac")

    @Published var temperature: String = "--"
    @Published var humidity: String = "--"
    @Published var connectionStatus: String = "Disconnected"
    @Published var lastUpdated: Date? = nil

    var isActiveSource: Bool = false  // Set by ContentView to indicate if this is the active sensor

    private var centralManager: CBCentralManager!
    private var lastSeen: Date? = nil
    private var freshnessTimer: Timer?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        loadStoredValues()
    }
    
    private func loadStoredValues() {
        temperature = sharedDefaults?.string(forKey: "temperature") ?? "--"
        humidity = sharedDefaults?.string(forKey: "humidity") ?? "--"
    }
    
    private func saveValues() {
        // Only save to UserDefaults if this is the active sensor source
        guard isActiveSource else { return }

        // Save to standard UserDefaults for App Intents access
        UserDefaults.standard.set(temperature, forKey: "currentTemperature")
        UserDefaults.standard.set(humidity, forKey: "currentHumidity")
        UserDefaults.standard.set(connectionStatus, forKey: "connectionStatus")
        UserDefaults.standard.synchronize()

        // Also save to shared defaults for potential widgets
        sharedDefaults?.set(temperature, forKey: "temperature")
        sharedDefaults?.set(humidity, forKey: "humidity")
        sharedDefaults?.synchronize()

        // Donate intents to Apple Intelligence for pattern learning
        donateIntents()
    }

    private func donateIntents() {
        // Donate temperature intent
        Task { @MainActor in
            let tempIntent = GetLocalTemperatureIntent()
            tempIntent.donate()
        }

        // Donate humidity intent
        Task { @MainActor in
            let humIntent = GetLocalHumidityIntent()
            humIntent.donate()
        }

        // Apple Intelligence now learns:
        // - When user checks readings (time patterns)
        // - How often they check (frequency)
        // - Context (location, time of day)
        // - Can proactively suggest checking readings
    }
    
    private func startFreshnessTimer() {
        freshnessTimer?.invalidate()
        freshnessTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let last = self.lastSeen, Date().timeIntervalSince(last) > 10 {
                DispatchQueue.main.async {
                    self.connectionStatus = "No recent data from RuuviTag"
                }
            }
        }
    }

    private func stopFreshnessTimer() {
        freshnessTimer?.invalidate()
        freshnessTimer = nil
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            connectionStatus = "Scanning for RuuviTag..."
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            startFreshnessTimer()
        } else {
            connectionStatus = "Bluetooth not available"
            stopFreshnessTimer()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // RuuviTag manufacturer ID is 0x0499
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data, manufacturerData.count >= 6 {
            // Check for Ruuvi manufacturer ID (0x0499)
            let companyID = manufacturerData.prefix(2)
            if companyID == Data([0x99, 0x04]) {
                parseRuuviRawFormat(manufacturerData)
                DispatchQueue.main.async {
                    self.lastSeen = Date()
                    self.lastUpdated = Date()
                    // Only update status if this is the active sensor source
                    if self.isActiveSource {
                        self.connectionStatus = "Receiving data from RuuviTag"
                    }
                }
            }
        }
    }

    private func parseRuuviRawFormat(_ data: Data) {
        guard data.count >= 6 else {
            return
        }

        let format = data[2]

        var temperatureC: Double = 0
        var humidityPct: Double = 0

        if format == 0x03 {
            // RAWv1: https://docs.ruuvi.com/communication/bluetooth-advertisements/data-format-3-rawv1.html
            guard data.count >= 8 else {
                return
            }
            // Bytes 3-4: temperature (signed short) in 0.01 °C, little-endian
            let tempRaw = Int16(bitPattern: UInt16(data[3]) | (UInt16(data[4]) << 8))
            temperatureC = Double(tempRaw) / 100.0

            // Bytes 5-6: humidity (unsigned short) in 0.01 %, little-endian
            let humRaw = UInt16(data[5]) | (UInt16(data[6]) << 8)
            humidityPct = Double(humRaw) / 100.0

        } else if format == 0x05 {
            // RAWv2: https://docs.ruuvi.com/communication/bluetooth-advertisements/data-format-5-rawv2.html
            guard data.count >= 14 else {
                return
            }
            // Bytes 3-4: temperature (signed short) in 0.005 °C, big-endian
            let tempRaw = Int16(data[3]) << 8 | Int16(data[4])
            temperatureC = Double(tempRaw) * 0.005

            // Bytes 5-6: humidity (unsigned short) in 0.0025 %, big-endian
            let humRaw = UInt16(data[5]) << 8 | UInt16(data[6])
            humidityPct = Double(humRaw) * 0.0025

        } else {
            return
        }

        DispatchQueue.main.async {
            self.temperature = String(format: "%.1f °C", temperatureC)
            self.humidity = String(format: "%.1f %%", humidityPct)
            self.saveValues()
        }
    }
}
