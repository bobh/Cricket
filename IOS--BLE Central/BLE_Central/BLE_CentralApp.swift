//
//  BLE_CentralApp.swift
//  BLE_Central - Cricket
//
//  Created by bobh on 7/9/25.
//

import SwiftUI
import AppIntents

@main
struct BLE_CentralApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Register App Shortcuts with Siri
struct CricketAppShortcutsProvider: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .orange

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetLocalTemperatureIntent(),
            phrases: [
                "Get local temperature with \(.applicationName)",
                "What's my temperature in \(.applicationName)",
                "Check \(.applicationName) temperature",
                "\(.applicationName) temp",
                "Temperature in \(.applicationName)"
            ],
            shortTitle: "Local Temperature",
            systemImageName: "thermometer.medium"
        )

        AppShortcut(
            intent: GetLocalHumidityIntent(),
            phrases: [
                "Get local humidity with \(.applicationName)",
                "What's my humidity in \(.applicationName)",
                "Check \(.applicationName) humidity",
                "\(.applicationName) humidity",
                "Humidity in \(.applicationName)"
            ],
            shortTitle: "Local Humidity",
            systemImageName: "humidity.fill"
        )

        AppShortcut(
            intent: GetSensorStatusIntent(),
            phrases: [
                "Check \(.applicationName) sensor",
                "\(.applicationName) sensor status",
                "Is \(.applicationName) connected",
                "\(.applicationName) status"
            ],
            shortTitle: "Sensor Status",
            systemImageName: "sensor.fill"
        )
    }
}
