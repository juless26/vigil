import SwiftUI

/// Watch icon button. A 56 × 36 capsule on the dark control surface, with a white icon.
/// The tap area grows to 44 pt tall so it meets the touch minimum.
/// Figma: Watch Icon Button.
public struct WatchIconButton: View {
    public enum Icon: String, Sendable {
        /// Pause holding and call the nurse.
        case pause = "Pause"
    }

    let icon: Icon
    let label: String
    let action: () -> Void

    /// - Parameters:
    ///   - label: What VoiceOver reads, for example "Pause and call the nurse".
    public init(_ icon: Icon, label: String, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(icon.rawValue, bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .frame(width: 56, height: 36)
                .background(VigilColor.surfaceControl, in: Capsule())
                .padding(.vertical, (VigilLayout.Size.touchMin - 36) / 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#Preview {
    WatchIconButton(.pause, label: "Pause and call the nurse") {}
        .padding()
        .background(.black)
}
