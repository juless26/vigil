import SwiftUI

/// Figma: Form Row, Type=Text. Typed entry. The label stays visible after typing.
/// Put "Required" or "Optional" in `prompt`, never rely on color.
public struct FormTextRow: View {
    let label: String
    let prompt: String
    @Binding var text: String

    public init(label: String, prompt: String, text: Binding<String>) {
        self.label = label
        self.prompt = prompt
        self._text = text
    }

    public var body: some View {
        HStack(spacing: VigilLayout.Space.m) {
            Text(label)
                .font(.body)
                .foregroundStyle(VigilToken.Form.label)
                .frame(width: 120, alignment: .leading)
            TextField(label, text: $text, prompt: Text(prompt).foregroundStyle(VigilToken.Form.placeholder))
                .font(.body)
                .foregroundStyle(VigilToken.Form.label)
        }
        .padding(.horizontal, VigilLayout.Space.l)
        .frame(minHeight: VigilLayout.Size.formRowMin)
        .background(VigilToken.Row.background)
    }
}

/// Figma: Form Row, Type=Picker. One choice from a list. Opens a menu instead of a stack of checkboxes.
public struct FormPickerRow<Option: Hashable>: View {
    let label: String
    let options: [Option]
    let title: (Option) -> String
    @Binding var selection: Option

    public init(label: String, options: [Option], selection: Binding<Option>, title: @escaping (Option) -> String) {
        self.label = label
        self.options = options
        self._selection = selection
        self.title = title
    }

    public var body: some View {
        Menu {
            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { Text(title($0)).tag($0) }
            }
        } label: {
            HStack(spacing: VigilLayout.Space.m) {
                Text(label)
                    .font(.body)
                    .foregroundStyle(VigilToken.Form.label)
                Spacer()
                Text(title(selection))
                    .font(.body)
                    .foregroundStyle(VigilToken.Form.value)
                ChevronIcon()
            }
            .padding(.horizontal, VigilLayout.Space.l)
            .frame(minHeight: VigilLayout.Size.formRowMin)
            .background(VigilToken.Row.background)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("\(label), \(title(selection))")
    }
}
