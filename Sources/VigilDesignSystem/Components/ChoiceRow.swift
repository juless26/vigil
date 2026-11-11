import SwiftUI

/// Figma: Choice Row. One answer in a short list the nurse taps at the bedside.
/// Use for 2 to 5 visible answers. For longer lists, use `FormPickerRow`.
public struct ChoiceRow: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    public init(_ label: String, isSelected: Bool, action: @escaping () -> Void) {
        self.label = label
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: VigilLayout.Space.m) {
                Text(label)
                    .font(.body)
                    .foregroundStyle(VigilToken.Choice.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(VigilToken.Choice.check)
                    .opacity(isSelected ? 1 : 0)
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
    }
}

#Preview {
    VStack(spacing: 0) {
        ChoiceRow("She was awake", isSelected: false) {}
        ChoiceRow("Drowsy, woke when I spoke", isSelected: true) {}
    }
}
