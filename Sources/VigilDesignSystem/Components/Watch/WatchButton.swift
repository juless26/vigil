import SwiftUI

/// Figma: Watch Button. 176 × 36 capsule on the dark control surface.
/// The tap area grows to 44 pt tall so it meets the touch minimum.
public struct WatchButton: View {
    let label: String
    let action: () -> Void

    public init(_ label: String, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(VigilColor.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(VigilColor.surfaceControl, in: Capsule())
                .padding(.vertical, (VigilLayout.Size.touchMin - 36) / 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
