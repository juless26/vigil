import SwiftUI

/// The four states a mother can be in. There is no fifth state.
/// To add one, add it in Figma (Status Badge variants) and here at the same time.
public enum VigilStatus: String, CaseIterable, Sendable {
    /// The watch could not wake her. A nurse needs to go now.
    case checkNow
    /// The watch nudged her and she responded.
    case checkSoon
    /// Session going well.
    case holding
    /// No session right now.
    case notHolding

    public var label: String {
        switch self {
        case .checkNow: return "Check now"
        case .checkSoon: return "Check soon"
        case .holding: return "Holding"
        case .notHolding: return "Not holding"
        }
    }
}

/// Figma: Status Badge. A colored dot plus a word, so color is never the only signal.
public struct StatusBadge: View {
    let status: VigilStatus

    public init(status: VigilStatus) {
        self.status = status
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(VigilToken.Badge.dot(status))
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(status.label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(VigilToken.Badge.label)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, VigilLayout.Space.xs)
        .background(VigilToken.Badge.background(status), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status, \(status.label)")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        ForEach(VigilStatus.allCases, id: \.self) { StatusBadge(status: $0) }
    }
    .padding()
}
