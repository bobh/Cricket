//
//  LinkState.swift
//  CricketCore
//
//  Current connectivity, published for the UI. Drives which UnavailableReason
//  is returned when there is no cached reading.
//

/// Current connectivity state (feeds set this; the UI observes it).
public enum LinkState: Sendable, Equatable {
    case idle
    case scanning
    case connected
    case disconnected
    case bluetoothOff
    case bluetoothUnauthorized
    case bluetoothUnsupported
}
