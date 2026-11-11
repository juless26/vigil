import SwiftUI

/// Figma: Patient Row. One mother in the Patients list.
/// `detail` says what is happening now, for example "Holding 42 min".
/// Never pass date of birth, diagnosis or medication, because the list shows on a shared unit phone.
public struct PatientRow: View {
    let name: String
    let detail: String
    let initials: String
    let status: VigilStatus

    public init(name: String, detail: String, initials: String, status: VigilStatus) {
        self.name = name
        self.detail = detail
        self.initials = initials
        self.status = status
    }

    public var body: some View {
        HStack(spacing: VigilLayout.Space.m) {
            Text(initials)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(VigilToken.Row.avatarLabel)
                .frame(width: VigilLayout.Size.avatar, height: VigilLayout.Size.avatar)
                .background(VigilToken.Row.avatarBackground, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(VigilToken.Row.name)
                    .lineLimit(1)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(VigilToken.Row.detail)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            StatusBadge(status: status)
            ChevronIcon()
        }
        .padding(.horizontal, VigilLayout.Space.l)
        .padding(.vertical, 10)
        .frame(minHeight: VigilLayout.Size.rowMin)
        .background(VigilToken.Row.background)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name). \(status.label). \(detail).")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    PatientRow(name: "Malika Williams", detail: "Holding 42 min", initials: "MW", status: .checkNow)
}
