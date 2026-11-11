import SwiftUI

/// Figma: Icon / Chevron Right. Decorative, so VoiceOver skips it.
public struct ChevronIcon: View {
    public init() {}

    public var body: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(VigilToken.chevron)
            .accessibilityHidden(true)
    }
}
