//
//  AppGroupReadingStore.swift
//  CricketCore
//
//  Concrete ReadingPersisting over the shared App Group container. Stores the last-known
//  reading as JSON so an out-of-process App Intent can answer immediately after cold launch.
//
//  App Group id MUST be `group.wm6h.CricketAI` (DR-0.1) — never the `com.yourcompany`
//  placeholder, and no trailing spaces (trailing spaces cause profile mismatch).
//

import Foundation

/// Persists the last-known reading in the shared App Group `UserDefaults`.
///
/// Holds only value-type configuration (the suite name + key) so the store is trivially
/// `Sendable`; the `UserDefaults` handle is resolved per call (cheap and thread-safe).
public struct AppGroupReadingStore: ReadingPersisting {
    public static let defaultSuiteName = "group.wm6h.CricketAI"

    private let suiteName: String
    private let key: String

    public init(suiteName: String = AppGroupReadingStore.defaultSuiteName,
                key: String = "latestReading") {
        self.suiteName = suiteName
        self.key = key
    }

    private var defaults: UserDefaults? { UserDefaults(suiteName: suiteName) }

    public func save(_ reading: Reading) {
        guard let defaults, let data = try? JSONEncoder().encode(reading) else { return }
        defaults.set(data, forKey: key)
    }

    public func load() -> Reading? {
        guard let defaults, let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Reading.self, from: data)
    }
}
