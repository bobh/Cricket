//
//  EnvironmentalConditionsOutput.swift
//  CricketAI
//
//  Structured result returned by ReadEnvironmentalConditions to the model.
//

import FoundationModels

@Generable(description: "A freshness-aware reading from CricketAI's local environmental sensor.")
nonisolated struct EnvironmentalConditionsOutput {
    @Guide(description: "Reading state: fresh, stale, or unavailable.")
    let state: String

    @Guide(description: "Temperature in degrees Celsius, or nil when unavailable.")
    let temperatureCelsius: Double?

    @Guide(description: "Temperature in degrees Fahrenheit, or nil when unavailable.")
    let temperatureFahrenheit: Double?

    @Guide(description: "Relative humidity percentage, or nil when unavailable.")
    let relativeHumidityPercent: Double?

    @Guide(description: "Barometric pressure in hectopascals when supplied by the sensor.")
    let pressureHPa: Double?

    @Guide(description: "The sensor source, or nil when no reading is available.")
    let source: String?

    @Guide(description: "ISO 8601 capture time, or nil when no reading is available.")
    let timestamp: String?

    @Guide(description: "Whole seconds elapsed since capture, or nil when unavailable.")
    let ageSeconds: Int?

    @Guide(description: "Plain-language freshness or unavailability disclosure.")
    let freshnessNote: String

    @Guide(description: "Why no reading is available, otherwise nil.")
    let unavailableReason: String?
}
