import SwiftUI

/// Figma: Progress Bar. Holding time against her goal.
/// Figma shows 10% steps; code takes the exact value from 0 to 1.
public struct ProgressBar: View {
    let value: Double

    public init(value: Double) {
        self.value = min(max(value, 0), 1)
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(VigilToken.Progress.track)
                Capsule().fill(VigilToken.Progress.fill)
                    .frame(width: proxy.size.width * value)
            }
        }
        .frame(height: 8)
        .accessibilityElement()
        .accessibilityLabel("Progress toward goal")
        .accessibilityValue("\(Int((value * 100).rounded())) percent")
    }
}
