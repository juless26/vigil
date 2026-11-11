import SwiftUI

/// Figma: Patient Row. One mother in the Patients list.
/// `detail` says what is happening now, for example "Holding 42 min".
/// Never pass date of birth, diagnosis or medication, because the list shows on a shared unit phone.
/// Pass `photo` only if she agreed to photos on the consent form. Without it, her initials show.
public struct PatientRow: View {
    let name: String
    let detail: String
    let initials: String
    let status: VigilStatus
    let photo: Image?

    public init(name: String, detail: String, initials: String, status: VigilStatus, photo: Image? = nil) {
        self.name = name
        self.detail = detail
        self.initials = initials
        self.status = status
        self.photo = photo
    }

    public var body: some View {
        HStack(spacing: VigilLayout.Space.m) {
            PatientAvatar(initials: initials, photo: photo, size: VigilLayout.Size.avatar)
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
