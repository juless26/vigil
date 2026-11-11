import CoreGraphics

/// Spacing, radius and size values. Matches the "Vigil Layout" collection in Figma.
public enum VigilLayout {
    public enum Space {
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 12
        public static let l: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
    }

    public enum Radius {
        public static let badge: CGFloat = 12
        public static let tile: CGFloat = 20
        public static let card: CGFloat = 24
        public static let button: CGFloat = 25
    }

    public enum Size {
        /// Smallest tappable height allowed (Apple HIG).
        public static let touchMin: CGFloat = 44
        public static let buttonLarge: CGFloat = 50
        public static let buttonMedium: CGFloat = 44
        public static let rowMin: CGFloat = 64
        public static let formRowMin: CGFloat = 48
        public static let avatar: CGFloat = 44
    }

    /// Opacity while a finger is down. Figma stores this as 70 (percent).
    public static let pressedOpacity: Double = 0.7
}
