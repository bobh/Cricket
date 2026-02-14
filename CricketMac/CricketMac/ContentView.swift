//
//  ContentView.swift
//  Cricket_mac
//
//  Created by bobh on 10/1/25.
//
/*
 Summary of the solution:
 - The Arduino was using the Health Thermometer Service (0x1809) with characteristic 0x2A1C for temperature
 - The Arduino was using the Environmental Sensing Service (0x181A) with characteristic 0x2A6F for humidity
 - Both characteristics send data as IEEE 754 float32 (4 bytes, little-endian)
 - macOS Core Bluetooth handles little-endian conversion automatically with Data.withUnsafeBytes { $0.load(as: Float.self) }
 */
/*
 I've fixed the issue! The problem was that both ViewModels were competing to write to UserDefaults. Now only the active sensor (the one
   selected in the UI) will write to UserDefaults.

   Changes made:

   1. BluetoothViewModel.swift - Added isActiveSource flag, only saves to UserDefaults when active
   2. RuuviTagViewModel.swift - Added isActiveSource flag, only saves to UserDefaults when active
   3. ContentView.swift - Updates the isActiveSource flags when you switch sensors

   To test the fix:

   1. Quit the Cricket app completely (Cmd+Q)
   2. Restart the Cricket app
   3. Click the RuuviTag button (antenna icon) in the sidebar to activate RuuviTag as the data source
   4. Wait ~5 seconds for RuuviTag to send new data
   5. Check the app displays: 19.1°C and 37.8% (or current values)
   6. Run the Shortcuts script immediately to verify it now matches

   The Shortcuts script should now show the exact same temperature and humidity as the app UI displays, because only the active sensor writes
   to UserDefaults.
 */



import SwiftUI
import Combine

struct ContentView: View {
    // Sensor source selection
    @State private var sensorSource: String = "BLE"

    // View Models - both Arduino BLE and RuuviTag
    @StateObject private var bluetoothViewModel = BluetoothViewModel()
    @StateObject private var ruuviViewModel = RuuviTagViewModel()

    // UI State
    @State private var showSettings = false

    // Helper function to switch sensor sources
    private func changeSensorSource(_ newSource: String) {
        sensorSource = newSource
        // Update which ViewModel is active for UserDefaults writes
        bluetoothViewModel.isActiveSource = (newSource == "BLE")
        ruuviViewModel.isActiveSource = (newSource == "Ruuvi")
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // App Header
                VStack(spacing: 8) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 40))
                        .foregroundColor(DesignColor.brandBlue)

                    Text("Cricket")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Hyperlocal Monitoring")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
                .padding(.bottom, 16)

                Divider()

                // Navigation
                List(selection: $showSettings) {
                    Button(action: { showSettings = false }) {
                        Label("Dashboard", systemImage: "gauge")
                    }
                    .tag(false)

                    Button(action: { showSettings = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(true)
                }
                .listStyle(.sidebar)

                Spacer()

                // Quick Sensor Switch
                VStack(spacing: 12) {
                    Divider()

                    Text("Sensor Source")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        Button(action: { changeSensorSource("BLE") }) {
                            Image(systemName: "hammer.fill")
                                .foregroundColor(sensorSource == "BLE" ? .white : DesignColor.brandBlue)
                                .padding(8)
                                .background(sensorSource == "BLE" ? DesignColor.brandBlue : Color.clear)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .help("Arduino DIY")

                        Button(action: { changeSensorSource("Ruuvi") }) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(sensorSource == "Ruuvi" ? .white : DesignColor.brandGreen)
                                .padding(8)
                                .background(sensorSource == "Ruuvi" ? DesignColor.brandGreen : Color.clear)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .help("RuuviTag")
                    }
                }
                .padding()
            }
            .frame(minWidth: 200)
        } detail: {
            // Main Content - Switch between Arduino BLE and RuuviTag
            if showSettings {
                SettingsView(
                    sensorSource: $sensorSource,
                    bluetoothViewModel: bluetoothViewModel
                )
            } else {
                DashboardView(
                    sensorSource: sensorSource,
                    bluetoothViewModel: bluetoothViewModel,
                    ruuviViewModel: ruuviViewModel
                )
            }
        }
        .navigationTitle(showSettings ? "Settings" : "Dashboard")
        .onAppear {
            // Set initial active source
            bluetoothViewModel.isActiveSource = (sensorSource == "BLE")
            ruuviViewModel.isActiveSource = (sensorSource == "Ruuvi")
        }
    }
}

