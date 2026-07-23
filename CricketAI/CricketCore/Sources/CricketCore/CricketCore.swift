//
//  CricketCore.swift
//  CricketCore
//
//  The single in-process source of truth (DR-0). Owns the latest reading and computes
//  freshness on demand against an injectable clock. Fed by a SensorFeed; read by the
//  App Intents surface and the ReadEnvironmentalConditions Tool.
//

import Foundation
import Observation

/// The single in-process authority for the current environmental reading (DR-0).
///
/// There is deliberately no accessor that yields a bare number: every read returns a
/// `ReadingResult`, so staleness and absence are impossible to silently ignore
/// (FR-5, FR-6, FR-7). An `@Observable @MainActor` type per SDD §5.2.
@MainActor
@Observable
public final class CricketCore {

    // MARK: Observable state (for SwiftUI / status intents)
    public private(set) var latest: Reading?
    public private(set) var linkState: LinkState = .idle

    // MARK: Policy
    /// Readings at or under this age are `.fresh`; older are `.stale` (DR-4).
    /// Configurable constant — not a magic number scattered at call sites.
    public var freshnessThreshold: Duration = .seconds(300)   // 5 minutes (DR-4 default)

    // MARK: Collaborators
    private let now: () -> Date                 // injectable for tests (NFR-5)
    private let persistence: ReadingPersisting?

    /// True when the most recent packet was a sentinel/error and no good reading exists.
    /// Lets `currentConditions()` surface `.unavailable(.sensorError)` instead of a
    /// generic reason (FR-7, AB-2). Cleared whenever a valid reading is ingested.
    private var lastWasSensorError = false

    // MARK: Init
    /// - Parameters:
    ///   - now: clock provider; override in tests to drive freshness deterministically.
    ///   - persistence: optional App Group store for the out-of-process intent path.
    public init(now: @escaping () -> Date = { Date() },
                persistence: ReadingPersisting? = nil) {
        self.now = now
        self.persistence = persistence
        // Warm-start from the persisted last-known reading so an intent can answer
        // immediately after cold launch, before the first live packet arrives.
        self.latest = persistence?.load()
    }

    // MARK: Public read API (the whole point of Phase 0)

    /// The single accessor every consumer uses. Returns a discriminated result —
    /// there is no path that yields a bare number, so staleness/absence is impossible
    /// to silently ignore (FR-5, FR-6, FR-7).
    public func currentConditions() -> ReadingResult {
        guard let reading = latest else {
            // No good reading exists. Pick the most specific reason available.
            if lastWasSensorError { return .unavailable(.sensorError) }
            switch linkState {
            case .bluetoothOff:            return .unavailable(.bluetoothOff)
            case .bluetoothUnauthorized:   return .unavailable(.bluetoothUnauthorized)
            case .bluetoothUnsupported:    return .unavailable(.bluetoothUnsupported)
            case .disconnected:            return .unavailable(.disconnected)
            case .idle, .scanning, .connected:
                return .unavailable(.neverConnected)
            }
        }

        let age = Duration.seconds(now().timeIntervalSince(reading.timestamp))
        return age <= freshnessThreshold ? .fresh(reading) : .stale(reading, age: age)
    }

    // MARK: Feed-facing ingestion (called by a SensorFeed on the main actor)

    /// Accept a new, already-validated reading. The feed is responsible for sentinel
    /// filtering (FR-3) before calling this.
    ///
    /// When multiple sources are live, a source-priority rule applies (prefer RuuviTag;
    /// fall back to Arduino only when the current higher-priority reading has gone stale).
    /// A reading always marks the link connected even if it loses arbitration.
    public func ingest(_ reading: Reading) {
        lastWasSensorError = false
        if linkState != .connected { linkState = .connected }
        guard shouldReplaceLatest(with: reading) else { return }
        latest = reading
        persistence?.save(reading)     // keep the out-of-process intent path warm
    }

    /// Source-arbitration policy (see `SensorSource.priority`).
    private func shouldReplaceLatest(with incoming: Reading) -> Bool {
        guard let current = latest else { return true }
        // Same or higher priority always wins (Ruuvi > Arduino; same source = update).
        if incoming.source.priority >= current.source.priority { return true }
        // Lower-priority source (Arduino under a live Ruuvi): accept only as a fallback,
        // once the current higher-priority reading is stale.
        let currentAge = Duration.seconds(now().timeIntervalSince(current.timestamp))
        return currentAge > freshnessThreshold
    }

    /// Report a link-state transition (e.g. from CBManagerState handling).
    public func updateLink(_ state: LinkState) {
        linkState = state
    }

    /// The feed observed a sentinel/error packet — record it without corrupting `latest`.
    /// When there is a prior good reading, that reading is still served (aging into
    /// `.stale`); only when none exists does `.unavailable(.sensorError)` surface.
    public func noteSensorError() {
        lastWasSensorError = true
        if linkState != .connected { linkState = .connected }  // connected, not yielding valid data
    }
}
