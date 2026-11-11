import SwiftUI

/// A mother's portrait in a circle with a thin outline, or her initials when there is no photo.
/// Used inside Patient Row (44 pt) and on the patient screen header (64 pt).
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
                    .overlay(Circle().strokeBorder(VigilToken.Row.avatarBorder, lineWidth: size > 50 ? 1.5 : 1))
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
