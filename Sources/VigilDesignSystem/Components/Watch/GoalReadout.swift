import SwiftUI

/// Figma: Goal Readout. Goal percent above minutes held, right-aligned beside the ring.
public struct GoalReadout: View {
    let percent: String
    let minutes: String

    /// - Parameters:
    ///   - percent: For example "GOAL 25%".
    ///   - minutes: For example "30/120 MIN".
    public init(percent: String, minutes: String) {
        self.percent = percent
        self.minutes = minutes
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(percent)
                .font(.headline.weight(.bold))
                .foregroundStyle(VigilColor.textPrimary)
            Text(minutes)
                .font(.footnote)
                .foregroundStyle(VigilToken.Watch.accent)
        }
        .accessibilityElement(children: .combine)
    }
}
