import SwiftUI

public enum AlertLevel: Sendable {
    /// The watch could not wake her. Stays on screen until a nurse acts.
    case checkNow
    /// The watch nudged her and she responded.
    case checkSoon

    var status: VigilStatus { self == .checkNow ? .checkNow : .checkSoon }
}

/// Figma: Alert Card. Pinned to the top of a patient screen.
/// Write `title` and `body` about what the watch measured, not about the mother.
public struct AlertCard: View {
    public struct Action {
        let label: String
        let handler: () -> Void

        public init(_ label: String, handler: @escaping () -> Void) {
            self.label = label
            self.handler = handler
        }
    }

    let level: AlertLevel
    let title: String
    let message: String
    let time: String
    let primary: Action
    let secondary: Action

    public init(level: AlertLevel, title: String, message: String, time: String, primary: Action, secondary: Action) {
        self.level = level
        self.title = title
        self.message = message
        self.time = time
        self.primary = primary
        self.secondary = secondary
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: VigilLayout.Space.m) {
            HStack(spacing: VigilLayout.Space.s) {
                Circle()
                    .fill(VigilToken.Alert.border(level))
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)
                Text(level.status.label)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(VigilToken.Alert.title)
                Spacer()
                Text(time)
                    .font(.footnote)
                    .foregroundStyle(VigilToken.Alert.meta)
            }
            Text(title)
                .font(.headline)
                .foregroundStyle(VigilToken.Alert.title)
            Text(message)
                .font(.body)
                .foregroundStyle(VigilToken.Alert.body)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: VigilLayout.Space.s) {
                VigilButton(primary.label, style: .filled, action: primary.handler)
                VigilButton(secondary.label, style: .tinted, action: secondary.handler)
            }
        }
        .padding(VigilLayout.Space.l)
        .background(VigilToken.Alert.background(level), in: RoundedRectangle(cornerRadius: VigilLayout.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VigilLayout.Radius.card)
                .strokeBorder(VigilToken.Alert.border(level), lineWidth: 1.5)
        )
        .accessibilityElement(children: .contain)
        .onAppear {
            AccessibilityNotification.Announcement("\(level.status.label). \(title)").post()
        }
    }
}

#Preview {
    AlertCard(
        level: .checkNow,
        title: "Malika may be asleep",
        message: "The watch tapped Malika twice and she has not responded. Her heart rate dropped from 80 to 66 bpm in 4 minutes, below her resting rate of 74.",
        time: "2 min ago",
        primary: .init("I’m going now") {},
        secondary: .init("Call charge nurse") {}
    )
    .padding()
}
