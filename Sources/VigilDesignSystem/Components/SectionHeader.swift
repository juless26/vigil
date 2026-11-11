import SwiftUI

/// Figma: Section Header. Label above a grouped list. Sentence case, never all caps.
public struct SectionHeader: View {
    let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(VigilToken.List.header)
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, VigilLayout.Space.l)
            .padding(.top, VigilLayout.Space.l)
            .padding(.bottom, 6)
            .accessibilityAddTraits(.isHeader)
    }
}
