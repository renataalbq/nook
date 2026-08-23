import SwiftUI
import UniformTypeIdentifiers

/// The sheet plus everything on it: boxes, pen marks, drops from the palette.
struct PageCanvas: View {
    let page: Page
    let store: LibraryStore
    let focus: EditorFocus
    let pen: PenSettings
    let selection: CanvasSelection

    @State private var isTargeted = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            PaperBackground(style: page.paper)

            // Clicking bare paper only clears the selection; boxes come from
            // the dock, so a stray double-click no longer litters the page.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { deselect() }

            ForEach(page.items) { item in
                CanvasItemView(
                    item: item,
                    paper: page.paper,
                    isSelected: selection.itemID == item.id,
                    store: store,
                    focus: focus,
                    onSelect: { select(item) }
                )
                .simultaneousGesture(TapGesture().onEnded {
                    // Tapping a widget takes the caret out of whatever text box
                    // had it, so the format bar stops pointing at stale text.
                    if item.kind.isText { selection.itemID = item.id } else { select(item) }
                })
            }
            .allowsHitTesting(!pen.isActive)

            DrawingLayer(
                strokes: page.strokes,
                pen: pen,
                onFinish: { store.addStroke($0) },
                onErase: { store.eraseStrokes(near: $0, radius: pen.eraserRadius) }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(borderColor, lineWidth: isTargeted || pen.isActive ? 2 : 1)
        )
        .shadow(color: Theme.cardShadow, radius: 14, y: 6)
        // One drop handler for everything: template chips, files, and images
        // dragged straight out of a browser.
        .onDrop(of: [.nookTemplate] + ImageImport.acceptedTypes, isTargeted: $isTargeted) { providers, location in
            handleDrop(providers, at: location)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider], at location: CGPoint) -> Bool {
        if let provider = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.nookTemplate.identifier)
        }) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.nookTemplate.identifier) { data, _ in
                guard let data, let drop = try? JSONDecoder().decode(TemplateDrop.self, from: data) else { return }
                Task { @MainActor in
                    place(drop.kind.makeKind(), at: location)
                }
            }
            return true
        }

        Task { @MainActor in
            guard let imported = await ImageImport.fromProviders(providers, store: store) else { return }
            place(.image(ImageBox(assetID: imported.assetID, aspect: imported.aspect)), at: location)
        }
        return true
    }

    /// Drops land centred on the cursor rather than hanging off it.
    private func place(_ kind: ItemKind, at location: CGPoint) {
        let size = kind.defaultSize
        let origin = CGPoint(
            x: max(0, location.x - size.width / 2),
            y: max(0, location.y - size.height / 2)
        )
        store.addItem(CanvasItem(kind: kind, at: origin, size: size))
    }

    /// Selecting takes the caret out of any text box, so Delete removes the box
    /// itself instead of a character.
    private func select(_ item: CanvasItem) {
        selection.itemID = item.id
        blurText()
    }

    /// Clears both the dashed outline and the caret.
    private func deselect() {
        selection.itemID = nil
        blurText()
    }

    private func blurText() {
        NSApp.keyWindow?.makeFirstResponder(nil)
        focus.textView = nil
    }

    private var borderColor: Color {
        if isTargeted { return Theme.water }
        if pen.isActive {
            return pen.isEraser
                ? Theme.inkSoft.opacity(0.7)
                : Color(nsColor: NSColor(hex: pen.colorHex)).opacity(0.7)
        }
        return Theme.ruleLine.opacity(0.7)
    }
}
