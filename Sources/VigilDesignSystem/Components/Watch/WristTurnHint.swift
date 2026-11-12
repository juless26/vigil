import SwiftUI

/// Figma: Wrist Turn Hint. A hand rocks 30° each way beside the vibration waves,
/// to show her how to turn her wrist to stop the alert.
/// Alerts are vibrations only, so they never wake the baby.
/// The hand holds still when Reduce Motion is on.
public struct WristTurnHint: View {
    public enum Alert: Sendable {
        /// Tier 1. A gentle tap only she feels.
        case vibration
        /// Tier 2. A harder, longer tap. The hand rocks twice as fast.
        case strongVibration

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
            Image("VibrationWaves", bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 50)
        }
        .frame(width: 100, height: 52)
        .onAppear { rocked = true }
        .accessibilityElement()
        .accessibilityLabel("Turn your wrist to stop the alert")
    }
}
