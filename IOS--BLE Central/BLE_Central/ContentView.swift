//
//  ContentView.swift
//  BLE_Central - Cricket
//
//  iOS version with improvements ported from macOS
//

import SwiftUI
import Combine

struct ContentView: View {
    // Sensor source selection
    @AppStorage("sensorSource") private var sensorSource: String = "BLE"

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

    var currentTemperature: String {
        sensorSource == "BLE" ? bluetoothViewModel.temperature : ruuviViewModel.temperature
    }

    var currentTemperatureFahrenheit: String {
        let tempString = currentTemperature
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "thermometer.medium")
                            .font(.system(size: 40))
                            .foregroundColor(DesignColor.brandBlue)

                        Text("Cricket")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Hyperlocal Monitoring")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

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
                    .padding(.horizontal)

                    // Main Readings
                    VStack(spacing: 16) {
                        // Temperature Card
                        VStack(spacing: 16) {
                            Image(systemName: "thermometer.medium")
                                .font(.system(size: 50))
                                .foregroundColor(DesignColor.brandOrange)

                            VStack(alignment: .center, spacing: 4) {
                                Text("Temperature")
                                    .font(DesignFont.label())
                                    .foregroundColor(.secondary)

                                VStack(alignment: .center, spacing: 8) {
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

                            VStack(alignment: .center, spacing: 4) {
                                Text("Humidity")
                                    .font(DesignFont.label())
                                    .foregroundColor(.secondary)

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
                    .padding(.horizontal)

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
                            title: sensorSource == "BLE" ? "DIY Built" : "Commercial Sensor",
                            description: sensorSource == "BLE" ? "You built this sensor yourself using Arduino Nano 33 Sense Rev 2." : "High-quality RuuviTag environmental sensor.",
                            color: DesignColor.brandOrange
                        )
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 20)

                    // Sensor Switcher
                    VStack(spacing: 12) {
                        Text("Sensor Source")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 16) {
                            Button(action: { changeSensorSource("BLE") }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "hammer.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(sensorSource == "BLE" ? .white : DesignColor.brandBlue)
                                        .padding()
                                        .background(sensorSource == "BLE" ? DesignColor.brandBlue : Color.clear)
                                        .cornerRadius(12)
                                    Text("Arduino DIY")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(.plain)

                            Button(action: { changeSensorSource("Ruuvi") }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 30))
                                        .foregroundColor(sensorSource == "Ruuvi" ? .white : DesignColor.brandGreen)
                                        .padding()
                                        .background(sensorSource == "Ruuvi" ? DesignColor.brandGreen : Color.clear)
                                        .cornerRadius(12)
                                    Text("RuuviTag")
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Set initial active source
                bluetoothViewModel.isActiveSource = (sensorSource == "BLE")
                ruuviViewModel.isActiveSource = (sensorSource == "Ruuvi")

                if sensorSource == "BLE" {
                    bluetoothViewModel.startScanning()
                }
            }
            .onChange(of: sensorSource) { oldValue, newValue in
                if oldValue == "Ruuvi" && newValue == "BLE" {
                    bluetoothViewModel.showResetMessage()
                }
                if newValue == "BLE" {
                    bluetoothViewModel.startScanning()
                }
            }
        }
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
