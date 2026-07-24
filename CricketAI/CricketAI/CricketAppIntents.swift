//
//  CricketAppIntents.swift
//  CricketAI
//
//  App Intents for Siri and Shortcuts. Readings come from CricketCore (the single source
//  of truth) via the shared App Group last-known store, so an intent invoked out-of-process
//  still answers with the most recent reading AND discloses its freshness (never a bare,
//  undisclosed value). No more direct UserDefaults string parsing.
//

import AppIntents
import Foundation
import AVFoundation
import CricketCore

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

// MARK: - CricketCore access (shared last-known reading, freshness-aware)

/// A transient CricketCore over the shared App Group store. Warm-starts from the
/// last-known reading the live app persisted, and classifies it fresh/stale/unavailable
/// against the current time — the correct out-of-process read path (DR-0 / FR-6).
@MainActor
private func currentConditions() -> ReadingResult {
    CricketCore(persistence: AppGroupReadingStore()).currentConditions()
}

private func appIntentSensorType(_ source: SensorSource) -> SensorType {
    source == .arduino ? .arduino : .ruuviTag
}

/// Human-facing explanation when no reading can be served.
private func unavailableMessage(_ result: ReadingResult) -> String {
    guard case .unavailable(let reason) = result else { return "No sensor data available." }
    switch reason {
    case .neverConnected:        return "CricketAI hasn't received a reading from a sensor yet."
    case .disconnected:          return "The sensor is disconnected."
    case .bluetoothOff:          return "Bluetooth is off. Turn it on in Settings to reach the sensor."
    case .bluetoothUnauthorized: return "CricketAI isn't allowed to use Bluetooth. Check Privacy settings."
    case .bluetoothUnsupported:  return "This device doesn't support Bluetooth Low Energy."
    case .sensorError:           return "The sensor reported an error."
    }
}

/// Freshness qualifier appended to a spoken reading (AB-4). Empty when the reading is live.
private func freshnessSuffix(_ result: ReadingResult) -> String {
    if case .stale = result { return ", though that reading was \(result.freshnessNote)" }
    return ""
}

// MARK: - Helper Functions (entity builders for query suggestions)

@MainActor
func getCurrentTemperatureReading() async throws -> TemperatureReading? {
    guard let reading = currentConditions().reading else { return nil }
    return TemperatureReading(
        id: reading.id,
        celsius: reading.celsius,
        fahrenheit: reading.fahrenheit,
        timestamp: reading.timestamp,
        sensorType: appIntentSensorType(reading.source),
        rawValue: String(format: "%.1f °C", reading.celsius)
    )
}

@MainActor
func getCurrentHumidityReading() async throws -> HumidityReading? {
    guard let reading = currentConditions().reading else { return nil }
    return HumidityReading(
        id: reading.id,
        relativeHumidity: reading.relativeHumidity,
        timestamp: reading.timestamp,
        sensorType: appIntentSensorType(reading.source),
        rawValue: String(format: "%.1f %%", reading.relativeHumidity)
    )
}

@MainActor
func getCurrentSensorStatus() async throws -> SensorStatus? {
    let result = currentConditions()
    switch result {
    case .fresh(let reading):
        return SensorStatus(id: UUID(), sensorType: appIntentSensorType(reading.source),
                            isConnected: true, statusMessage: "Connected — live reading",
                            lastUpdate: reading.timestamp)
    case .stale(let reading, _):
        return SensorStatus(id: UUID(), sensorType: appIntentSensorType(reading.source),
                            isConnected: true, statusMessage: "Stale — \(result.freshnessNote)",
                            lastUpdate: reading.timestamp)
    case .unavailable:
        return SensorStatus(id: UUID(), sensorType: .arduino,
                            isConnected: false, statusMessage: unavailableMessage(result),
                            lastUpdate: nil)
    }
}

func playCricketChirp() {
    guard let soundURL = Bundle.main.url(forResource: "cricket", withExtension: "wav") else {
        return
    }

    #if os(macOS)
    if let sound = NSSound(contentsOf: soundURL, byReference: false) {
        sound.play()
    }
    #elseif os(iOS)
    do {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try audioSession.setActive(true)

        let player = try AVAudioPlayer(contentsOf: soundURL)
        player.prepareToPlay()
        player.play()

        try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    } catch {
        // Silent failure for production
    }
    #endif
}

