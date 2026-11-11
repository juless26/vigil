import SwiftUI

/// Tier 2: colors named by purpose, with light and dark values.
/// Matches the "Vigil Color" collection in Figma. Every text pair passes WCAG AA (4.5:1) in both modes.
public enum VigilColor {
    private typealias P = VigilPrimitive

    public static let surfaceScreen = Color.vigil(light: P.mist50, dark: P.ink1000)
    public static let surfaceCard = Color.vigil(light: P.white, dark: P.ink900)
    public static let surfaceControl = Color.vigil(light: P.mist100, dark: P.ink850)

    public static let textPrimary = Color.vigil(light: P.ink950, dark: P.mist50)
    public static let textSecondary = Color.vigil(light: P.ink600, dark: P.ink200)
    public static let textTertiary = Color.vigil(light: P.ink500, dark: P.ink300)
    public static let textOnAction = Color.vigil(light: P.white, dark: P.ink950)

    public static let borderSeparator = Color.vigil(light: P.mist200, dark: P.ink800)

    public static let actionPrimary = Color.vigil(light: P.blue600, dark: P.blue300)
    public static let actionTint = Color.vigil(light: P.blue50, dark: P.ink850)

    /// Orange and pink are for dots, edges and bars only. Never use them for small text.
    public static let statusCheckNow = Color.vigil(light: P.red600, dark: P.red300)
    public static let statusCheckSoon = Color.vigil(light: P.orange600, dark: P.orange300)
    public static let statusHolding = Color.vigil(light: P.pink600, dark: P.pink300)
    public static let statusInfo = Color.vigil(light: P.lavender600, dark: P.lavender300)
    public static let statusIdle = Color.vigil(light: P.ink450, dark: P.ink500)

    public static let statusCheckNowTint = Color.vigil(light: P.tintCheckNowLight, dark: P.tintCheckNowDark)
    public static let statusCheckSoonTint = Color.vigil(light: P.tintCheckSoonLight, dark: P.tintCheckSoonDark)
    public static let statusHoldingTint = Color.vigil(light: P.tintHoldingLight, dark: P.tintHoldingDark)
    public static let statusInfoTint = Color.vigil(light: P.tintInfoLight, dark: P.tintInfoDark)
}
