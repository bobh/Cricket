//
//  CricketMacApp.swift
//  CricketMac
//
//  Created by bobh on 7/27/25.
//

import SwiftUI
import AppIntents

@main
struct CricketMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
}

// Register App Shortcuts with Siri
struct CricketAppShortcutsProvider: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .orange

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetLocalTemperatureIntent(),
            phrases: [
                "\(.applicationName) local temperature",
                "\(.applicationName) temperature",
                "Local temperature in \(.applicationName)",
                "What's my local temperature in \(.applicationName)",
                "Get my temperature from \(.applicationName)"
            ],
            shortTitle: "Local Temperature",
            systemImageName: "thermometer.medium"
        )

        AppShortcut(
            intent: GetLocalHumidityIntent(),
            phrases: [
                "\(.applicationName) local humidity",
                "\(.applicationName) humidity",
                "Local humidity in \(.applicationName)",
                "What's my local humidity in \(.applicationName)",
                "Get my humidity from \(.applicationName)"
            ],
            shortTitle: "Local Humidity",
            systemImageName: "humidity.fill"
        )

        AppShortcut(
            intent: GetSensorStatusIntent(),
            phrases: [
                "\(.applicationName) sensor status",
                "\(.applicationName) sensor",
                "Check my \(.applicationName) sensor",
                "Is my \(.applicationName) sensor connected"
            ],
            shortTitle: "Sensor Status",
            systemImageName: "sensor.fill"
        )
    }
}
