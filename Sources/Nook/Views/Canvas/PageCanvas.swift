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

            // A single click on bare paper only clears the selection. A
            // double-click drops a text box exactly there — the dock is a
            // shortcut now, not the only way in. `onTapGesture` has no
            // location, so the double-click needs the spatial variant instead.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { deselect() }
                .simultaneousGesture(
                    SpatialTapGesture(count: 2).onEnded { value in
                        place(.richText(RichText()), at: value.location)
                    }
                )

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

            if page.items.isEmpty {
                emptyHint
                    .allowsHitTesting(false)
            }

            DrawingLayer(
                strokes: page.strokes,
                pen: pen,
                onFinish: { store.addStroke($0) },
                onErase: { store.eraseStrokes(near: $0, radius: pen.eraserRadius) }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                .stroke(borderColor, lineWidth: isTargeted || pen.isActive ? 2 : 1)
        )
        .shadow(color: Theme.cardShadow, radius: 14, y: 6)
        // One drop handler for everything: template chips, decor chips,
        // files, and images dragged straight out of a browser.
        .onDrop(of: [.nookTemplate, .nookDecor] + ImageImport.acceptedTypes, isTargeted: $isTargeted) { providers, location in
            handleDrop(providers, at: location)
        }
    }

    /// Shown only while the page is genuinely blank — the moment the first
    /// box lands, this never comes back.
    private var emptyHint: some View {
        VStack(spacing: 10) {
            LucideIcon(name: "mouse-pointer-click", size: 20)
                .foregroundStyle(Theme.accent)
                .frame(width: 52, height: 52)
                .background(Circle().fill(Theme.accent.opacity(0.14)))

            VStack(spacing: 4) {
                Text("duplo clique pra escrever")
                    .font(Theme.hand(17, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("a caixa nasce exatamente onde você clicou")
                    .font(Theme.hand(12))
                    .foregroundStyle(Theme.inkSoft)
            }

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Theme.inkSoft.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                .frame(width: 220, height: 70)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

        if let provider = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.nookDecor.identifier)
        }) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.nookDecor.identifier) { data, _ in
                guard let data, let drop = try? JSONDecoder().decode(DecorDrop.self, from: data) else { return }
                Task { @MainActor in
                    place(.decor(Decor(kind: drop.kind)), at: location)
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
        if isTargeted { return Theme.water.accent }
        if pen.isActive {
            return pen.isEraser
                ? Theme.inkSoft.opacity(0.7)
                : Color(nsColor: NSColor(hex: pen.colorHex)).opacity(0.7)
        }
        return Theme.ruleLine.opacity(0.7)
    }
}
