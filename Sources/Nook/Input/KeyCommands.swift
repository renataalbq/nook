import Foundation
import AppKit
import UniformTypeIdentifiers

/// Watches for Delete and Escape at the window level.
///
/// SwiftUI's `.onKeyPress` needs `.focusable()`, which paints an accent focus
/// ring around the whole sheet and swallows clicks. A local event monitor gets
/// the same keys without touching the view's hit testing or its looks.
@MainActor
final class KeyCommands {
    private var monitor: Any?

    func start(selection: CanvasSelection, store: LibraryStore) {
        guard monitor == nil else { return }
        // The monitor always fires on the main thread, which is what
        // `assumeIsolated` states so the AppKit calls inside stay legal.
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            MainActor.assumeIsolated { Self.handle(event, selection: selection, store: store) }
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    private static func handle(_ event: NSEvent, selection: CanvasSelection, store: LibraryStore) -> NSEvent? {
        // 51 = delete, 117 = forward delete, 53 = escape, 9 = v
        let isDelete = event.keyCode == 51 || event.keyCode == 117
        let isEscape = event.keyCode == 53
        let isPaste = event.keyCode == 9 && event.modifierFlags.contains(.command)
        guard isDelete || isEscape || isPaste else { return event }

        // While the caret is in a text box, these keys belong to the text.
        if NSApp.keyWindow?.firstResponder is NSTextView { return event }

        if isPaste {
            return pasteImage(into: store) ? nil : event
        }

        if isEscape {
            selection.itemID = nil
            return nil
        }

        guard let id = selection.itemID else { return event }
        store.deleteItem(id)
        selection.itemID = nil
        return nil
    }

    /// Cmd+V drops whatever picture is on the clipboard onto the page.
    /// Returns false when the clipboard holds nothing image-like, so the
    /// keystroke passes through untouched.
    private static func pasteImage(into store: LibraryStore) -> Bool {
        let pasteboard = NSPasteboard.general
        let types = [UTType.image.identifier, UTType.fileURL.identifier, UTType.url.identifier]
        guard pasteboard.canReadItem(withDataConformingToTypes: types) else { return false }

        let step = Double((store.selectedPage?.items.count ?? 0) % 8) * 26
        Task { @MainActor in
            guard let imported = await ImageImport.fromPasteboard(store: store) else { return }
            let width = 240.0
            store.addItem(CanvasItem(
                kind: .image(ImageBox(assetID: imported.assetID, aspect: imported.aspect)),
                at: CGPoint(x: 60 + step, y: 60 + step),
                size: CGSize(width: width, height: width / max(0.2, imported.aspect))
            ))
        }
        return true
    }
}
