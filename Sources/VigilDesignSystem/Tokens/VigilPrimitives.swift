import SwiftUI

/// Tier 1: raw color values. Matches the "Vigil Primitives" collection in Figma.
/// Screens and components never use these directly. Use `VigilColor` or `VigilToken` instead.
enum VigilPrimitive {
    static let blue600 = Color(hex: 0x3A55D4)
    static let blue300 = Color(hex: 0x8EA2FF)
    static let blue50 = Color(hex: 0xEEF1FD)

    static let lavender600 = Color(hex: 0x6E5FD0)
    static let lavender300 = Color(hex: 0xB3A9F2)

    static let pink600 = Color(hex: 0xD6407F)
    static let pink300 = Color(hex: 0xFF8FBF)

    static let orange600 = Color(hex: 0xD9481F)
    static let orange300 = Color(hex: 0xFF8A5C)

    static let red600 = Color(hex: 0xC8243A)
    static let red300 = Color(hex: 0xFF7A84)

    static let ink1000 = Color(hex: 0x0A0D24)
    static let ink950 = Color(hex: 0x141A3D)
    static let ink900 = Color(hex: 0x151937)
    static let ink850 = Color(hex: 0x21264A)
    static let ink800 = Color(hex: 0x2C3260)
    static let ink600 = Color(hex: 0x474E86)
    static let ink500 = Color(hex: 0x5F66A3)
    static let ink450 = Color(hex: 0x757BBA)
    static let ink300 = Color(hex: 0x9499D0)
    static let ink200 = Color(hex: 0xB6BBE8)

    static let mist200 = Color(hex: 0xDDE0F7)
    static let mist100 = Color(hex: 0xE8EAFB)
    static let mist50 = Color(hex: 0xF3F4FE)
    static let white = Color(hex: 0xFFFFFF)

    static let tintCheckNowLight = Color(hex: 0xFBE4E7)
    static let tintCheckNowDark = Color(hex: 0x44182F)
    static let tintCheckSoonLight = Color(hex: 0xFDE9E1)
    static let tintCheckSoonDark = Color(hex: 0x3E2340)
    static let tintHoldingLight = Color(hex: 0xFBE4EF)
    static let tintHoldingDark = Color(hex: 0x3E1D3C)
    static let tintInfoLight = Color(hex: 0xECE9FB)
    static let tintInfoDark = Color(hex: 0x2A2656)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    /// A color that switches between light and dark mode.
    /// Apple Watch always uses the dark value.
    static func vigil(light: Color, dark: Color) -> Color {
        #if os(watchOS)
        return dark
        #else
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #endif
    }
}
