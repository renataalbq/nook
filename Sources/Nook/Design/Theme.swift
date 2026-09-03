import SwiftUI
import AppKit

/// Single source of truth for the soft-stationery look.
///
/// Every colour is an appearance-aware `NSColor`, so light and dark come from
/// one declaration and follow the window without any view having to observe
/// `colorScheme` itself.
enum Theme {
    // MARK: Surfaces
    static let desk = dynamic(light: 0xF9F4EF, dark: 0x17161A)
    /// Cards, the sidebar, the toolbar chips — every raised surface.
    static let surface = dynamic(light: 0xF6ECEE, dark: 0x221F27)
    static let paper = dynamic(light: 0xFDFBF6, dark: 0x201F25)

    /// The floating format popover: dark on a light sheet, flipped to a pale
    /// card once the sheet itself goes dark.
    static let popover = dynamic(light: 0x2E2B33, dark: 0xF2ECE3)
    static let popoverInk = dynamic(light: 0xFFFFFF, dark: 0x2E2B33)

    // MARK: Ink
    static let ink = dynamic(light: 0x433D38, dark: 0xEDE7DC)
    static let inkSoft = dynamic(light: 0x8B8075, dark: 0x9A9187)

    // MARK: Neutral ramp — lightest to darkest.
    static let neutral1 = dynamic(light: 0xF1EAE1, dark: 0x2A2830)
    static let neutral2 = dynamic(light: 0xE0DACF, dark: 0x35333D)
    static let neutral3 = dynamic(light: 0xC9C1B6, dark: 0x45424C)
    static let neutral4 = dynamic(light: 0xABA298, dark: 0x5C5A62)
    static let neutral5 = dynamic(light: 0x6E655C, dark: 0x8A8790)

    // MARK: Sheet rules
    static let ruleLine = neutral2
    static let gridLine = dynamic(light: 0xCBDAE3, dark: 0xEEE7DB, lightAlpha: 0.75, darkAlpha: 0.13)

    static let cardShadow = Color.black.opacity(0.10)

    // MARK: Radii — small controls, cards, and the big sheet. True pills
    // (capsule shapes) compute their own radius and don't need a constant.
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 16
    static let radiusLarge: CGFloat = 28

    // MARK: Tints
    //
    // Each tint carries its own accent (the saturated, same-ish colour in
    // both appearances), a pastel fill for card backgrounds, a darker border
    // for strokes, and — light mode only — an extra-pale tone for subtle
    // highlights. Where dark mode wasn't given its own border, the light
    // one is reused rather than invented.
    struct TintPalette {
        let accentLight: UInt32
        let accentDark: UInt32
        let fillLight: UInt32
        let fillDark: UInt32
        let borderLight: UInt32
        let borderDark: UInt32
        let paleLight: UInt32

        var accent: Color { Theme.dynamic(light: accentLight, dark: accentDark) }
        var fill: Color { Theme.dynamic(light: fillLight, dark: fillDark) }
        var border: Color { Theme.dynamic(light: borderLight, dark: borderDark) }
        /// Light mode's extra-pale tone; dark mode falls back to `fill`,
        /// which already sits close to the background there.
        var pale: Color { Theme.dynamic(light: paleLight, dark: fillDark) }
    }

    static let blush = TintPalette(
        accentLight: 0xE79BAE, accentDark: 0xE79BAE,
        fillLight: 0xF3D2DA, fillDark: 0x4A2F38,
        borderLight: 0xA85F74, borderDark: 0x8C5A69,
        paleLight: 0xF9E2E8
    )
    static let sage = TintPalette(
        accentLight: 0x9DB584, accentDark: 0xB5C6A4,
        fillLight: 0xD4DEC8, fillDark: 0x2F3A2E,
        borderLight: 0x61794A, borderDark: 0x5D6E54,
        paleLight: 0xE3EBD9
    )
    /// "Azulzinho" in the spec — água / water track's colour.
    static let water = TintPalette(
        accentLight: 0x82AFDA, accentDark: 0x7FA6CC,
        fillLight: 0xD7E5EE, fillDark: 0x22303B,
        borderLight: 0x4C7397, borderDark: 0x46617A,
        paleLight: 0xE7F0F6
    )
    static let butter = TintPalette(
        accentLight: 0xE3BC6B, accentDark: 0xEBD9A8,
        fillLight: 0xF7EACB, fillDark: 0x6B5B3C,
        borderLight: 0x8A6B2E, borderDark: 0x8A6B2E,
        paleLight: 0xFBF1DA
    )
    static let lilac = TintPalette(
        accentLight: 0xA9A2D6, accentDark: 0xD8CDE8,
        fillLight: 0xE3DBEA, fillDark: 0x38304A,
        borderLight: 0x6A5C86, borderDark: 0x6A5C86,
        paleLight: 0xEDE7F2
    )

    static func tint(_ name: TintName) -> TintPalette {
        switch name {
        case .blush: return blush
        case .sky: return water
        case .sage: return sage
        case .butter: return butter
        case .lilac: return lilac
        }
    }

    /// The one saturated accent for anything acting as the primary call to
    /// action (the "texto" dock chip, the active nook row, selected states)
    /// — blush's accent, since that's the colour every such element already
    /// wears in the design.
    static let accent = blush.accent

    /// One tint's accent per letter, in tint order.
    static let wordmarkColors: [Color] = [blush.accent, sage.accent, butter.accent, lilac.accent]

    // MARK: - Type

    /// Body text: Nunito, weighted 400/500/600. Ships inside the app bundle
    /// (`Resources/Fonts`, registered via `ATSApplicationFontsPath`); falls
    /// back to rounded system type if that registration ever fails.
    static func hand(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .ultraLight, .thin: name = "Nunito-ExtraLight"
        case .light: name = "Nunito-Light"
        case .medium: name = "Nunito-Medium"
        case .semibold: name = "Nunito-SemiBold"
        case .bold: name = "Nunito-Bold"
        case .heavy: name = "Nunito-ExtraBold"
        case .black: name = "Nunito-Black"
        default: name = "Nunito-Regular"
        }
        guard NSFont(name: name, size: size) != nil else {
            return .system(size: size, weight: weight, design: .rounded)
        }
        return .custom(name, size: size)
    }

    /// Headings — "hoje", "água", a week's title, the wordmark: Baloo 2,
    /// bold or extra-bold.
    static func title(_ size: CGFloat, extraBold: Bool = false) -> Font {
        let name = extraBold ? "Baloo2-ExtraBold" : "Baloo2-Bold"
        guard NSFont(name: name, size: size) != nil else {
            return .system(size: size, weight: .bold, design: .rounded)
        }
        return .custom(name, size: size)
    }

    // MARK: - Plumbing

    /// Builds one colour that resolves differently in light and dark appearances.
    static func dynamic(light: UInt32, dark: UInt32, lightAlpha: Double = 1, darkAlpha: Double = 1) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return isDark ? NSColor(hex: dark, alpha: darkAlpha) : NSColor(hex: light, alpha: lightAlpha)
        })
    }
}

extension NSColor {
    convenience init(hex: UInt32, alpha: Double = 1) {
        self.init(
            srgbRed: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
