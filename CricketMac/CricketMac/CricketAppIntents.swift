//
//  CricketAppIntents.swift
//  Cricket
//
//  App Intents for Siri and Shortcuts integration
//  Apple Intelligence-optimized with AppEntity and AppEnum implementations
//  Enables natural language queries and complex Shortcuts automation
//

import AppIntents
import Foundation
import AVFoundation

#if os(macOS)
import AppKit
#endif

// MARK: - AppEnum Definitions

enum SensorType: String, AppEnum {
    case arduino = "BLE"
    case ruuviTag = "Ruuvi"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Sensor Type")
    }

    static var caseDisplayRepresentations: [SensorType: DisplayRepresentation] {
        [
            .arduino: DisplayRepresentation(
                title: "Arduino BLE Sensor",
                subtitle: "Custom environmental sensor with temperature and humidity"
            ),
            .ruuviTag: DisplayRepresentation(
                title: "RuuviTag",
                subtitle: "Commercial Bluetooth environmental sensor"
            )
        ]
    }
}

enum TemperatureUnit: String, AppEnum {
    case celsius
    case fahrenheit
    case both

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Temperature Unit")
    }

    static var caseDisplayRepresentations: [TemperatureUnit: DisplayRepresentation] {
        [
            .celsius: "Celsius (°C)",
            .fahrenheit: "Fahrenheit (°F)",
            .both: "Both units"
        ]
    }
}

// MARK: - AppEntity Definitions

struct TemperatureReading: AppEntity {
    var id: UUID
    var celsius: Double
    var fahrenheit: Double
    var timestamp: Date
    var sensorType: SensorType
    var rawValue: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Temperature Reading")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(String(format: "%.1f", celsius))°C",
            subtitle: "\(String(format: "%.0f", fahrenheit))°F from \(sensorType.rawValue)",
            image: DisplayRepresentation.Image(systemName: "thermometer.medium")
        )
    }

    static var defaultQuery = TemperatureReadingQuery()
}

struct TemperatureReadingQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [TemperatureReading] {
        return []
    }

    func suggestedEntities() async throws -> [TemperatureReading] {
        guard let reading = try? await getCurrentTemperatureReading() else {
            return []
        }
        return [reading]
    }
}

struct HumidityReading: AppEntity {
    var id: UUID
    var relativeHumidity: Double
    var timestamp: Date
    var sensorType: SensorType
    var rawValue: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Humidity Reading")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(String(format: "%.1f", relativeHumidity))%",
            subtitle: "Relative humidity from \(sensorType.rawValue)",
            image: DisplayRepresentation.Image(systemName: "humidity.fill")
        )
    }

    static var defaultQuery = HumidityReadingQuery()
}

struct HumidityReadingQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [HumidityReading] {
        return []
    }

    func suggestedEntities() async throws -> [HumidityReading] {
        guard let reading = try? await getCurrentHumidityReading() else {
            return []
        }
        return [reading]
    }
}

struct SensorStatus: AppEntity {
    var id: UUID
    var sensorType: SensorType
    var isConnected: Bool
    var statusMessage: String
    var lastUpdate: Date?

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Sensor Status")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(sensorType.rawValue) Sensor",
            subtitle: LocalizedStringResource(stringLiteral: statusMessage),
            image: DisplayRepresentation.Image(systemName: isConnected ? "sensor.fill" : "sensor")
        )
    }

    static var defaultQuery = SensorStatusQuery()
}

struct SensorStatusQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [SensorStatus] {
        return []
    }

    func suggestedEntities() async throws -> [SensorStatus] {
        guard let status = try? await getCurrentSensorStatus() else {
            return []
        }
        return [status]
    }
}

// MARK: - Helper Functions

