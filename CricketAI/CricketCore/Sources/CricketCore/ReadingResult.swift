//
//  ReadingResult.swift
//  CricketCore
//
//  The discriminated result every consumer receives (FR-6). There is deliberately
//  NO way to obtain a bare Double — staleness and unavailability are un-ignorable.
//

/// The discriminated result every consumer receives (FR-6, FR-7).
public enum ReadingResult: Sendable, Equatable {
    case fresh(Reading)
    case stale(Reading, age: Duration)
    case unavailable(UnavailableReason)
}

extension ReadingResult {
    /// The underlying reading if one exists (fresh or stale); nil when unavailable.
    public var reading: Reading? {
        switch self {
        case .fresh(let r):    return r
        case .stale(let r, _): return r
        case .unavailable:     return nil
        }
    }

    /// Human/agent-facing age note the dialog layer and Tool can append (FR-12, AB-4).
    public var freshnessNote: String {
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
