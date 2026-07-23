//
//  ReadingPersisting.swift
//  CricketCore
//
//  Cross-process handoff. An App Intent may perform() in an extension process that has
//  no live BLE link; it reads the last-known reading persisted here by the foreground/
//  background app process.
//

/// A store for the last-known reading, shared across processes (app ⇄ intent extension).
public protocol ReadingPersisting: Sendable {
    func save(_ reading: Reading)
    func load() -> Reading?
}
