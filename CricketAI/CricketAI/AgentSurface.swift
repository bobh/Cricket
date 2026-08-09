//
//  AgentSurface.swift
//  CricketAI
//
//  Owns the on-device Foundation Models session used by the in-app chat.
//

import Foundation
import FoundationModels
import Observation
import CricketCore

@MainActor
@Observable
final class AgentSurface {
    private static let instructions = """
        You are CricketAI, an environmental assistant using a sensor in the user's immediate space.
        When you state any current temperature, humidity, or pressure for the user's location, that
        value must come from the environmental reading tool's latest result. Never estimate, recall,
        or infer a current value from general knowledge, weather, or earlier conversation. Always
        disclose whether the reading is fresh, stale, or unavailable. If unavailable, give only
        general guidance and do not invent a substitute value. Use your own domain knowledge to
        reason and advise. Recommend normal safety precautions when appropriate. Do not request
        location, weather, web, or network access for current local-condition questions.
        """

    private let model: SystemLanguageModel
    private let session: LanguageModelSession
    private let tracker: ToolUseTracker

    private(set) var messages: [ChatMessage] = []
    private(set) var isResponding = false

    init(core: CricketCore) {
        let model = SystemLanguageModel.default
        let tracker = ToolUseTracker()
        let tool = ReadEnvironmentalConditions(core: core, tracker: tracker)

        self.model = model
        self.tracker = tracker
        self.session = LanguageModelSession(
            model: model,
            tools: [tool],
            instructions: Self.instructions
        )
    }

    var availabilityMessage: String? {
        switch model.availability {
        case .available:
            return nil
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                return "This device does not support the on-device Foundation Model."
            case .appleIntelligenceNotEnabled:
                return "Turn on Apple Intelligence to use Ask Cricket."
            case .modelNotReady:
                return "The on-device model is still downloading or preparing."
            @unknown default:
                return "The on-device Foundation Model is currently unavailable."
            }
        @unknown default:
            return "The on-device Foundation Model is currently unavailable."
        }
    }

    func send(_ rawPrompt: String) async {
        let prompt = rawPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isResponding else { return }

        messages.append(ChatMessage(role: .user, text: prompt, usedLocalConditions: false))

        guard availabilityMessage == nil else {
            messages.append(ChatMessage(
                role: .assistant,
                text: availabilityMessage ?? "The on-device model is unavailable.",
                usedLocalConditions: false
            ))
            return
        }

        isResponding = true
        tracker.reset()
        defer { isResponding = false }

        do {
            // CricketAI is a single-purpose environmental chat. Requiring the tool on every
            // turn provides the SDD's hard guarantee that advice cannot bypass current local data.
            let options = GenerationOptions(toolCallingMode: .required)
            let response = try await session.respond(to: prompt, options: options)
            messages.append(ChatMessage(
                role: .assistant,
                text: response.content,
                usedLocalConditions: tracker.wasUsed
            ))
        } catch {
            messages.append(ChatMessage(
                role: .assistant,
                text: "I couldn't complete that request. \(error.localizedDescription)",
                usedLocalConditions: tracker.wasUsed
            ))
        }
    }
}
