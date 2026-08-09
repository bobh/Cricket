//
//  ToolUseTracker.swift
//  CricketAI
//

import Observation

@MainActor
@Observable
final class ToolUseTracker {
    private(set) var wasUsed = false

    func reset() {
        wasUsed = false
    }

    func markUsed() {
        wasUsed = true
    }
}
