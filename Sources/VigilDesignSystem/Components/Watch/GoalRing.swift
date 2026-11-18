import SwiftUI

/// Figma: Goal Ring. Holding time against her goal, with an icon in the center.
/// Figma shows fixed progress steps; code takes the exact value from 0 to 1.
public struct GoalRing: View {
    public enum Icon: String, Sendable {
        /// She is holding her baby.
        case handHeart = "HandHeart"
        /// An alert is playing on her watch.
        case hand = "Hand"
        /// Holding time is paused until the nurse arrives.
        case pause = "Pause"
        /// She reached her holding goal.
        case star = "Star"
    }

    let icon: Icon
    let progress: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var heartTilted = false

    /// From the WatchV2 prototype: the heart swings 25.6° counterclockwise and back
    /// about its own center, while the hand holds still.
    private static let heartSwingDegrees = -25.6
    private static let heartPivot = UnitPoint(x: 16.76 / 24, y: 6.10 / 24)
    private static let heartSwingSeconds = 0.8

    public init(icon: Icon, progress: Double) {
        self.icon = icon
        self.progress = min(max(progress, 0), 1)
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(VigilToken.Progress.track, lineWidth: 3.4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(VigilToken.Watch.accent, style: StrokeStyle(lineWidth: 3.4, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            iconView
                .accessibilityHidden(true)
        }
        .frame(width: 56, height: 56)
        .onAppear { heartTilted = true }
        .accessibilityElement()
        .accessibilityLabel("Holding goal")
        .accessibilityValue("\(Int((progress * 100).rounded())) percent")
    }

    @ViewBuilder
    private var iconView: some View {
        if icon == .handHeart {
            // The hand and heart are separate layers so only the heart rocks.
            // The heart holds still when Reduce Motion is on.
            ZStack {
                Image("HandOnly", bundle: .module)
                    .resizable()
                    .scaledToFit()
                Image("HeartOnly", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(reduceMotion || !heartTilted ? 0 : Self.heartSwingDegrees),
                                    anchor: Self.heartPivot)
                    .animation(reduceMotion ? nil : .easeInOut(duration: Self.heartSwingSeconds)
                        .repeatForever(autoreverses: true), value: heartTilted)
            }
            .frame(width: 24, height: 24)
        } else {
            Image(icon.rawValue, bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: icon == .pause ? 20 : 24, height: icon == .pause ? 20 : 24)
        }
    }
}
