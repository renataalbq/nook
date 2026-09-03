import Foundation
import AppKit

/// Styled text, stored as RTF so fonts, sizes and colours survive a save.
struct RichText: Codable, Hashable {
    var rtf: Data
    /// Plain mirror, kept for search and for rebuilding if the RTF ever fails to parse.
    var plain: String

    init(rtf: Data, plain: String) {
        self.rtf = rtf
        self.plain = plain
    }

    init(plain: String = "") {
        let attributed = NSAttributedString(
            string: plain,
            attributes: [.font: NSFont.systemFont(ofSize: Paper.textSize)]
        )
        self.init(attributed: attributed)
    }

    init(attributed: NSAttributedString) {
        let range = NSRange(location: 0, length: attributed.length)
        self.rtf = attributed.rtf(from: range, documentAttributes: [:]) ?? Data()
        self.plain = attributed.string
    }

    var attributed: NSAttributedString {
        guard !rtf.isEmpty,
              let parsed = NSAttributedString(rtf: rtf, documentAttributes: nil)
        else { return NSAttributedString(string: plain) }
        return parsed
    }
}

/// One freehand pen mark on a page.
struct Stroke: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var points: [CGPoint]
    var colorHex: UInt32
    var width: Double
}

/// Which appearance the whole app is forced into.
enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "auto"
        case .light: return "claro"
        case .dark: return "escuro"
        }
    }

    /// Lucide icon name — see `Design/Lucide/LucideIcon.swift`.
    var symbol: String {
        switch self {
        case .system: return "sun-moon"
        case .light: return "sun"
        case .dark: return "moon"
        }
    }
}
