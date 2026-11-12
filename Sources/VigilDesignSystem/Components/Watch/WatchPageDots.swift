import SwiftUI

/// Figma: Watch Page Dots. Shows which of the two holding pages is on screen.
public struct WatchPageDots: View {
    public enum Page: Int, Sendable {
        case first = 1
        case second = 2
    }

    let page: Page

    public init(page: Page) {
        self.page = page
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(1...2, id: \.self) { index in
                Circle()
                    .fill(index == page.rawValue ? VigilColor.textPrimary : VigilColor.textTertiary)
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Page \(page.rawValue) of 2")
    }
}
