import Foundation
import CoreBluetooth
import Combine
import AppIntents

class BluetoothViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.CricketMac")

    @Published var temperature: String = "--"
    @Published var humidity: String = "--"
    @Published var connectionStatus: String = "Disconnected"
    @Published var lastUpdated: Date? = nil

    var isActiveSource: Bool = false  // Set by ContentView to indicate if this is the active sensor
    
    private var centralManager: CBCentralManager!
    private var discoveredPeripheral: CBPeripheral?

    var isBluetoothReady: Bool {
        guard let manager = centralManager else { return false }
        return manager.state == .poweredOn
    }

    // Custom 128-bit BLE UUIDs (Bluetooth SIG compliant - matching Arduino Demetor_Peripheral_1)
    private let environmentalSensingServiceUUID = CBUUID(string: "5971E8F1-BC4D-4A5F-A6FD-3591131A98C6")
    private let temperatureCharacteristicUUID = CBUUID(string: "78B20AF1-E597-40C1-A69C-304205B7E099")
    private let humidityCharacteristicUUID = CBUUID(string: "0BA15AA1-A805-4205-BC82-AF2E4A9364C5")

    // Stored characteristic references (avoid repeated UUID searches)
    private var temperatureCharacteristic: CBCharacteristic?
    private var humidityCharacteristic: CBCharacteristic?

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
    
    func startScanning() {
        if centralManager.state == .poweredOn {
            connectionStatus = "Scanning for Arduino sensor..."
            centralManager.scanForPeripherals(withServices: [environmentalSensingServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])

            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                guard let self = self else { return }
                if self.discoveredPeripheral == nil {
                    self.connectionStatus = "No Arduino found. Is it powered on?"
                }
            }
        }
    }

    func showResetMessage() {
        DispatchQueue.main.async {
            self.connectionStatus = "Reset Arduino: Press white reset button"
            self.temperature = "--"
            self.humidity = "--"
            self.lastUpdated = nil
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            connectionStatus = "Scanning for Arduino sensor..."
            centralManager.scanForPeripherals(
                withServices: [environmentalSensingServiceUUID],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
            )

        case .poweredOff:
            connectionStatus = "Bluetooth is off - Enable in System Settings"
            temperature = "--"
            humidity = "--"

        case .unauthorized:
            connectionStatus = "Bluetooth access denied - Check Privacy settings"
            temperature = "--"
            humidity = "--"

        case .unsupported:
            connectionStatus = "This Mac doesn't support Bluetooth Low Energy"
            temperature = "--"
            humidity = "--"

        case .resetting:
            connectionStatus = "Bluetooth resetting..."

        case .unknown:
            connectionStatus = "Bluetooth state unknown - waiting..."

        @unknown default:
            connectionStatus = "Unexpected Bluetooth state"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID],
           serviceUUIDs.contains(environmentalSensingServiceUUID) {
            centralManager.stopScan()
            discoveredPeripheral = peripheral
            discoveredPeripheral?.delegate = self
            centralManager.connect(peripheral, options: nil)
            connectionStatus = "Connecting to Arduino..."
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionStatus = "Connected to Arduino"
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionStatus = "Disconnected"
        centralManager.scanForPeripherals(
            withServices: [environmentalSensingServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionStatus = "Connection failed"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.startScanning()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            return
        }

        guard let services = peripheral.services else {
            return
        }

        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            return
        }

        guard let characteristics = service.characteristics else {
            return
        }

        for characteristic in characteristics {
            if characteristic.uuid == temperatureCharacteristicUUID {
                temperatureCharacteristic = characteristic  // Store reference
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)
            } else if characteristic.uuid == humidityCharacteristicUUID {
                humidityCharacteristic = characteristic  // Store reference
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.connectionStatus = "Update error: \(error.localizedDescription)"
            }
            return
        }

        guard let value = characteristic.value else {
            return
        }

        if characteristic.uuid == temperatureCharacteristicUUID {
            if let tempC = parseTemperature(from: value) {
                DispatchQueue.main.async {
                    self.temperature = String(format: "%.1f °C", tempC)
                    self.lastUpdated = Date()
                    // Only update status if this is the active sensor source
                    if self.isActiveSource {
                        self.connectionStatus = "Connected to Arduino"
                    }
                    self.saveValues()
                }
            } else {
                DispatchQueue.main.async {
                    self.temperature = "--"
                    // Only update status if this is the active sensor source
                    if self.isActiveSource {
                        self.connectionStatus = "Sensor error (temperature)"
                    }
                }
            }
        } else if characteristic.uuid == humidityCharacteristicUUID {
            if let relHum = parseHumidity(from: value) {
                DispatchQueue.main.async {
                    self.humidity = String(format: "%.1f %%", relHum)
                    self.lastUpdated = Date()
                    // Only update status if this is the active sensor source
                    if self.isActiveSource {
                        self.connectionStatus = "Connected to Arduino"
                    }
                    self.saveValues()
                }
            } else {
                DispatchQueue.main.async {
                    self.humidity = "--"
                    // Only update status if this is the active sensor source
                    if self.isActiveSource {
                        self.connectionStatus = "Sensor error (humidity)"
                    }
                }
            }
        }
    }

    // Helper to parse Arduino IEEE 754 float32 format (4 bytes, little-endian)
    private func parseTemperature(from data: Data) -> Float? {
        // Temperature: IEEE 754 single-precision (4 bytes), little-endian
        // Example: 23.4°C → 0x41BB3333 → bytes: 33 33 BB 41
        guard data.count == 4 else { return nil }
        let value = data.withUnsafeBytes { $0.load(as: Float.self) }
        guard value.isFinite else { return nil } // Check for NaN or infinity
        return value
    }

    private func parseHumidity(from data: Data) -> Float? {
        // Humidity: IEEE 754 single-precision (4 bytes), little-endian
        // Example: 45.7%RH → 0x4236CCCD → bytes: CD CC 36 42
        guard data.count == 4 else { return nil }
        let value = data.withUnsafeBytes { $0.load(as: Float.self) }
        guard value.isFinite else { return nil } // Check for NaN or infinity
        return value
    }
}