// MARK: - App Intents

struct GetLocalTemperatureIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Local Temperature"

    static var description = IntentDescription(
        "Retrieves the current temperature from your Cricket environmental sensor in the room. Discloses how recent the reading is.",
        categoryName: "Weather & Environment",
        searchKeywords: ["temperature", "temp", "environment", "climate", "room temperature", "indoor temperature", "thermometer"]
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

        let result = currentConditions()
        guard let reading = result.reading else {
            throw AppIntentError.noData(unavailableMessage(result))
        }

        let entity = TemperatureReading(
            id: reading.id, celsius: reading.celsius, fahrenheit: reading.fahrenheit,
            timestamp: reading.timestamp, sensorType: appIntentSensorType(reading.source),
            rawValue: String(format: "%.1f °C", reading.celsius)
        )
        let message = formatTemperatureMessage(reading: entity, unit: unit) + freshnessSuffix(result)

        return .result(value: entity, dialog: IntentDialog(stringLiteral: message))
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
        "Retrieves the current relative humidity from your Cricket environmental sensor in the room. Discloses how recent the reading is.",
        categoryName: "Weather & Environment",
        searchKeywords: ["humidity", "moisture", "relative humidity", "air quality", "environment", "indoor humidity", "hygrometer"]
    )

    static var openAppWhenRun: Bool = false

    static var parameterSummary: some ParameterSummary {
        Summary("Get current humidity level")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<HumidityReading> & ProvidesDialog {
        let result = currentConditions()
        guard let reading = result.reading else {
            throw AppIntentError.noData(unavailableMessage(result))
        }

        let entity = HumidityReading(
            id: reading.id, relativeHumidity: reading.relativeHumidity,
            timestamp: reading.timestamp, sensorType: appIntentSensorType(reading.source),
            rawValue: String(format: "%.1f %%", reading.relativeHumidity)
        )
        let comfortLevel = getComfortLevel(humidity: reading.relativeHumidity)
        let message = "Your local humidity is \(String(format: "%.1f", reading.relativeHumidity)) percent\(comfortLevel)" + freshnessSuffix(result)

        return .result(value: entity, dialog: IntentDialog(stringLiteral: message))
    }

    private func getComfortLevel(humidity: Double) -> String {
        switch humidity {
        case 0..<30:  return ", which is quite dry"
        case 30..<40: return ", which is comfortable but slightly dry"
        case 40..<60: return ", which is ideal for comfort"
        case 60..<70: return ", which is comfortable but slightly humid"
        case 70...:   return ", which is quite humid"
        default:      return ""
        }
    }
}

struct GetWorkshopConditionsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Workshop Conditions"

    static var description = IntentDescription(
        "Retrieves both temperature and humidity from your Cricket environmental sensor in the room, and discloses how recent the reading is.",
        categoryName: "Weather & Environment",
        searchKeywords: ["workshop", "conditions", "temperature", "humidity", "environment", "both"]
    )

    static var openAppWhenRun: Bool = false

    static var parameterSummary: some ParameterSummary {
        Summary("Get temperature and humidity")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let result = currentConditions()
        guard let reading = result.reading else {
            throw AppIntentError.noData(unavailableMessage(result))
        }

        let sensorName = reading.source == .arduino ? "Arduino" : "RuuviTag"
        let message = "Temperature: \(String(format: "%.1f", reading.celsius))°C, Humidity: \(String(format: "%.1f", reading.relativeHumidity))%, Source: \(sensorName)" + freshnessSuffix(result)

        return .result(value: message, dialog: IntentDialog(stringLiteral: message))
    }
}

struct GetSensorStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Sensor Status"

    static var description = IntentDescription(
        "Checks the connection and freshness status of your Cricket environmental sensor.",
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

        let message = status.isConnected
            ? "\(status.sensorType.rawValue == "BLE" ? "Arduino" : "RuuviTag") sensor: \(status.statusMessage)"
            : status.statusMessage

        return .result(value: status, dialog: IntentDialog(stringLiteral: message))
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
