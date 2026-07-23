//
//  UnavailableReason.swift
//  CricketCore
//
//  Why no reading can be served. Distinct cases let the agent / dialog explain *why*
//  rather than emit a fabricated value (FR-7, AB-2).
//

/// Why no reading can be served (FR-7, AB-2).
public enum UnavailableReason: String, Sendable, Equatable, Codable {
    case neverConnected          // no sensor has ever reported this session/install
    case disconnected            // was connected; link dropped and no cached reading
    case bluetoothOff
    case bluetoothUnauthorized
    case bluetoothUnsupported
    case sensorError             // most recent packet was a sentinel (-32768 / 65535)
}