struct DashboardView: View {
    let sensorSource: String
    @ObservedObject var bluetoothViewModel: BluetoothViewModel
    @ObservedObject var ruuviViewModel: RuuviTagViewModel

    var currentTemperature: String {
        sensorSource == "BLE" ? bluetoothViewModel.temperature : ruuviViewModel.temperature
    }

    var currentTemperatureFahrenheit: String {
        let tempString = currentTemperature
        // Extract numeric value from "XX.X °C" format
        guard let celsiusValue = Double(tempString.components(separatedBy: " ").first ?? "") else {
            return "--"
        }
        let fahrenheit = celsiusValue * 9.0 / 5.0 + 32.0
        return String(format: "%.0f", fahrenheit)
    }

    var currentHumidity: String {
        sensorSource == "BLE" ? bluetoothViewModel.humidity : ruuviViewModel.humidity
    }

    var currentStatus: String {
        sensorSource == "BLE" ? bluetoothViewModel.connectionStatus : ruuviViewModel.connectionStatus
    }

    var statusColor: Color {
        if currentStatus.contains("Connected") || currentStatus.contains("Receiving") {
            return DesignColor.statusOK
        } else if currentStatus.contains("Scanning") || currentStatus.contains("Connecting") {
            return DesignColor.statusWarning
        } else {
            return DesignColor.statusError
        }
    }

    var statusLEDMode: LEDMode {
        if currentStatus.contains("Connected") {
            return .on
        } else if currentStatus.contains("Scanning") || currentStatus.contains("Connecting") {
            return .blink
        } else {
            return .off
        }
    }
    
    private var lastUpdatedText: String {
        let date = sensorSource == "BLE" ? bluetoothViewModel.lastUpdated : ruuviViewModel.lastUpdated
        guard let date = date else { return "Last updated: --" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return "Last updated: \(formatter.string(from: date))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Status Header
                HStack(spacing: 12) {
                    LEDView(
                        color: statusColor == DesignColor.statusOK ? .green : (statusColor == DesignColor.statusWarning ? .amber : .red),
                        mode: statusLEDMode,
                        size: 16
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentStatus)
                            .font(.headline)
                            .foregroundColor(statusColor)

                        Text(sensorSource == "BLE" ? "Arduino Nano 33 Sense Rev 2" : "RuuviTag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(lastUpdatedText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(DesignColor.cardBackground)
                .cornerRadius(12)

                // Main Readings
                HStack(alignment: .top, spacing: 24) {
                    // Temperature Card
                    VStack(spacing: 16) {
                        Image(systemName: "thermometer.medium")
                            .font(.system(size: 50))
                            .foregroundColor(DesignColor.brandOrange)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Temperature")
                                .font(DesignFont.label())
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(currentTemperature)
                                    .font(DesignFont.readingXL())
                                    .foregroundColor(.primary)

                                HStack(alignment: .top, spacing: 0) {
                                    Text(currentTemperatureFahrenheit)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.secondary)
                                    Text("°")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .offset(y: 2)
                                    Text("F")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(32)
                    .background(DesignColor.cardBackground)
                    .cornerRadius(16)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Temperature")
                    .accessibilityValue("\(currentTemperature), \(currentTemperatureFahrenheit) degrees Fahrenheit")

                    // Humidity Card
                    VStack(spacing: 16) {
                        Image(systemName: "humidity.fill")
                            .font(.system(size: 50))
                            .foregroundColor(DesignColor.brandBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Humidity")
                                .font(DesignFont.label())
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(currentHumidity)
                                .font(DesignFont.readingXL())
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(32)
                    .background(DesignColor.cardBackground)
                    .cornerRadius(16)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Humidity")
                    .accessibilityValue(currentHumidity)
                }

                // Info Cards
                VStack(spacing: 16) {
                    InfoCard(
                        icon: "info.circle.fill",
                        title: "Hyperlocal Data",
                        description: "These readings are from your immediate environment, not a distant weather station.",
                        color: DesignColor.brandGreen
                    )

                    InfoCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Real-Time Monitoring",
                        description: "Data updates automatically as your sensor transmits new readings.",
                        color: DesignColor.brandBlue
                    )

                    InfoCard(
                        icon: "hammer.fill",
                        title: "DIY Built",
                        description: "You built this sensor yourself using Arduino Nano 33 Sense Rev 2.",
                        color: DesignColor.brandOrange
                    )
                }

                Spacer(minLength: 40)
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(DesignColor.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
