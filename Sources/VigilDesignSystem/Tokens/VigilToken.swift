import SwiftUI

/// Tier 3: colors named by where they are used.
/// Matches the "Vigil Component" collection in Figma. Each one points to a `VigilColor`.
public enum VigilToken {
    private typealias C = VigilColor
    private typealias P = VigilPrimitive

    public enum Badge {
        public static let label = C.textPrimary
        public static func background(_ status: VigilStatus) -> Color {
            switch status {
            case .checkNow: return C.statusCheckNowTint
            case .checkSoon: return C.statusCheckSoonTint
            case .holding: return C.statusHoldingTint
            case .notHolding: return C.surfaceControl
            }
        }
        public static func dot(_ status: VigilStatus) -> Color {
            switch status {
            case .checkNow: return C.statusCheckNow
            case .checkSoon: return C.statusCheckSoon
            case .holding: return C.statusHolding
            case .notHolding: return C.statusIdle
            }
        }
    }

    public enum Button {
        public static let filledBackground = C.actionPrimary
        public static let filledLabel = C.textOnAction
        /// Same as the card surface. The blue edge carries the button shape.
        public static let tintedBackground = C.surfaceCard
        /// 1.5 pt edge, at least 5 to 1 against every background.
        public static let tintedBorder = C.actionPrimary
        public static let tintedLabel = C.actionPrimary
        public static let disabledBackground = C.surfaceControl
        public static let disabledLabel = C.textSecondary
    }

    public enum Alert {
        public static let title = C.textPrimary
        public static let body = C.textSecondary
        public static let meta = C.textSecondary
        /// Only Check now cards are filled. Check soon cards are white with an orange edge.
        public static func background(_ level: AlertLevel) -> Color {
            level == .checkNow ? C.statusCheckNowTint : C.surfaceCard
        }
        public static func border(_ level: AlertLevel) -> Color {
            level == .checkNow ? C.statusCheckNow : C.statusCheckSoon
        }
    }

    public enum Row {
        public static let background = C.surfaceCard
        public static let avatarBackground = C.statusInfoTint
        public static let avatarLabel = C.textPrimary
        public static let name = C.textPrimary
        public static let detail = C.textSecondary
    }

    public enum List {
        public static let background = C.surfaceCard
        public static let separator = C.borderSeparator
        public static let header = C.textSecondary
    }

    public enum Vital {
        public static let label = C.textPrimary
        public static let value = C.textPrimary
        public static let unit = C.textSecondary
        public static let meta = C.textSecondary
    }

    public enum Tile {
        public static let background = C.surfaceCard
        public static let value = C.textPrimary
        public static let label = C.textSecondary
    }

    public enum Form {
        public static let label = C.textPrimary
        public static let value = C.textSecondary
        public static let placeholder = C.textTertiary
    }

    public enum Choice {
        public static let label = C.textPrimary
        public static let check = C.actionPrimary
    }

    public enum Progress {
        public static let track = C.surfaceControl
        public static let fill = C.statusHolding
    }

    /// Watch screens. Pink for the ring and hearts; white for icon outlines and the pause sign.
    public enum Watch {
        public static let background = P.black
        public static let accent = P.pinkWatch
        public static let icon = P.white
    }

    public static let chevron = C.textTertiary
    public static let screenBackground = C.surfaceScreen
    public static let cardBackground = C.surfaceCard
}