@MainActor
func getCurrentTemperatureReading() async throws -> TemperatureReading? {
    let defaults = UserDefaults.standard
    guard let temperatureString = defaults.string(forKey: "currentTemperature"),
          temperatureString != "--",
          let celsiusValue = Double(temperatureString.components(separatedBy: " ").first ?? "") else {
        return nil
    }

    let fahrenheitValue = celsiusValue * 9.0 / 5.0 + 32.0
    let sensorSource = defaults.string(forKey: "sensorSource") ?? "BLE"
    let sensorType: SensorType = sensorSource == "BLE" ? .arduino : .ruuviTag

    return TemperatureReading(
        id: UUID(),
        celsius: celsiusValue,
        fahrenheit: fahrenheitValue,
        timestamp: Date(),
        sensorType: sensorType,
        rawValue: temperatureString
    )
}

@MainActor
func getCurrentHumidityReading() async throws -> HumidityReading? {
    let defaults = UserDefaults.standard
    guard let humidityString = defaults.string(forKey: "currentHumidity"),
          humidityString != "--",
          let humidityValue = Double(humidityString.components(separatedBy: " ").first ?? "") else {
        return nil
    }

    let sensorSource = defaults.string(forKey: "sensorSource") ?? "BLE"
    let sensorType: SensorType = sensorSource == "BLE" ? .arduino : .ruuviTag

    return HumidityReading(
        id: UUID(),
        relativeHumidity: humidityValue,
        timestamp: Date(),
        sensorType: sensorType,
        rawValue: humidityString
    )
}

@MainActor
func getCurrentSensorStatus() async throws -> SensorStatus? {
    let defaults = UserDefaults.standard
    let statusMessage = defaults.string(forKey: "connectionStatus") ?? "Unknown"
    let sensorSource = defaults.string(forKey: "sensorSource") ?? "BLE"
    let sensorType: SensorType = sensorSource == "BLE" ? .arduino : .ruuviTag

    let isConnected = statusMessage.lowercased().contains("connected") ||
                     statusMessage.lowercased().contains("receiving")

    return SensorStatus(
        id: UUID(),
        sensorType: sensorType,
        isConnected: isConnected,
        statusMessage: statusMessage,
        lastUpdate: Date()
    )
}

func playCricketChirp() {
    guard let soundURL = Bundle.main.url(forResource: "cricket", withExtension: "wav") else {
        return
    }

    #if os(macOS)
    // macOS uses NSSound
    if let sound = NSSound(contentsOf: soundURL, byReference: false) {
        sound.play()
        // Removed Thread.sleep to prevent 800ms blocking delay for OpenClaw integration
    }
    #elseif os(iOS)
    // iOS uses AVAudioSession
    do {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try audioSession.setActive(true)

        let player = try AVAudioPlayer(contentsOf: soundURL)
        player.prepareToPlay()
        player.play()

        // Removed Thread.sleep to prevent 800ms blocking delay for OpenClaw integration

        try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    } catch {
        // Silent failure for production
    }
    #endif
}

// MARK: - Enhanced App Intents

struct GetLocalTemperatureIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Local Temperature"

    static var description = IntentDescription(
        "Retrieves the current temperature reading from your Cricket environmental sensor. Supports both Arduino BLE and RuuviTag sensors with automatic unit conversion between Celsius and Fahrenheit.",
        categoryName: "Weather & Environment",
        searchKeywords: ["temperature", "temp", "weather", "environment", "climate", "room temperature", "indoor temperature", "thermometer"]
    )

    static var openAppWhenRun: Bool = true

    @Parameter(title: "Temperature Unit", description: "Choose the temperature unit to display", default: .both)
    var unit: TemperatureUnit

    static var parameterSummary: some ParameterSummary {
        Summary("Get temperature in \(\.$unit)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<TemperatureReading> & ProvidesDialog {
        playCricketChirp()

        guard let reading = try await getCurrentTemperatureReading() else {
            throw AppIntentError.noData("No temperature data available from your sensor. Please ensure your sensor is connected and transmitting data.")
        }

        let message = formatTemperatureMessage(reading: reading, unit: unit)

        return .result(
            value: reading,
            dialog: IntentDialog(stringLiteral: message)
        )
    }

    private func formatTemperatureMessage(reading: TemperatureReading, unit: TemperatureUnit) -> String {
        switch unit {
        case .celsius:
            return "Your local temperature is \(String(format: "%.1f", reading.celsius)) degrees Celsius"
        case .fahrenheit:
            return "Your local temperature is \(String(format: "%.0f", reading.fahrenheit)) degrees Fahrenheit"
        case .both:
            return "Your local temperature is \(String(format: "%.1f", reading.celsius)) degrees Celsius, or \(String(format: "%.0f", reading.fahrenheit)) degrees Fahrenheit"
        }
    }
}

