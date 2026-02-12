//
//  CricketWidget.swift
//  CricketWidget
//
//  Widget Extension for Cricket Environmental Sensor
//  Displays temperature and humidity on iOS home screen
//

import WidgetKit
import SwiftUI

// MARK: - Widget Timeline Entry

struct CricketEntry: TimelineEntry {
    let date: Date
    let temperature: String
    let humidity: String
    let sensorSource: String
    let connectionStatus: String
}

// MARK: - Timeline Provider

struct CricketProvider: TimelineProvider {
    private let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.CricketIOS")

    func placeholder(in context: Context) -> CricketEntry {
        CricketEntry(
            date: Date(),
            temperature: "20.5 °C",
            humidity: "45.0 %",
            sensorSource: "RuuviTag",
            connectionStatus: "Connected"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CricketEntry) -> Void) {
        let entry = getCurrentEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CricketEntry>) -> Void) {
        let currentEntry = getCurrentEntry()

        // Update every 5 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdate))

        completion(timeline)
    }

    private func getCurrentEntry() -> CricketEntry {
        let temperature = sharedDefaults?.string(forKey: "temperature") ?? "--"
        let humidity = sharedDefaults?.string(forKey: "humidity") ?? "--"
        let sensorSource = sharedDefaults?.string(forKey: "sensorSource") ?? "BLE"
        let status = sharedDefaults?.string(forKey: "connectionStatus") ?? "Unknown"

        let sensorName = sensorSource == "BLE" ? "Arduino" : "RuuviTag"

        return CricketEntry(
            date: Date(),
            temperature: temperature,
            humidity: humidity,
            sensorSource: sensorName,
            connectionStatus: status
        )
    }
}

// MARK: - Widget Views

struct CricketWidgetEntryView: View {
    var entry: CricketProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (Single Metric)

struct SmallWidgetView: View {
    let entry: CricketEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.15, blue: 0.2), Color(red: 0.2, green: 0.25, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                // Cricket icon
                Image(systemName: "sensor.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)

                // Temperature (primary metric for small widget)
                Text(entry.temperature)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Sensor name
                Text(entry.sensorSource)
                    .font(.caption2)
                    .foregroundColor(.green.opacity(0.8))
                    .textCase(.uppercase)
                    .tracking(1)
            }
            .padding()
        }
    }
}

// MARK: - Medium Widget (Both Metrics)

struct MediumWidgetView: View {
    let entry: CricketEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.15, blue: 0.2), Color(red: 0.2, green: 0.25, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 0) {
                // Temperature side
                VStack(spacing: 8) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)

                    Text(entry.temperature)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Temperature")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 1)
                    .padding(.vertical, 16)

                // Humidity side
                VStack(spacing: 8) {
                    Image(systemName: "humidity.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)

                    Text(entry.humidity)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Humidity")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
            }
            .padding()

            // Sensor badge
            VStack {
                HStack {
                    Spacer()
                    Text(entry.sensorSource)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
                Spacer()
            }
            .padding(8)
        }
    }
}

// MARK: - Large Widget (Full Details)

struct LargeWidgetView: View {
    let entry: CricketEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.15, blue: 0.2), Color(red: 0.2, green: 0.25, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "sensor.fill")
                        .font(.title2)
                        .foregroundColor(.green)

                    Text("Cricket Sensor")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Spacer()
                }

                Divider()
                    .background(Color.white.opacity(0.3))

                // Temperature card
                HStack {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                        .frame(width: 60)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Temperature")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        Text(entry.temperature)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

                // Humidity card
                HStack {
                    Image(systemName: "humidity.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .frame(width: 60)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Humidity")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        Text(entry.humidity)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)

                Spacer()

                // Footer
                HStack {
                    Text(entry.sensorSource)
                        .font(.caption.bold())
                        .foregroundColor(.green)

                    Spacer()

                    Text(entry.date, style: .time)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding()
        }
    }
}

// MARK: - Widget Configuration

struct CricketWidget: Widget {
    let kind: String = "CricketWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CricketProvider()) { entry in
            CricketWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Cricket Sensor")
        .description("View temperature and humidity from your environmental sensor")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

struct CricketWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CricketWidgetEntryView(entry: CricketEntry(
                date: Date(),
                temperature: "22.3 °C",
                humidity: "48.5 %",
                sensorSource: "RuuviTag",
                connectionStatus: "Connected"
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small")

            CricketWidgetEntryView(entry: CricketEntry(
                date: Date(),
                temperature: "22.3 °C",
                humidity: "48.5 %",
                sensorSource: "RuuviTag",
                connectionStatus: "Connected"
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium")

            CricketWidgetEntryView(entry: CricketEntry(
                date: Date(),
                temperature: "22.3 °C",
                humidity: "48.5 %",
                sensorSource: "RuuviTag",
                connectionStatus: "Connected"
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large")
        }
    }
}

// MARK: - Widget Bundle (if you add more widgets in the future)

@main
struct CricketWidgetBundle: WidgetBundle {
    var body: some Widget {
        CricketWidget()
    }
}
