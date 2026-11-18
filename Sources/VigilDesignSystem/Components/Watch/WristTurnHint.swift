import SwiftUI

/// Figma: Wrist Turn Hint. A hand rocks 30° each way beside six vibration waves
/// to show her how to turn her wrist to stop the alert.
/// Alerts are vibrations only, so they never wake the baby.
/// The hand holds still when Reduce Motion is on.
public struct WristTurnHint: View {
    public enum Alert: Sendable {
        /// The watch alert. Firm taps that repeat until she turns her wrist.
        case strongVibration

        var artName: String {
            switch self {
            case .strongVibration: return "StrongVibrationWaves"
            }
        }

        var artSize: CGSize {
            switch self {
            case .strongVibration: return CGSize(width: 46, height: 56)
            }
        }

        var rockDuration: Double {
            switch self {
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
