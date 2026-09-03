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

        /// The format bar lives in a popover that only exists while there is
        /// something selected to style — an empty caret has nothing to show it
        /// for, and closes whatever was open.
        func textViewDidChangeSelection(_ notification: Notification) {
            guard !isApplying, let textView = notification.object as? NSTextView else { return }

            let range = textView.selectedRange()
            guard range.length > 0, let rect = Self.boundingRect(for: range, in: textView) else {
                FormatPopoverController.shared.dismiss()
                return
            }
            FormatPopoverController.shared.present(for: textView, focus: parent.focus, anchor: rect)
        }

        /// Selection rect in `textView`'s own coordinate space — what
        /// `NSPopover.positioningRect` expects. Goes through screen
        /// coordinates rather than `layoutManager`/`textContainer` directly:
        /// those return `nil` on a TextKit-2-backed view (the default since
        /// macOS 12), which silently killed the popover entirely. `firstRect`
        /// works regardless of which TextKit generation is behind the view.
        private static func boundingRect(for range: NSRange, in textView: NSTextView) -> NSRect? {
            guard let window = textView.window else { return nil }
            let screenRect = textView.firstRect(forCharacterRange: range, actualRange: nil)
            guard screenRect.isEmpty == false else { return nil }
            let windowRect = window.convertFromScreen(screenRect)
            return textView.convert(windowRect, from: nil)
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

    /// Losing the caret means the selection is gone too, even if AppKit
    /// never fires a selection-changed notification for it.
    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result { FormatPopoverController.shared.dismiss() }
        return result
    }
}

/// Owns the single floating format popover the app ever shows at once — only
/// one text view can hold a non-empty selection at a time, so one instance
/// covers every box on the page.
///
/// `.transient` behaviour closes it on any click outside its content, which
/// is what makes it "disappear on defocus" for free; the explicit `dismiss()`
/// calls above cover the cases that aren't an outside click (selection
/// collapsing to a caret, losing first responder).
@MainActor
final class FormatPopoverController {
    static let shared = FormatPopoverController()

    private let popover: NSPopover = {
        let popover = NSPopover()
        popover.behavior = .transient
        return popover
    }()

    private init() {}

    func present(for textView: NSTextView, focus: EditorFocus, anchor rect: NSRect) {
        if popover.contentViewController == nil {
            let host = NSHostingController(rootView: FormatBar(focus: focus))
            // Without this, NSPopover can't learn the SwiftUI content's actual
            // fitting size and falls back to stretching across the anchor
            // window's width instead of hugging the format bar's own width.
            host.sizingOptions = [.preferredContentSize]
            popover.contentViewController = host
        }

        if popover.isShown {
            popover.positioningRect = rect
        } else {
            // NSTextView is a flipped view (origin top-left), so `.minY` of
            // its own bounds-space rect is the visually *upper* edge —
            // `.maxY` anchored the popover below the selection instead of
            // above it.
            popover.show(relativeTo: rect, of: textView, preferredEdge: .minY)
        }
    }

    func dismiss() {
        guard popover.isShown else { return }
        popover.close()
    }
}
