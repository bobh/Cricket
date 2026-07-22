//
//  ContentView.swift
//  CricketIOS
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    // Sensor source selection
    @AppStorage("sensorSource") private var sensorSource: String = "BLE"

    // View Models - both Arduino BLE and RuuviTag
    @State private var bluetoothViewModel = BluetoothViewModel()
    @State private var ruuviViewModel = RuuviTagViewModel()

    // UI State
    @State private var showSettings = false

    private let sharedDefaults = UserDefaults(suiteName: "group.wm6h.CricketAI")
    @AppStorage("useFahrenheit") private var useFahrenheit: Bool = false

    // Helper function to switch sensor sources
    private func changeSensorSource(_ newSource: String) {
        sensorSource = newSource
        bluetoothViewModel.isActiveSource = (newSource == "BLE")
        ruuviViewModel.isActiveSource = (newSource == "Ruuvi")
        sharedDefaults?.set(newSource, forKey: "sensorSource")
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
                            .foregroundStyle(DesignColor.brandBlue)

                        Text("Cricket")
                            .font(.largeTitle)
                            .bold()

                        Text("Hyperlocal Monitoring")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                                .foregroundStyle(statusColor)

                            Text(sensorSource == "BLE" ? "Arduino Nano 33 Sense Rev 2" : "RuuviTag")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(lastUpdatedText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(DesignColor.cardBackground)
                    .clipShape(.rect(cornerRadius: 12))
                    .padding(.horizontal)

                    // Main Readings
                    VStack(spacing: 16) {
                        // Temperature Card
                        VStack(spacing: 16) {
                            Image(systemName: "thermometer.medium")
                                .font(.system(size: 50))
                                .foregroundStyle(DesignColor.brandOrange)

                            VStack(alignment: .center, spacing: 4) {
                                Text("Temperature")
                                    .font(DesignFont.label())
                                    .foregroundStyle(.secondary)

                                VStack(alignment: .center, spacing: 8) {
                                    Text(useFahrenheit
                                         ? (currentTemperatureFahrenheit == "--" ? "--" : "\(currentTemperatureFahrenheit) °F")
                                         : currentTemperature)
                                        .font(DesignFont.readingXL())
                                        .foregroundStyle(.primary)

                                    Text(useFahrenheit ? currentTemperature
                                         : (currentTemperatureFahrenheit == "--" ? "--" : "\(currentTemperatureFahrenheit) °F"))
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                        .background(DesignColor.cardBackground)
                        .clipShape(.rect(cornerRadius: 16))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Temperature")
                        .accessibilityValue("\(currentTemperature), \(currentTemperatureFahrenheit) degrees Fahrenheit")

                        // Humidity Card
                        VStack(spacing: 16) {
                            Image(systemName: "humidity.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(DesignColor.brandBlue)

                            VStack(alignment: .center, spacing: 4) {
                                Text("Humidity")
                                    .font(DesignFont.label())
                                    .foregroundStyle(.secondary)

                                Text(currentHumidity)
                                    .font(DesignFont.readingXL())
                                    .foregroundStyle(.primary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                        .background(DesignColor.cardBackground)
                        .clipShape(.rect(cornerRadius: 16))
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
                            .foregroundStyle(.secondary)

                        HStack(spacing: 16) {
                            Button(action: { changeSensorSource("BLE") }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "hammer.fill")
                                        .font(.system(size: 30))
                                        .foregroundStyle(sensorSource == "BLE" ? .white : DesignColor.brandBlue)
                                        .padding()
                                        .background(sensorSource == "BLE" ? DesignColor.brandBlue : Color.clear)
                                        .clipShape(.rect(cornerRadius: 12))
                                    Text("Arduino DIY")
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)

                            Button(action: { changeSensorSource("Ruuvi") }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 30))
                                        .foregroundStyle(sensorSource == "Ruuvi" ? .white : DesignColor.brandGreen)
                                        .padding()
                                        .background(sensorSource == "Ruuvi" ? DesignColor.brandGreen : Color.clear)
                                        .clipShape(.rect(cornerRadius: 12))
                                    Text("RuuviTag")
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        useFahrenheit.toggle()
                        sharedDefaults?.set(useFahrenheit, forKey: "useFahrenheit")
                        WidgetCenter.shared.reloadAllTimelines()
                    } label: {
                        Text(useFahrenheit ? "°C" : "°F")
                            .font(.headline)
                    }
                }
            }
            .onAppear {
                bluetoothViewModel.isActiveSource = (sensorSource == "BLE")
                ruuviViewModel.isActiveSource = (sensorSource == "Ruuvi")
                sharedDefaults?.set(sensorSource, forKey: "sensorSource")
                sharedDefaults?.set(useFahrenheit, forKey: "useFahrenheit")

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
                .foregroundStyle(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .bold()

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(DesignColor.cardBackground)
        .clipShape(.rect(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
}
