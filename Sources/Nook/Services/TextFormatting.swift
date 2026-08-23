import AppKit

/// Text styling commands applied to whatever the caret is in.
///
/// With a selection, the change hits the selected runs. With an empty caret it
/// goes into typing attributes, so the next thing typed comes out styled.
enum TextFormatting {
    static let fonts: [(label: String, name: String?)] = [
        ("Redondinha", nil),
        ("Bradley Hand", "BradleyHandITCTT-Bold"),
        ("Noteworthy", "Noteworthy-Light"),
        ("Marker Felt", "MarkerFelt-Thin"),
        ("Snell", "SnellRoundhand"),
        ("Serifada", "NewYork-Regular"),
        ("Mono", "SFMono-Regular")
    ]

    static let sizes: [CGFloat] = [11, 13, 15, 18, 22, 28, 36]

    /// Pastels first; the darker inks at the end are for body copy.
    static let palette: [UInt32] = [
        0xE59AAF, 0xF0B7C4, 0xF6CBA0, 0xF3E1A0,
        0xB6D8B0, 0x9FC9D8, 0xB3AEDC, 0xD9B8E0,
        0x8A7F76, 0x433D38
    ]

    static let highlights: [UInt32] = [
        0xF9D8DF, 0xFBE9C6, 0xDCEFD3, 0xD3E7F2, 0xE6DDF3
    ]

    // MARK: - Commands

    static func toggleTrait(_ trait: NSFontTraitMask, in textView: NSTextView) {
        mutateFonts(in: textView) { font in
            let manager = NSFontManager.shared
            let hasTrait = manager.traits(of: font).contains(trait)
            return hasTrait
                ? manager.convert(font, toNotHaveTrait: trait)
                : manager.convert(font, toHaveTrait: trait)
        }
    }

    static func toggleUnderline(in textView: NSTextView) {
        toggleIntAttribute(.underlineStyle, in: textView)
    }

    static func toggleStrikethrough(in textView: NSTextView) {
        toggleIntAttribute(.strikethroughStyle, in: textView)
    }

    static func setSize(_ size: CGFloat, in textView: NSTextView) {
        mutateFonts(in: textView) { font in
            NSFontManager.shared.convert(font, toSize: size)
        }
    }

    static func setFamily(_ postScriptName: String?, in textView: NSTextView) {
        mutateFonts(in: textView) { font in
            guard let postScriptName else {
                return roundedFont(ofSize: font.pointSize)
            }
            return NSFont(name: postScriptName, size: font.pointSize) ?? font
        }
    }

    static func setColor(_ hex: UInt32, in textView: NSTextView) {
        setAttribute(.foregroundColor, value: NSColor(hex: hex), in: textView)
    }

    static func setHighlight(_ hex: UInt32?, in textView: NSTextView) {
        if let hex {
            setAttribute(.backgroundColor, value: NSColor(hex: hex), in: textView)
        } else {
            removeAttribute(.backgroundColor, in: textView)
        }
    }

    static func clearFormatting(in textView: NSTextView) {
        forEachTarget(textView) { storage, range in
            storage.setAttributes([
                .font: roundedFont(ofSize: Paper.textSize),
                .foregroundColor: NSColor.labelColor
            ], range: range)
        }
        textView.typingAttributes[.font] = roundedFont(ofSize: Paper.textSize)
        textView.typingAttributes[.foregroundColor] = NSColor.labelColor
        textView.typingAttributes[.underlineStyle] = 0
        textView.typingAttributes[.strikethroughStyle] = 0
        textView.typingAttributes[.backgroundColor] = nil
    }

    static func roundedFont(ofSize size: CGFloat) -> NSFont {
        let base = NSFont.systemFont(ofSize: size)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded),
              let font = NSFont(descriptor: descriptor, size: size)
        else { return base }
        return font
    }

    /// RTF bakes the ink colour in at save time, so text written in light mode
    /// would stay near-black on a dark sheet. Anything that reads as plain ink
    /// is handed back to the system label colour; picked colours are left alone.
    static func normalizeDefaultInk(in storage: NSMutableAttributedString) {
        let full = NSRange(location: 0, length: storage.length)
        storage.enumerateAttribute(.foregroundColor, in: full) { value, range, _ in
            guard let color = (value as? NSColor)?.usingColorSpace(.sRGB) else { return }
            let isNeutral = color.saturationComponent < 0.18
            let isDarkOrLight = color.brightnessComponent < 0.40 || color.brightnessComponent > 0.90
            if isNeutral && isDarkOrLight {
                storage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)
            }
        }
    }

    // MARK: - Plumbing

    private static func mutateFonts(in textView: NSTextView, transform: (NSFont) -> NSFont) {
        forEachTarget(textView) { storage, range in
            storage.enumerateAttribute(.font, in: range) { value, subrange, _ in
                let font = (value as? NSFont) ?? roundedFont(ofSize: Paper.textSize)
                storage.addAttribute(.font, value: transform(font), range: subrange)
            }
        }
        let typing = (textView.typingAttributes[.font] as? NSFont) ?? roundedFont(ofSize: Paper.textSize)
        textView.typingAttributes[.font] = transform(typing)
    }

    private static func setAttribute(_ key: NSAttributedString.Key, value: Any, in textView: NSTextView) {
        forEachTarget(textView) { storage, range in
            storage.addAttribute(key, value: value, range: range)
        }
        textView.typingAttributes[key] = value
    }

    private static func removeAttribute(_ key: NSAttributedString.Key, in textView: NSTextView) {
        forEachTarget(textView) { storage, range in
            storage.removeAttribute(key, range: range)
        }
        textView.typingAttributes[key] = nil
    }

    private static func toggleIntAttribute(_ key: NSAttributedString.Key, in textView: NSTextView) {
        let current = (textView.typingAttributes[key] as? Int) ?? 0
        let next = current == 0 ? NSUnderlineStyle.single.rawValue : 0
        setAttribute(key, value: next, in: textView)
    }

    /// Runs `body` over the selection, or marks the change as typing-only when
    /// there is nothing selected.
    private static func forEachTarget(_ textView: NSTextView, _ body: (NSMutableTextStorage, NSRange) -> Void) {
        guard let storage = textView.textStorage else { return }
        let ranges = textView.selectedRanges
            .map(\.rangeValue)
            .filter { $0.length > 0 }
        guard !ranges.isEmpty else { return }

        storage.beginEditing()
        for range in ranges {
            body(storage, range)
        }
        storage.endEditing()
        textView.didChangeText()
    }
}

/// `NSTextStorage` is what `textStorage` hands back; the alias keeps signatures short.
typealias NSMutableTextStorage = NSTextStorage