struct GetLocalHumidityIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Local Humidity"

    static var description = IntentDescription(
        "Retrieves the current relative humidity reading from your Cricket environmental sensor. Useful for monitoring indoor air quality, comfort levels, and environmental conditions.",
        categoryName: "Weather & Environment",
        searchKeywords: ["humidity", "moisture", "relative humidity", "air quality", "environment", "indoor humidity", "hygrometer"]
    )

    static var openAppWhenRun: Bool = false

    static var parameterSummary: some ParameterSummary {
        Summary("Get current humidity level")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<HumidityReading> & ProvidesDialog {
        guard let reading = try await getCurrentHumidityReading() else {
            throw AppIntentError.noData("No humidity data available from your sensor. Please ensure your sensor is connected and transmitting data.")
        }

        let comfortLevel = getComfortLevel(humidity: reading.relativeHumidity)
        let message = "Your local humidity is \(String(format: "%.1f", reading.relativeHumidity)) percent\(comfortLevel)"

        return .result(
            value: reading,
            dialog: IntentDialog(stringLiteral: message)
        )
    }

    private func getComfortLevel(humidity: Double) -> String {
        switch humidity {
        case 0..<30:
            return ", which is quite dry"
        case 30..<40:
            return ", which is comfortable but slightly dry"
        case 40..<60:
            return ", which is ideal for comfort"
        case 60..<70:
            return ", which is comfortable but slightly humid"
        case 70...:
            return ", which is quite humid"
        default:
            return ""
        }
    }
}

struct GetWorkshopConditionsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Workshop Conditions"

    static var description = IntentDescription(
        "Retrieves both temperature and humidity readings from your Cricket environmental sensor in a single query. Perfect for workshop monitoring and environmental condition checks.",
        categoryName: "Weather & Environment",
        searchKeywords: ["workshop", "conditions", "temperature", "humidity", "environment", "both", "all sensors"]
    )

    static var openAppWhenRun: Bool = false

    static var parameterSummary: some ParameterSummary {
        Summary("Get temperature and humidity")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        guard let tempReading = try await getCurrentTemperatureReading(),
              let humidityReading = try await getCurrentHumidityReading() else {
            throw AppIntentError.noData("No sensor data available. Please ensure your sensor is connected and transmitting data.")
        }

        let sensorName = tempReading.sensorType == .arduino ? "Arduino" : "RuuviTag"
        let message = "Temperature: \(String(format: "%.1f", tempReading.celsius))°C, Humidity: \(String(format: "%.1f", humidityReading.relativeHumidity))%, Source: \(sensorName)"

        return .result(
            value: message,
            dialog: IntentDialog(stringLiteral: message)
        )
    }
}

struct GetSensorStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Sensor Status"

    static var description = IntentDescription(
        "Checks the connection and operational status of your Cricket environmental sensor. Displays whether the sensor is connected, scanning, or experiencing issues.",
        categoryName: "Device Status",
        searchKeywords: ["sensor", "status", "connection", "connected", "bluetooth", "BLE", "device status"]
    )

    static var openAppWhenRun: Bool = false

    static var parameterSummary: some ParameterSummary {
        Summary("Check sensor connection status")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<SensorStatus> & ProvidesDialog {
        guard let status = try await getCurrentSensorStatus() else {
            throw AppIntentError.noData("Unable to retrieve sensor status information.")
        }

        let sensorName = status.sensorType == .arduino ? "Arduino" : "RuuviTag"
        let message = "Your \(sensorName) sensor is: \(status.statusMessage)"

        return .result(
            value: status,
            dialog: IntentDialog(stringLiteral: message)
        )
    }
}

// MARK: - Error Types

enum AppIntentError: Error, CustomLocalizedStringResourceConvertible {
    case noData(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noData(let message):
            return LocalizedStringResource(stringLiteral: message)
        }
    }
}
