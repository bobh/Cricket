//
//  ChatView.swift
//  CricketAI
//

import Foundation
import SwiftUI

struct ChatView: View {
    @Environment(CricketRuntime.self) private var runtime
    @State private var prompt = ""

    private var agent: AgentSurface { runtime.agent }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let availability = agent.availabilityMessage {
                    availabilityBanner(availability)
                }

                ScrollView {
                    LazyVStack(spacing: 14) {
                        if agent.messages.isEmpty {
                            emptyState
                        }

                        ForEach(agent.messages) { message in
                            messageRow(message)
                        }

                        if agent.isResponding {
                            HStack {
                                ProgressView()
                                Text("Checking local conditions…")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }

                Divider()
                composer
            }
            .navigationTitle("Ask Cricket")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Ask About Your Space", systemImage: "sparkles")
        } description: {
            Text("Try “Is it safe to work on CMOS devices right now?”")
        }
        .padding(.top, 48)
    }

    private func availabilityBanner(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundStyle(DesignColor.statusWarning)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(DesignColor.cardBackground)
    }

    private func messageRow(_ message: ChatMessage) -> some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
            Text(message.text)
                .textSelection(.enabled)
                .padding(12)
                .background(message.role == .user ? DesignColor.brandBlue : DesignColor.cardBackground)
                .foregroundStyle(message.role == .user ? Color.white : Color.primary)
                .clipShape(.rect(cornerRadius: 14))

            if message.role == .assistant, message.usedLocalConditions {
                Label("Used local sensor conditions", systemImage: "sensor.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
        .padding(.horizontal)
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Ask about current conditions", text: $prompt, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.send)
                .onSubmit(send)

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
            }
            .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || agent.isResponding)
            .accessibilityLabel("Send")
        }
        .padding()
    }

    private func send() {
        let submittedPrompt = prompt
        prompt = ""
        Task {
            await agent.send(submittedPrompt)
        }
    }
}

#Preview {
    ChatView()
        .environment(CricketRuntime())
}
