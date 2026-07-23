//
//  ArduinoSampleAssembler.swift
//  CricketCore
//
//  The Arduino sends temperature and humidity as SEPARATE characteristics, so a feed
//  receives them in independent callbacks. This tiny state machine caches the latest of
//  each and produces a SensorSample once both are known — pure and unit-testable, so the
//  CoreBluetooth conformer that uses it stays thin.
//

/// Combines independently-arriving Arduino temperature and humidity into a SensorSample.
public struct ArduinoSampleAssembler: Sendable {
    private var celsius: Double?
    private var relativeHumidity: Double?

    public init() {}

    /// Record a new temperature; returns a sample if both fields are now known.
    public mutating func updating(temperatureCelsius value: Double) -> SensorSample? {
        celsius = value
        return completedSample()
    }

    /// Record a new humidity; returns a sample if both fields are now known.
    public mutating func updating(relativeHumidity value: Double) -> SensorSample? {
        self.relativeHumidity = value
        return completedSample()
    }

    private func completedSample() -> SensorSample? {
        guard let celsius, let relativeHumidity else { return nil }
        // Drop the firmware's boot placeholder: `writeValue(0.0)` is written to both
        // characteristics at startup before the first real reading. 0.0 %RH is physically
        // implausible, so an exact (0.0, 0.0) pair is the placeholder, not real data.
        if celsius == 0.0 && relativeHumidity == 0.0 { return nil }
        return SensorSample(celsius: celsius, relativeHumidity: relativeHumidity)
    }
}
