import SwiftUI
import AppKit
import Observation

/// Tracks which text box currently has the caret so the format bar knows what to style.
@Observable
final class EditorFocus {
    weak var textView: NSTextView?
}

/// NSTextView wrapped for SwiftUI. SwiftUI's own TextEditor is plain-string only,
/// and Nook needs per-run fonts, sizes and colours.
struct RichTextEditor: NSViewRepresentable {
    @Binding var value: RichText
    var lineSpacing: CGFloat
    var focus: EditorFocus

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NookTextView()
        textView.delegate = context.coordinator
        textView.focus = focus
        textView.isRichText = true
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 2, height: 2)
        textView.textColor = .labelColor
        textView.font = NSFont.systemFont(ofSize: Paper.textSize)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.textContainer?.widthTracksTextView = true

        let scroll = NSScrollView()
        scroll.documentView = textView
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = false
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true

        context.coordinator.apply(value, to: textView, lineSpacing: lineSpacing)
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let textView = scroll.documentView as? NSTextView else { return }
        context.coordinator.parent = self
        if let nook = textView as? NookTextView { nook.focus = focus }

        // Only push back when the model changed underneath us; otherwise the
        // caret jumps to the end on every keystroke.
        if context.coordinator.lastPushed != value.rtf {
            context.coordinator.apply(value, to: textView, lineSpacing: lineSpacing)
        } else if context.coordinator.lastLineSpacing != lineSpacing {
            context.coordinator.applyLineSpacing(lineSpacing, to: textView)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor
        var lastPushed: Data?
        var lastLineSpacing: CGFloat?
        private var isApplying = false

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func apply(_ value: RichText, to textView: NSTextView, lineSpacing: CGFloat) {
            isApplying = true
            defer { isApplying = false }

            let incoming = NSMutableAttributedString(attributedString: value.attributed)
            TextFormatting.normalizeDefaultInk(in: incoming)
            textView.textStorage?.setAttributedString(incoming)
            lastPushed = value.rtf
            applyLineSpacing(lineSpacing, to: textView)
        }

        func applyLineSpacing(_ spacing: CGFloat, to textView: NSTextView) {
            lastLineSpacing = spacing
            guard let storage = textView.textStorage else { return }
            let style = NSMutableParagraphStyle()
            style.lineSpacing = spacing
            let full = NSRange(location: 0, length: storage.length)
            storage.addAttribute(.paragraphStyle, value: style, range: full)
            textView.defaultParagraphStyle = style
            textView.typingAttributes[.paragraphStyle] = style
        }

        func textDidChange(_ notification: Notification) {
            guard !isApplying,
                  let textView = notification.object as? NSTextView,
                  let storage = textView.textStorage
            else { return }
            let value = RichText(attributed: storage)
            lastPushed = value.rtf
            parent.value = value
        }
    }
}

/// Reports focus so the format bar can target the active box.
final class NookTextView: NSTextView {
    var focus: EditorFocus?

    override func becomeFirstResponder() -> Bool {
        focus?.textView = self
        return super.becomeFirstResponder()
    }
}
