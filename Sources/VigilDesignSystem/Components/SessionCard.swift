import SwiftUI

/// Figma: Session Card. Holding time against her goal.
/// Pass `onPause` and `onEnd` while the session is running (State=Active).
/// Leave them out on the End session screen (State=Ended).
public struct SessionCard: View {
    let label: String
    let elapsed: String
    let goal: String
    let meta: String
    let progress: Double
    let onPause: (() -> Void)?
    let onEnd: (() -> Void)?

    public init(
        label: String,
        elapsed: String,
        goal: String,
        meta: String,
        progress: Double,
        onPause: (() -> Void)? = nil,
        onEnd: (() -> Void)? = nil
    ) {
        self.label = label
        self.elapsed = elapsed
        self.goal = goal
        self.meta = meta
        self.progress = progress
        self.onPause = onPause
        self.onEnd = onEnd
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(VigilColor.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(elapsed)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(VigilToken.Tile.value)
                Text(goal)
                    .font(.subheadline)
                    .foregroundStyle(VigilToken.Tile.label)
            }
            ProgressBar(value: progress)
            Text(meta)
                .font(.footnote)
                .foregroundStyle(VigilColor.textSecondary)
            if let onPause, let onEnd {
                HStack(spacing: VigilLayout.Space.s) {
                    VigilButton("Pause session", style: .tinted, action: onPause)
                    VigilButton("End session", style: .tinted, action: onEnd)
                }
            }
        }
        .padding(VigilLayout.Space.l)
        .background(VigilToken.cardBackground, in: RoundedRectangle(cornerRadius: VigilLayout.Radius.card))
    }
}

#Preview {
    VStack(spacing: 16) {
        SessionCard(label: "Holding session", elapsed: "42 min", goal: "of 120 min goal",
                    meta: "Started 2:18 PM · watch connected, battery 75%", progress: 42.0 / 120,
                    onPause: {}, onEnd: {})
        SessionCard(label: "Holding time", elapsed: "1 hr 43 min", goal: "of 2 hr goal",
                    meta: "Her watch is thanking her for her time.", progress: 103.0 / 120)
    }
    .padding()
}
