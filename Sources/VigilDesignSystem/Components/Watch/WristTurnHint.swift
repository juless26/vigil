import SwiftUI

/// Figma: Wrist Turn Hint. A hand rocks 30° each way beside the vibration waves,
/// (four waves for Tier 1, six for Tier 2)
/// to show her how to turn her wrist to stop the alert.
/// Alerts are vibrations only, so they never wake the baby.
/// The hand holds still when Reduce Motion is on.
public struct WristTurnHint: View {
    public enum Alert: Sendable {
        /// Tier 1. A gentle tap only she feels.
        case vibration
        /// Tier 2. A harder, longer tap. Six waves instead of four, and the hand rocks twice as fast.
        case strongVibration

        var artName: String {
            switch self {
            case .vibration: return "VibrationWaves"
            case .strongVibration: return "StrongVibrationWaves"
            }
        }

        var artSize: CGSize {
            switch self {
            case .vibration: return CGSize(width: 40, height: 50)
            case .strongVibration: return CGSize(width: 46, height: 56)
            }
        }

        var rockDuration: Double {
            switch self {
            case .vibration: return 0.9
            case .strongVibration: return 0.45
            }
        }
    }

    let alert: Alert
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rocked = false

    public init(alert: Alert) {
        self.alert = alert
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image("Hand", bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(reduceMotion ? 0 : (rocked ? 30 : -30)))
                .animation(reduceMotion ? nil : .easeInOut(duration: alert.rockDuration).repeatForever(autoreverses: true), value: rocked)
            Image(alert.artName, bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: alert.artSize.width, height: alert.artSize.height)
        }
        .frame(width: 100, height: alert.artSize.height + 2)
        .onAppear { rocked = true }
        .accessibilityElement()
        .accessibilityLabel("Turn your wrist to stop the alert")
    }
}
