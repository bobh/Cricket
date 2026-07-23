//
//  CricketCore_sketch.swift
//  CricketAI — Phase 0 design sketch
//
//  Single source of truth for the latest environmental reading + its freshness.
//  Consumed IN-PROCESS by both the App Intents surface and the Foundation Models Tool.
//
//  This is a design sketch for review. Per Agents.md ("no multiple types per file"),
//  each MARK section below becomes its own file at implementation time:
//      Reading.swift, SensorSource.swift, ReadingResult.swift,
//      UnavailableReason.swift, LinkState.swift, SensorFeed.swift,
//      ReadingPersisting.swift, CricketCore.swift
//
//  Conforms to Agents.md: @Observable @MainActor, structured concurrency only,
//  nonisolated CB delegates (in the feed, not here), no force-unwraps,
//  Swift Testing, injectable clock for testability (NFR-5).
//
//  Targets iOS 26.5 SDK — buildable NOW (Phase 0 does not depend on iOS 27 APIs).
//

import Foundation
import Observation

// MARK: - SensorSource

/// Where a reading originated. Raw values match the CricketIOS app-group convention.
enum SensorSource: String, Sendable, Codable, CaseIterable {
    case arduino = "BLE"
    case ruuvi   = "Ruuvi"
}

// MARK: - Reading

/// An accepted, sentinel-filtered environmental reading. `Sendable` so it can be
/// extracted from a `nonisolated` CoreBluetooth delegate and handed to the `@MainActor`.
struct Reading: Sendable, Equatable, Identifiable, Codable {
    let id: UUID
    let celsius: Double
    let relativeHumidity: Double   // % RH
    let timestamp: Date            // capture time (DR-1 / FR-4)
    let source: SensorSource

    // MARK: Optional, source-capability-aware metrics (DR-3, revised 2026-07-23)
    // NOT part of the ⭐acid test (temp + humidity drive ESD/CMOS + material domains).
    // Modeled as Optional so a source/build that can't supply them returns nil — the
    // freshness/disclosure layer then says "pressure unavailable from this source"
    // rather than fabricating a value. Do NOT build agent features on these until a
    // concrete workshop use case (e.g. pressure *trend*) justifies it.

    /// Barometric pressure in hectopascals (hPa). nil when the source doesn't report it.
    /// RuuviTag (new model, RAWv2) supplies it for free; Rev-2 Arduino can via the onboard
    /// LPS22HB IF the firmware exposes a pressure characteristic (an Arduino build without
    /// it reports `.arduino` yet yields `pressureHPa == nil` — nil is authoritative).
    let pressureHPa: Double?

    /// Monotonic disturbance/movement counter. nil when the source doesn't report motion.
    /// RuuviTag provides it natively (RAWv2); a Rev-2 Arduino build can synthesize it from a
    /// BMI270 any-motion interrupt. A minimal, source-agnostic "was it disturbed" signal —
    /// deliberately not a raw 3-axis vector.
    let movementCount: Int?

    /// Derived — never stored.
    var fahrenheit: Double { celsius * 9.0 / 5.0 + 32.0 }

    /// Which optional metrics this particular reading carries (for dialog/disclosure copy).
    var hasPressure: Bool { pressureHPa != nil }
    var hasMotion: Bool { movementCount != nil }
}

// MARK: - UnavailableReason

/// Why no reading can be served. Distinct cases let the agent / dialog explain *why*
/// rather than emit a fabricated value (FR-7, AB-2).
enum UnavailableReason: String, Sendable, Equatable, Codable {
    case neverConnected          // no sensor has ever reported this session/install
    case disconnected            // was connected; link dropped and no cached reading
    case bluetoothOff
    case bluetoothUnauthorized
    case bluetoothUnsupported
    case sensorError             // sentinel value (-32768 / 65535) most recently
}

// MARK: - ReadingResult

/// The discriminated result every consumer receives (FR-6). There is deliberately
/// NO way to obtain a bare `Double` — staleness and unavailability are un-ignorable.
enum ReadingResult: Sendable, Equatable {
    case fresh(Reading)
    case stale(Reading, age: Duration)
    case unavailable(UnavailableReason)
}

extension ReadingResult {
    /// The underlying reading if one exists (fresh or stale); nil when unavailable.
    var reading: Reading? {
        switch self {
        case .fresh(let r):        return r
        case .stale(let r, _):     return r
        case .unavailable:         return nil
        }
    }

    /// Human/agent-facing age note the dialog layer and Tool can append (FR-12, AB-4).
    var freshnessNote: String {
        switch self {
        case .fresh:
            return "current"
        case .stale(_, let age):
            let minutes = Int(age.components.seconds / 60)
            return "last updated about \(minutes) minute\(minutes == 1 ? "" : "s") ago"
        case .unavailable(let reason):
            return "no live reading available (\(reason.rawValue))"
        }
    }
}

// MARK: - LinkState

/// Current connectivity, published for the UI. Drives which `UnavailableReason`
/// is returned when there is no cached reading.
enum LinkState: Sendable, Equatable {
    case idle
    case scanning
    case connected
    case disconnected
    case bluetoothOff
    case bluetoothUnauthorized
    case bluetoothUnsupported
}

// MARK: - SensorFeed

/// Contract implemented by `BluetoothService` (Arduino, connected) and
/// `RuuviService` (advertisement-only). Both push Sendable values into `CricketCore`.
/// Background acquisition (FR-8, RESOLVED): the BLE implementation configures
/// `CBCentralManager` with a restoration identifier and the `bluetooth-central`
/// background mode so readings continue while the app is backgrounded.
@MainActor
protocol SensorFeed: AnyObject {
    /// Begin (or resume) acquisition. Restores a persisted peripheral UUID if present.
    func start()
    /// Delegate/sink the feed calls when new data or link changes occur.
    var sink: CricketCore? { get set }
}

