import SwiftUI

/// Figma: Button. Style, Size and State (Default, Pressed, Disabled).
/// Pressed comes from the finger being down. Disabled comes from `.disabled(true)`.
public struct VigilButton: View {
    public enum Style: Sendable {
        /// The single main action in a screen region.
        case filled
        /// Any other action.
        case tinted
    }

    public enum Size: Sendable {
        /// 50 pt. Screen and card actions.
        case large
        /// 44 pt. Tight rows. Never smaller than the touch minimum.
        case medium
    }

    let label: String
    let style: Style
    let size: Size
    let action: () -> Void

    public init(_ label: String, style: Style = .filled, size: Size = .large, action: @escaping () -> Void) {
        self.label = label
        self.style = style
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(label)
        }
        .buttonStyle(VigilButtonStyle(style: style, size: size))
    }
}

struct VigilButtonStyle: ButtonStyle {
    let style: VigilButton.Style
    let size: VigilButton.Size
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size == .large ? .headline : .subheadline.weight(.semibold))
            .foregroundStyle(labelColor)
            .padding(.horizontal, size == .large ? 20 : 16)
            .frame(maxWidth: .infinity, minHeight: size == .large ? VigilLayout.Size.buttonLarge : VigilLayout.Size.buttonMedium)
            .background(backgroundColor, in: Capsule())
            .overlay {
                if style == .tinted && isEnabled {
                    Capsule().strokeBorder(VigilToken.Button.tintedBorder, lineWidth: 1.5)
                }
            }
            .opacity(configuration.isPressed ? VigilLayout.pressedOpacity : 1)
            .contentShape(Capsule())
    }

    private var backgroundColor: Color {
        guard isEnabled else { return VigilToken.Button.disabledBackground }
        return style == .filled ? VigilToken.Button.filledBackground : VigilToken.Button.tintedBackground
    }

    private var labelColor: Color {
        guard isEnabled else { return VigilToken.Button.disabledLabel }
        return style == .filled ? VigilToken.Button.filledLabel : VigilToken.Button.tintedLabel
    }
}

#Preview {
    VStack(spacing: 12) {
        VigilButton("End session") {}
        VigilButton("Pause session", style: .tinted) {}
        VigilButton("Next", size: .medium) {}.disabled(true)
    }
    .padding()
}
