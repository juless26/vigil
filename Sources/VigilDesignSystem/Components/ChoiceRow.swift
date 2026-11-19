import SwiftUI

/// Figma: Choice Row. One answer in a short list the nurse taps at the bedside.
/// Use for 2 to 5 visible answers. For longer lists, use `FormPickerRow`.
/// `mark` shows how many answers she can pick: `.radio` for one, `.checkbox` for several.
/// Nothing is selected until she taps, so a saved answer is always her own.
public struct ChoiceRow: View {
    /// Figma: Mark property.
    public enum Mark: Sendable {
        /// Pick one answer.
        case radio
        /// Pick all that apply.
        case checkbox
    }

    let label: String
    let isSelected: Bool
    let mark: Mark
    let action: () -> Void

    public init(_ label: String, isSelected: Bool, mark: Mark = .radio, action: @escaping () -> Void) {
        self.label = label
        self.isSelected = isSelected
        self.mark = mark
        self.action = action
    }

    private var symbol: String {
        switch mark {
        case .radio: isSelected ? "largecircle.fill.circle" : "circle"
        case .checkbox: isSelected ? "checkmark.square.fill" : "square"
        }
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: VigilLayout.Space.m) {
                Text(label)
                    .font(.body)
                    .foregroundStyle(VigilToken.Choice.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: symbol)
                    .font(.title3)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(isSelected && mark == .checkbox ? VigilToken.Choice.markOn
                                         : isSelected ? VigilToken.Choice.check : VigilToken.Choice.markOff,
                                     isSelected ? VigilToken.Choice.check : VigilToken.Choice.markOff)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, VigilLayout.Space.l)
            .padding(.vertical, VigilLayout.Space.m)
            .frame(minHeight: VigilLayout.Size.formRowMin)
            .background(VigilToken.Row.background)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(mark == .radio ? "Pick one" : "Pick all that apply")
    }
}

#Preview {
    VStack(spacing: 0) {
        ChoiceRow("She was awake", isSelected: false) {}
        ChoiceRow("Drowsy, woke when I spoke", isSelected: true) {}
        ChoiceRow("Called the charge nurse", isSelected: false, mark: .checkbox) {}
        ChoiceRow("Moved the baby to the isolette", isSelected: true, mark: .checkbox) {}
    }
}
