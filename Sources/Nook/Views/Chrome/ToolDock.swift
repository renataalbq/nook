import SwiftUI

/// The single bar at the foot of the page: text, templates and the pen.
///
/// Every template can be dragged onto the sheet or clicked to drop straight in,
/// so nothing here needs a popover — dragging out of one cancels the drag.
struct ToolDock: View {
    let store: LibraryStore
    let pen: PenSettings

    /// Keeps click-to-add from stacking every new box on the same spot.
    @State private var dropCount = 0
    @State private var showTemplates = false
    @State private var showGifPicker = false

    var body: some View {
        HStack(spacing: 8) {
            textButton
            templateSection
            penSection
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Theme.chrome)
                .shadow(color: Theme.cardShadow, radius: 10, y: 4)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: pen.isActive)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showTemplates)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: pen.isEraser)
    }

    // MARK: - Text

    /// Text earns its own button: it is the thing you reach for most, and
    /// burying it behind the templates icon costs a click every time.
    private var textButton: some View {
        chipButton(symbol: "textformat", isOn: false) {
            add(.text)
        }
        .draggable(TemplateDrop(kind: .text)) {
            chip(.text).opacity(0.9)
        }
        .help("caixa de texto — clique ou arraste")
    }

    private func chipButton(symbol: String, isOn: Bool, tint: Color = Theme.water, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isOn ? Color.white : Theme.ink)
                .frame(width: 30, height: 26)
                .background(Capsule().fill(isOn ? tint : Theme.desk.opacity(0.75)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stickers

    /// Lives with the templates rather than in the dock's top row: it inserts
    /// something into the page like the others do.
    private var gifChip: some View {
        Button {
            showGifPicker = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .medium))
                Text("Imagem / GIF")
                    .font(Theme.hand(11, weight: .medium))
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Theme.chrome)
                    .overlay(Capsule().stroke(Theme.ruleLine.opacity(0.8), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .help("buscar figurinhas e GIFs")
        .sheet(isPresented: $showGifPicker) {
            GifPicker(store: store) { assetID, aspect in
                place(assetID: assetID, aspect: aspect)
            }
        }
    }

    private func place(assetID: String, aspect: Double) {
        let step = CGFloat(dropCount % 8) * 26
        let width = 240.0
        store.addItem(CanvasItem(
            kind: .image(ImageBox(assetID: assetID, aspect: aspect)),
            at: CGPoint(x: 60 + step, y: 60 + step),
            size: CGSize(width: width, height: width / max(0.2, aspect))
        ))
        dropCount += 1
    }

    // MARK: - Templates

    /// The chips expand inline rather than into a popover: dragging out of a
    /// popover dismisses it and cancels the drag with it.
    private var templateSection: some View {
        HStack(spacing: 8) {
            Button {
                showTemplates.toggle()
                if showTemplates { pen.isActive = false }
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(showTemplates ? Color.white : Theme.ink)
                    .frame(width: 30, height: 26)
                    .background(
                        Capsule().fill(showTemplates ? Theme.water : Theme.desk.opacity(0.75))
                    )
            }
            .buttonStyle(.plain)
            .help("templates")

            if showTemplates {
                HStack(spacing: 5) {
                    ForEach(TemplateKind.allCases.filter { $0 != .text }) { kind in
                        tool(kind)
                    }
                    gifChip
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Theme.desk.opacity(0.75))
                )
            }
        }
    }

    private func tool(_ kind: TemplateKind) -> some View {
        chip(kind)
            .onTapGesture { add(kind) }
            .draggable(TemplateDrop(kind: kind)) { chip(kind).opacity(0.9) }
            .help("\(kind.label) — clique ou arraste para a folha")
    }

    private func chip(_ kind: TemplateKind) -> some View {
        HStack(spacing: 5) {
            Image(systemName: kind.symbol)
                .font(.system(size: 11, weight: .medium))
            Text(kind.label)
                .font(Theme.hand(11, weight: .medium))
        }
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Theme.chrome)
                .overlay(Capsule().stroke(Theme.ruleLine.opacity(0.8), lineWidth: 1))
        )
    }

    private func eraserSizeButton(_ value: Double) -> some View {
        Button {
            pen.eraserRadius = value * 5
        } label: {
            Circle()
                .strokeBorder(Theme.inkSoft.opacity(pen.eraserRadius == value * 5 ? 0.85 : 0.3), lineWidth: 1.5)
                .frame(width: value + 6, height: value + 6)
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
    }

    private func add(_ kind: TemplateKind) {
        let step = CGFloat(dropCount % 8) * 26
        store.addItem(CanvasItem(kind: kind.makeKind(), at: CGPoint(x: 60 + step, y: 60 + step)))
        dropCount += 1
    }

    // MARK: - Pen

    private var penSection: some View {
        HStack(spacing: 8) {
            Button {
                pen.isActive.toggle()
                if pen.isActive {
                    showTemplates = false
                } else {
                    pen.isEraser = false
                }
            } label: {
                Image(systemName: "pencil.tip")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(pen.isActive && !pen.isEraser ? Color.white : Theme.ink)
                    .frame(width: 30, height: 26)
                    .background(
                        Capsule().fill(pen.isActive && !pen.isEraser
                            ? Color(nsColor: NSColor(hex: pen.colorHex))
                            : Theme.desk.opacity(0.75))
                    )
            }
            .buttonStyle(.plain)
            .help("desenhar à mão")

            if pen.isActive {
                Divider().frame(height: 18)

                chipButton(symbol: "eraser", isOn: pen.isEraser, tint: Theme.inkSoft) {
                    pen.isEraser.toggle()
                }
                .help("borracha — passe por cima do traço")

                if pen.isEraser {
                    ForEach(PenSettings.widths, id: \.self) { value in
                        eraserSizeButton(value)
                    }
                }

                Divider().frame(height: 18)

                if !pen.isEraser {
                    ForEach(PenSettings.colors, id: \.self) { hex in
                        Button {
                            pen.colorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(nsColor: NSColor(hex: hex)))
                                .frame(width: 15, height: 15)
                                .overlay(
                                    Circle().stroke(Theme.ink.opacity(pen.colorHex == hex ? 0.8 : 0.15), lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider().frame(height: 18)

                if !pen.isEraser {
                    ForEach(PenSettings.widths, id: \.self) { value in
                        Button {
                            pen.width = value
                        } label: {
                            Circle()
                                .fill(Theme.ink.opacity(pen.width == value ? 0.85 : 0.3))
                                .frame(width: value + 4, height: value + 4)
                                .frame(width: 18, height: 18)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider().frame(height: 18)

                Button(action: store.undoStroke) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.inkSoft)
                }
                .buttonStyle(.plain)
                .help("desfazer traço")

                Button(action: store.clearStrokes) {
                    Text("limpar")
                        .font(Theme.hand(11))
                        .foregroundStyle(Theme.inkSoft)
                }
                .buttonStyle(.plain)
                .help("apagar todos os traços da página")
            }
        }
    }
}
