//
//  ChatMessage.swift
//  CricketAI
//

import Foundation

struct ChatMessage: Identifiable, Equatable {
    enum Role {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
    let usedLocalConditions: Bool
}
