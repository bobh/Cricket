//
//  LEDColor.swift
//  Cricket
//
//  LED status indicator view for iOS
//

import SwiftUI
import Combine

/// Enum for LED colors
enum LEDColor: UInt8 {
    case red = 0
    case green = 1
    case amber = 2
    case blue = 3

    var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .green: return .green
        case .amber: return .orange // Amber as yellowish-orange
        case .blue: return .blue
        }
    }

    var dimColor: Color {
        swiftUIColor.opacity(0.2) // Dim version for off state
    }
}

/// Enum for LED modes
enum LEDMode {
    case on
    case off
    case blink
}

/// A SwiftUI View that mimics a round thru-hole LED (e.g., 3mm or 5mm diameter style).
/// It supports on, off, and blink modes with internal 1-second interval timing for blinking.
/// The LED appearance matches the Arduino GraphicalLED with a gray housing, colored lens,
/// white highlight for dome effect, and glow when lit.
struct LEDView: View {
    var color: LEDColor = .red
    var mode: LEDMode = .off
    var size: CGFloat = 20.0 // Diameter in points

    @State private var isLit: Bool = false

    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Base circle for thru-hole housing (gray)
            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 1) // Black outline for depth
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

            // Inner LED lens (slightly smaller circle)
            Circle()
                .fill(isLit ? color.swiftUIColor : color.dimColor)
                .frame(width: size * 0.9, height: size * 0.9)

            // White highlight for dome effect (offset slightly)
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.3, height: size * 0.3)
                .offset(x: -size * 0.1, y: -size * 0.1)
                .blendMode(.overlay) // Blend with the lens color

            // Glow effect when lit (larger, semi-transparent circle)
            if isLit {
                Circle()
                    .fill(color.swiftUIColor.opacity(0.3))
                    .frame(width: size * 1.2, height: size * 1.2)
                    .blur(radius: 3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mode == .on ? "Status: Connected" : (mode == .blink ? "Status: Connecting" : "Status: Disconnected"))
        .onReceive(timer) { _ in
            if mode == .blink {
                isLit.toggle()
            }
        }
        .onChange(of: mode) { oldMode, newMode in
            switch newMode {
            case .on:
                isLit = true
            case .off:
                isLit = false
            case .blink:
                isLit = true // Start blink from on
            }
        }
        .onAppear {
            switch mode {
            case .on:
                isLit = true
            case .off:
                isLit = false
            case .blink:
                isLit = true
            }
        }
    }
}
