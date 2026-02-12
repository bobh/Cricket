//
//  CricketAppIntents.swift
//  Cricket (iOS)
//
//  App Intents for Siri and Shortcuts integration
//  Enables queries like "Hey Siri, Cricket temperature"
//

import AppIntents
import Foundation
import AVFoundation

// MARK: - Get Local Temperature Intent

struct GetLocalTemperatureIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Local Temperature"
    static var description = IntentDescription("Get the current temperature from your Cricket environmental sensor")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        // Play cricket chirp sound
        playCricketChirp()

        let defaults = UserDefaults.standard
        let temperature = defaults.string(forKey: "currentTemperature") ?? "--"
        let sensorSource = defaults.string(forKey: "sensorSource") ?? "BLE"
        let sensorName = sensorSource == "BLE" ? "Arduino" : "RuuviTag"

        NSLog("[Cricket Intent] Temperature: \(temperature), Source: \(sensorSource)")

        if temperature == "--" {
            let message = "No temperature data available from your \(sensorName) sensor"
            NSLog("[Cricket Intent] Returning no data message")
            return .result(
                value: message,
                dialog: IntentDialog(stringLiteral: message)
            )
        }

        // Convert to Fahrenheit
        var fahrenheitString = ""
        if let celsiusValue = Double(temperature.components(separatedBy: " ").first ?? "") {
            let fahrenheit = celsiusValue * 9.0 / 5.0 + 32.0
            fahrenheitString = String(format: ", or %.0f degrees Fahrenheit", fahrenheit)
        }

        let message = "Your local temperature is \(temperature)\(fahrenheitString)"
        NSLog("[Cricket Intent] Returning temperature message: \(message)")
        return .result(
            value: message,
            dialog: IntentDialog(stringLiteral: message)
        )
    }

    private func playCricketChirp() {
        guard let soundURL = Bundle.main.url(forResource: "cricket", withExtension: "wav") else {
            print("[Cricket] Could not find cricket.wav in bundle")
            return
        }

        do {
            // Configure audio session to allow Siri voice after sound
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)

            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.prepareToPlay()
            player.play()

            // Brief delay to allow sound to play
            Thread.sleep(forTimeInterval: 0.8)

            // Deactivate to allow Siri to speak
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("[Cricket] Error playing sound: \(error)")
        }
    }
}

// MARK: - Get Local Humidity Intent

struct GetLocalHumidityIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Local Humidity"
    static var description = IntentDescription("Get the current humidity from your Cricket environmental sensor")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let defaults = UserDefaults.standard
        let humidity = defaults.string(forKey: "currentHumidity") ?? "--"
        let sensorSource = defaults.string(forKey: "sensorSource") ?? "BLE"
        let sensorName = sensorSource == "BLE" ? "Arduino" : "RuuviTag"

        NSLog("[Cricket Intent] Humidity: \(humidity)")

        if humidity == "--" {
            let message = "No humidity data available from your \(sensorName) sensor"
            return .result(
                value: message,
                dialog: IntentDialog(stringLiteral: message)
            )
        }

        let message = "Your local humidity is \(humidity)"
        return .result(
            value: message,
            dialog: IntentDialog(stringLiteral: message)
        )
    }
}

// MARK: - Get Sensor Status Intent

struct GetSensorStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Sensor Status"
    static var description = IntentDescription("Check the connection status of your Cricket environmental sensor")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let defaults = UserDefaults.standard
        let status = defaults.string(forKey: "connectionStatus") ?? "Unknown"
        let sensorSource = defaults.string(forKey: "sensorSource") ?? "BLE"
        let sensorName = sensorSource == "BLE" ? "Arduino" : "RuuviTag"

        NSLog("[Cricket Intent] Status: \(status)")

        let message = "Your \(sensorName) sensor is: \(status)"
        return .result(
            value: message,
            dialog: IntentDialog(stringLiteral: message)
        )
    }
}
