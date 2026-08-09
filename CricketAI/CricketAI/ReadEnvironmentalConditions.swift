//
//  ReadEnvironmentalConditions.swift
//  CricketAI
//
//  The sole Foundation Models adapter for current local sensor truth.
//

import Foundation
import FoundationModels
import CricketCore

nonisolated struct ReadEnvironmentalConditions: Tool {
    let name = "readEnvironmentalConditions"
    let description = """
        Reads CricketAI's current local BLE sensor conditions for the user's immediate environment. \
        Use this whenever a request concerns an activity affected by current room temperature, \
        humidity, or pressure, including electronics and ESD handling, soldering, curing, finishing, \
        comfort, storage, plants, or workshop conditions. Values are returned in Celsius, Fahrenheit, \
        relative-humidity percent, and optional hectopascals. Always disclose stale or unavailable \
        readings. This is local sensor data; external weather is not a substitute.
        """

    private let core: CricketCore
    private let tracker: ToolUseTracker

    init(core: CricketCore, tracker: ToolUseTracker) {
        self.core = core
        self.tracker = tracker
    }

    @concurrent
    func call(arguments: EnvironmentalConditionsArguments) async throws -> EnvironmentalConditionsOutput {
        await tracker.markUsed()
        let result = await core.currentConditions()

        switch result {
        case .fresh(let reading):
            return output(
                state: "fresh",
                reading: reading,
                ageSeconds: elapsedSeconds(since: reading.timestamp),
                freshnessNote: result.freshnessNote
            )

        case .stale(let reading, let age):
            return output(
                state: "stale",
                reading: reading,
                ageSeconds: Int(clamping: age.components.seconds),
                freshnessNote: result.freshnessNote
            )

        case .unavailable(let reason):
            return EnvironmentalConditionsOutput(
                state: "unavailable",
                temperatureCelsius: nil,
                temperatureFahrenheit: nil,
                relativeHumidityPercent: nil,
                pressureHPa: nil,
                source: nil,
                timestamp: nil,
                ageSeconds: nil,
                freshnessNote: result.freshnessNote,
                unavailableReason: reason.rawValue
            )
        }
    }

    private func output(
        state: String,
        reading: Reading,
        ageSeconds: Int,
        freshnessNote: String
    ) -> EnvironmentalConditionsOutput {
        EnvironmentalConditionsOutput(
            state: state,
            temperatureCelsius: reading.celsius,
            temperatureFahrenheit: reading.fahrenheit,
            relativeHumidityPercent: reading.relativeHumidity,
            pressureHPa: reading.pressureHPa,
            source: reading.source.rawValue,
            timestamp: reading.timestamp.ISO8601Format(),
            ageSeconds: ageSeconds,
            freshnessNote: freshnessNote,
            unavailableReason: nil
        )
    }

    private func elapsedSeconds(since timestamp: Date) -> Int {
        max(0, Int(Date().timeIntervalSince(timestamp)))
    }
}
