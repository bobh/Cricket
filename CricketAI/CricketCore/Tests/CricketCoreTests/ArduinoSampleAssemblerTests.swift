//
//  ArduinoSampleAssemblerTests.swift
//  CricketCoreTests
//
//  Combining separately-arriving temperature and humidity into a SensorSample.
//

import Testing
@testable import CricketCore

@Suite("Arduino sample assembler")
struct ArduinoSampleAssemblerTests {

    @Test("Temperature alone does not complete a sample")
    func temperatureAloneIncomplete() {
        var a = ArduinoSampleAssembler()
        #expect(a.updating(temperatureCelsius: 21.0) == nil)
    }

    @Test("Humidity alone does not complete a sample")
    func humidityAloneIncomplete() {
        var a = ArduinoSampleAssembler()
        #expect(a.updating(relativeHumidity: 45.0) == nil)
    }

    @Test("Both fields complete a sample")
    func bothCompletes() {
        var a = ArduinoSampleAssembler()
        _ = a.updating(temperatureCelsius: 21.0)
        let sample = a.updating(relativeHumidity: 45.0)
        #expect(sample == SensorSample(celsius: 21.0, relativeHumidity: 45.0))
    }

    @Test("A new temperature after both known emits an updated sample")
    func updateAfterComplete() {
        var a = ArduinoSampleAssembler()
        _ = a.updating(temperatureCelsius: 21.0)
        _ = a.updating(relativeHumidity: 45.0)
        let sample = a.updating(temperatureCelsius: 22.5)
        #expect(sample == SensorSample(celsius: 22.5, relativeHumidity: 45.0))
    }

    @Test("Exact (0,0) boot placeholder is dropped")
    func bootPlaceholderDropped() {
        var a = ArduinoSampleAssembler()
        _ = a.updating(temperatureCelsius: 0.0)
        #expect(a.updating(relativeHumidity: 0.0) == nil)
    }

    @Test("A real 0.0 °C with non-zero humidity is kept")
    func realZeroCelsiusKept() {
        var a = ArduinoSampleAssembler()
        _ = a.updating(temperatureCelsius: 0.0)
        let sample = a.updating(relativeHumidity: 40.0)
        #expect(sample == SensorSample(celsius: 0.0, relativeHumidity: 40.0))
    }
}
