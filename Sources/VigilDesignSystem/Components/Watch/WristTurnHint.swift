import SwiftUI

/// Figma: Wrist Turn Hint. A hand rocks 30° each way beside the alert art,
/// to show her how to turn her wrist to stop the alert.
/// The hand holds still when Reduce Motion is on.
public struct WristTurnHint: View {
    public enum Alert: Sendable {
        /// Tier 1. Private haptic tap.
        case vibration
        /// Tier 2. The sound she chose.
        case audio

        var artName: String {
            switch self {
            case .vibration: return "VibrationWaves"
            case .audio: return "AudioBars"
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
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: rocked)
            Image(alert.artName, bundle: .module)
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
