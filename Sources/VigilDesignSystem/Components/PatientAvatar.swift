import SwiftUI

/// Figma: Patient Avatar. A mother's portrait in a circle, or her initials when there is no photo.
/// Sizes: 44 pt in list rows, 64 pt on the patient screen header, 96 pt on the full-screen alert.
/// Decorative for VoiceOver, because her name is always read nearby.
public struct PatientAvatar: View {
    let initials: String
    let photo: Image?
    let size: CGFloat

    public init(initials: String, photo: Image?, size: CGFloat = VigilLayout.Size.avatar) {
        self.initials = initials
        self.photo = photo
        self.size = size
    }

    public var body: some View {
        Group {
            if let photo {
                photo
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Text(initials)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(VigilToken.Row.avatarLabel)
                    .frame(width: size, height: size)
                    .background(VigilToken.Row.avatarBackground, in: Circle())
            }
        }
        .accessibilityHidden(true)
    }
}
