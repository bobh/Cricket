//
//  ContentView.swift
//  CricketAI
//
//  Observes the single CricketCore source of truth. Source selection is automatic
//  (RuuviTag preferred, Arduino fallback) via CricketCore arbitration — no manual toggle.
//  Freshness is disclosed honestly: fresh / stale-with-age / unavailable-with-reason.
//

import SwiftUI
import CricketCore

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Conditions", systemImage: "thermometer.medium") {
                ConditionsView()
            }

            Tab("Ask Cricket", systemImage: "sparkles") {
                ChatView()
            }
        }
    }
}

struct ConditionsView: View {
    @Environment(CricketRuntime.self) private var runtime
    @AppStorage("useFahrenheit") private var useFahrenheit: Bool = false

    // MARK: - Derived state

    private var result: ReadingResult { runtime.core.currentConditions() }

    private var statusText: String {
        switch result {
        case .fresh:                 return "Live reading"
        case .stale:                 return "Stale reading"
        case .unavailable(let r):    return message(for: r)
        }
    }

    private var freshnessNote: String { result.freshnessNote }

    private var statusLED: (color: LEDColor, mode: LEDMode) {
        switch result {
        case .fresh:        return (.green, .on)
        case .stale:        return (.amber, .blink)
        case .unavailable:  return (.red, .off)
        }
    }

    private var statusColor: Color {
        switch result {
        case .fresh:        return DesignColor.statusOK
        case .stale:        return DesignColor.statusWarning
        case .unavailable:  return DesignColor.statusError
        }
    }

    private var sourceLabel: String {
        switch result.reading?.source {
        case .arduino:  return "Arduino Nano 33 Sense Rev 2"
        case .ruuvi:    return "RuuviTag"
        case nil:       return "No sensor"
        }
    }

    private func message(for reason: UnavailableReason) -> String {
        switch reason {
        case .neverConnected:       return "Waiting for first reading…"
        case .disconnected:         return "Sensor disconnected"
        case .bluetoothOff:         return "Bluetooth is off"
        case .bluetoothUnauthorized:return "Bluetooth access denied"
        case .bluetoothUnsupported: return "Bluetooth LE not supported"
        case .sensorError:          return "Sensor error"
        }
    }

    private func primaryTemp(_ reading: Reading) -> String {
        useFahrenheit ? String(format: "%.0f °F", reading.fahrenheit)
                      : String(format: "%.1f °C", reading.celsius)
    }

    private func secondaryTemp(_ reading: Reading) -> String {
        useFahrenheit ? String(format: "%.1f °C", reading.celsius)
                      : String(format: "%.0f °F", reading.fahrenheit)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    statusCard
                    readings
                    infoCards
                    Spacer(minLength: 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        useFahrenheit.toggle()
                    } label: {
                        Text(useFahrenheit ? "°C" : "°F").font(.headline)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "thermometer.medium")
                .font(.system(size: 40))
                .foregroundStyle(DesignColor.brandBlue)
            Text("Cricket").font(.largeTitle).bold()
            Text("Hyperlocal Monitoring")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top)
    }

    private var statusCard: some View {
        HStack(spacing: 12) {
            LEDView(color: statusLED.color, mode: statusLED.mode, size: 16)
            VStack(alignment: .leading, spacing: 4) {
                Text(statusText).font(.headline).foregroundStyle(statusColor)
                Text(sourceLabel).font(.caption).foregroundStyle(.secondary)
                Text(freshnessNote).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(DesignColor.cardBackground)
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal)
    }

    @ViewBuilder
    private var readings: some View {
        VStack(spacing: 16) {
            // Temperature
            VStack(spacing: 16) {
                Image(systemName: "thermometer.medium")
                    .font(.system(size: 50))
                    .foregroundStyle(DesignColor.brandOrange)
                VStack(spacing: 4) {
                    Text("Temperature")
                        .font(DesignFont.label())
                        .foregroundStyle(.secondary)
                    VStack(spacing: 8) {
                        Text(result.reading.map(primaryTemp) ?? "--")
                            .font(DesignFont.readingXL())
                            .foregroundStyle(.primary)
                        Text(result.reading.map(secondaryTemp) ?? "--")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(32)
            .background(DesignColor.cardBackground)
            .clipShape(.rect(cornerRadius: 16))

            // Humidity
            VStack(spacing: 16) {
                Image(systemName: "humidity.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(DesignColor.brandBlue)
                VStack(spacing: 4) {
                    Text("Humidity")
                        .font(DesignFont.label())
                        .foregroundStyle(.secondary)
                    Text(result.reading.map { String(format: "%.1f %%", $0.relativeHumidity) } ?? "--")
                        .font(DesignFont.readingXL())
                        .foregroundStyle(.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(32)
            .background(DesignColor.cardBackground)
            .clipShape(.rect(cornerRadius: 16))

            // Optional metrics (disclosed only when the source supplies them)
            if let reading = result.reading, reading.hasPressure || reading.hasMotion {
                HStack(spacing: 24) {
                    if let hpa = reading.pressureHPa {
                        Label(String(format: "%.0f hPa", hpa), systemImage: "gauge.with.dots.needle.bottom.50percent")
                    }
                    if let motion = reading.movementCount {
                        Label("\(motion)", systemImage: "move.3d")
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private var infoCards: some View {
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
        }
        .padding(.horizontal)
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
                Text(title).font(.headline).bold()
                Text(description).font(.subheadline).foregroundStyle(.secondary)
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
        .environment(CricketRuntime())
}
