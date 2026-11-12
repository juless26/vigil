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
            Image(icon.rawValue, bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: icon == .pause ? 20 : 24, height: icon == .pause ? 20 : 24)
                .accessibilityHidden(true)
        }
        .frame(width: 56, height: 56)
        .accessibilityElement()
        .accessibilityLabel("Holding goal")
        .accessibilityValue("\(Int((progress * 100).rounded())) percent")
    }
}