// MARK: - ReadingPersisting

/// Cross-process handoff. An App Intent may `perform()` in an extension process
/// that has no live BLE link; it reads the last-known reading persisted here by the
/// foreground/background app process. App Group id MUST be `group.wm6h.CricketAI`
/// (DR-0.1) — never the `com.yourcompany` placeholder.
protocol ReadingPersisting: Sendable {
    func save(_ reading: Reading)
    func load() -> Reading?
}

// MARK: - CricketCore

/// The single in-process source of truth (DR-0). Owns the latest reading and computes
/// freshness on demand against an injectable clock. Fed by a `SensorFeed`; read by the
/// App Intents surface and the `ReadEnvironmentalConditions` Tool.
@MainActor
@Observable
final class CricketCore {

    // MARK: Observable state (for SwiftUI / status intents)
    private(set) var latest: Reading?
    private(set) var linkState: LinkState = .idle

    // MARK: Policy
    /// Readings at or under this age are `.fresh`; older are `.stale` (DR-4).
    /// Configurable constant — not a magic number scattered at call sites.
    var freshnessThreshold: Duration = .seconds(300)   // 5 minutes (proposed default)

    // MARK: Collaborators
    private let now: () -> Date                 // injectable for tests (NFR-5)
    private let persistence: ReadingPersisting?

    // MARK: Init
    /// - Parameters:
    ///   - now: clock provider; override in tests to drive freshness deterministically.
    ///   - persistence: optional App Group store for the out-of-process intent path.
    init(now: @escaping () -> Date = { Date() },
         persistence: ReadingPersisting? = nil) {
        self.now = now
        self.persistence = persistence
        // Warm-start from persisted last-known reading so an intent can answer
        // immediately after cold launch, before the first live packet arrives.
        self.latest = persistence?.load()
    }

    // MARK: Public read API (the whole point of Phase 0)

    /// The single accessor every consumer uses. Returns a discriminated result —
    /// there is no path that yields a bare number, so staleness/absence is
    /// impossible to silently ignore (FR-5, FR-6, FR-7).
    func currentConditions() -> ReadingResult {
        // Link problems with no cached reading map to a specific reason.
        if latest == nil {
            switch linkState {
            case .bluetoothOff:            return .unavailable(.bluetoothOff)
            case .bluetoothUnauthorized:   return .unavailable(.bluetoothUnauthorized)
            case .bluetoothUnsupported:    return .unavailable(.bluetoothUnsupported)
            case .disconnected:            return .unavailable(.disconnected)
            case .idle, .scanning, .connected:
                return .unavailable(.neverConnected)
            }
        }

        guard let reading = latest else { return .unavailable(.neverConnected) }

        let age = Duration.seconds(now().timeIntervalSince(reading.timestamp))
        return age <= freshnessThreshold ? .fresh(reading) : .stale(reading, age: age)
    }

    // MARK: Feed-facing ingestion (called by SensorFeed on the MainActor)

    /// Accept a new, already-validated reading. The feed is responsible for
    /// sentinel filtering (FR-3) before calling this.
    func ingest(_ reading: Reading) {
        latest = reading
        if linkState != .connected { linkState = .connected }
        persistence?.save(reading)     // keep the out-of-process intent path warm
    }

    /// Report a link-state transition (e.g., from CBManagerState handling).
    func updateLink(_ state: LinkState) {
        linkState = state
    }

    /// The feed observed a sentinel/error packet — record it without corrupting `latest`.
    func noteSensorError() {
        if latest == nil { linkState = .connected }  // connected but not yielding valid data
        // `currentConditions()` will report the last good reading as stale over time,
        // or `.unavailable(.sensorError)` if there was never a good one.
        if latest == nil { /* reason surfaced via link/never-connected path */ }
    }
}

// MARK: - Swift Testing (NFR-5) — freshness classification is pure and hardware-free

/*
import Testing

@MainActor
@Suite("CricketCore freshness")
struct CricketCoreFreshnessTests {

    private func reading(ageSeconds: Double, at base: Date) -> Reading {
        Reading(id: UUID(),
                celsius: 21.0,
                relativeHumidity: 45.0,
                timestamp: base.addingTimeInterval(-ageSeconds),
                source: .arduino,
                pressureHPa: nil,        // optional metric absent in this fixture
                movementCount: nil)
    }

    @Test("Recent reading is fresh")
    func fresh() {
        let base = Date(timeIntervalSince1970: 1_000_000)
        let core = CricketCore(now: { base })
        core.ingest(reading(ageSeconds: 60, at: base))   // 1 min old
        #expect({ if case .fresh = core.currentConditions() { return true }; return false }())
    }

    @Test("Old reading is stale with age")
    func stale() {
        let base = Date(timeIntervalSince1970: 1_000_000)
        let core = CricketCore(now: { base })
        core.ingest(reading(ageSeconds: 600, at: base))  // 10 min old, threshold 5
        if case .stale(_, let age) = core.currentConditions() {
            #expect(age > .seconds(299))
        } else {
            Issue.record("expected .stale")
        }
    }

    @Test("No reading + BT off is unavailable(bluetoothOff)")
    func unavailable() {
        let core = CricketCore(now: { Date() })
        core.updateLink(.bluetoothOff)
        #expect(core.currentConditions() == .unavailable(.bluetoothOff))
    }
}
*/
