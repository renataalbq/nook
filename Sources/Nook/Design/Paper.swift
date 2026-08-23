import AppKit
import CoreGraphics

/// Geometry shared by the sheet background and anything that has to line up with it.
enum Paper {
    static let ruleSpacing: CGFloat = 28
    static let gridSpacing: CGFloat = 22
    static let textSize: CGFloat = 15

    /// Height of one rendered line of body text.
    static let textLineHeight: CGFloat = {
        let font = NSFont.systemFont(ofSize: textSize)
        return ceil(font.ascender - font.descender + font.leading)
    }()

    /// Extra gap so consecutive text lines land exactly one rule apart.
    static let ruledLineSpacing: CGFloat = max(0, ruleSpacing - textLineHeight)

    /// TextEditor draws with its own inset; this cancels it so the first line
    /// sits on the first rule instead of floating above it.
    static let textEditorInset: CGFloat = 5

    /// Nearest legal top edge for a text box on ruled paper.
    static func snapTextTop(_ y: CGFloat) -> CGFloat {
        let base = ruleSpacing - textLineHeight - textEditorInset
        let index = max(0, (y - base) / ruleSpacing).rounded()
        return max(0, base + index * ruleSpacing)
    }
}
