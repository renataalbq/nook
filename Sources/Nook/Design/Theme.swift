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
    static let paper = dynamic(light: 0xFDFBF6, dark: 0x201F25)
    static let chrome = dynamic(light: 0xFFFFFF, dark: 0x272630)

    // MARK: Ink
    static let ink = dynamic(light: 0x433D38, dark: 0xEDE7DC)
    static let inkSoft = dynamic(light: 0x8B8075, dark: 0x9A9187)

    // MARK: Sheet rules
    static let ruleLine = dynamic(light: 0xE0DACF, dark: 0x35333D)
    static let gridLine = dynamic(light: 0xCBDAE3, dark: 0x33323E)

    // MARK: Pastels
    static let blush = dynamic(light: 0xF6D8DE, dark: 0x4A2F38)
    static let sky = dynamic(light: 0xD7E5EE, dark: 0x2B3A47)
    static let sage = dynamic(light: 0xD4DEC8, dark: 0x2F3A2E)
    static let butter = dynamic(light: 0xF7EACB, dark: 0x453B27)
    static let lilac = dynamic(light: 0xE3DBEA, dark: 0x38304A)

    static let water = dynamic(light: 0x82AFDA, dark: 0x7FA6CC)

    static func tint(_ name: TintName) -> Color {
        switch name {
        case .blush: return blush
        case .sky: return sky
        case .sage: return sage
        case .butter: return butter
        case .lilac: return lilac
        }
    }

    /// Rounded system face stands in for a handwritten font until one ships with the app.
    static func hand(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let cardShadow = Color.black.opacity(0.10)

    // MARK: - Plumbing

    /// Builds one colour that resolves differently in light and dark appearances.
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        })
    }
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
