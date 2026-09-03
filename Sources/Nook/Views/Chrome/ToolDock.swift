import SwiftUI

/// The single bar at the foot of the page: text stays out with a label,
/// everything else — templates, stickers, the pen — collapses behind its
/// own icon until tapped, the same floating dark pill as the format
/// popover. Every template can be clicked to drop straight in or dragged
/// onto the sheet to choose the spot.
struct ToolDock: View {
    let store: LibraryStore
    let pen: PenSettings

    /// Keeps click-to-add from stacking every new box on the same spot.
    @State private var dropCount = 0
    @State private var showGifPicker = false
    @State private var showDecor = false
    @State private var showTemplates = false

    var body: some View {
        HStack(spacing: 3) {
            chip(.text)

            templatesSection

            decorSection

            Rectangle().fill(Theme.popoverInk.opacity(0.15)).frame(width: 1, height: 16)

            penSection
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Theme.popover)
                .shadow(color: Theme.cardShadow, radius: 10, y: 4)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: pen.isActive)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: pen.isEraser)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showDecor)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showTemplates)
    }

    // MARK: - Templates
    //
    // Text is the one thing you reach for constantly, so it stays out on its
    // own with a label. Everything else — semana/listinha/água/post-it/mood —
    // collapses behind a single icon until you actually want one, same as
    // stickers and the pen. Only one section (templates/stickers/pen) stays
    // open at a time so the dock doesn't sprawl across the whole window.

    private var templatesSection: some View {
        HStack(spacing: 4) {
            Button {
                showTemplates.toggle()
                if showTemplates {
                    showDecor = false
                    pen.isActive = false
                }
            } label: {
                LucideIcon(name: "grid-3x3", size: 14)
                    .foregroundStyle(showTemplates ? Color.white : Theme.popoverInk.opacity(0.85))
                    .frame(width: 30, height: 26)
                    .background(Capsule().fill(showTemplates ? Theme.accent.opacity(0.6) : Color.clear))
            }
            .buttonStyle(.plain)
            .help("templates")

            if showTemplates {
                HStack(spacing: 4) {
                    ForEach(TemplateKind.allCases.filter { $0 != .text }) { kind in
                        chip(kind)
                    }
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Theme.popoverInk.opacity(0.08)))
            }
        }
    }

    /// Text is the primary action — click or arraste-most, so it wears the
    /// accent pill the way the selected tool always does. Everything else
    /// sits plain on the dark bar.
    private func chip(_ kind: TemplateKind) -> some View {
        let isPrimary = kind == .text

        return HStack(spacing: 5) {
            LucideIcon(name: kind.symbol, size: 13)
            Text(kind.label)
                .font(Theme.hand(11, weight: .medium))
        }
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .foregroundStyle(isPrimary ? Color.white : Theme.popoverInk.opacity(0.85))
        .padding(.horizontal, isPrimary ? 12 : 9)
        .padding(.vertical, 7)
        .background(Capsule().fill(isPrimary ? Theme.accent : Color.clear))
        .contentShape(Capsule())
        .onTapGesture { add(kind) }
        .draggable(TemplateDrop(kind: kind)) { dragPreview(kind) }
        .help("\(kind.label) — clique ou arraste para a folha")
    }

    private func dragPreview(_ kind: TemplateKind) -> some View {
        HStack(spacing: 5) {
            LucideIcon(name: kind.symbol, size: 13)
            Text(kind.label)
        }
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .font(Theme.hand(11, weight: .medium))
        .foregroundStyle(Color.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Theme.popover))
    }

    private func add(_ kind: TemplateKind) {
        let step = CGFloat(dropCount % 8) * 26
        store.addItem(CanvasItem(kind: kind.makeKind(), at: CGPoint(x: 60 + step, y: 60 + step)))
        dropCount += 1
    }

    // MARK: - Stickers & washi tape
    //
    // These expand inline rather than into a popover or sheet, same reason
    // the old template palette did: dragging out of a popover/sheet cancels
    // the drag, and clicking-to-place needs the chips to still be on-screen.
    // GIF/image search is the one thing here that doesn't need dragging —
    // you pick from results inside the sheet — so it stays a sheet.

    private var decorSection: some View {
        HStack(spacing: 5) {
            Button {
                showDecor.toggle()
                if showDecor {
                    showTemplates = false
                    pen.isActive = false
                }
            } label: {
                LucideIcon(name: "sparkles", size: 14)
                    .foregroundStyle(showDecor ? Color.white : Theme.popoverInk.opacity(0.85))
                    .frame(width: 30, height: 26)
                    .background(Capsule().fill(showDecor ? Theme.accent.opacity(0.6) : Color.clear))
            }
            .buttonStyle(.plain)
            .help("figurinhas e washi tape")

            if showDecor {
                HStack(spacing: 4) {
                    ForEach(DecorKind.allCases) { kind in
                        decorChip(kind)
                    }

                    Rectangle().fill(Theme.popoverInk.opacity(0.15)).frame(width: 1, height: 16)

                    Button {
                        showGifPicker = true
                    } label: {
                        LucideIcon(name: "image-plus", size: 14)
                            .foregroundStyle(Theme.popoverInk.opacity(0.85))
                            .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .help("buscar imagens e GIFs")
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Theme.popoverInk.opacity(0.08)))
            }
        }
        .sheet(isPresented: $showGifPicker) {
            GifPicker(store: store) { assetID, aspect in
                place(assetID: assetID, aspect: aspect)
            }
        }
    }

    private func decorChip(_ kind: DecorKind) -> some View {
        Group {
            if kind.isWashi {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Theme.accent.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .stroke(Theme.popoverInk.opacity(0.4), lineWidth: 1)
                    )
                    .frame(width: 20, height: 12)
            } else {
                LucideIcon(name: kind.symbol, size: 15)
                    .foregroundStyle(Theme.popoverInk.opacity(0.9))
            }
        }
        .frame(width: 26, height: 26)
        .contentShape(Rectangle())
        .onTapGesture { addDecor(kind) }
        .draggable(DecorDrop(kind: kind)) {
            LucideIcon(name: kind.isWashi ? "square" : kind.symbol, size: 16)
                .foregroundStyle(Color.white)
                .padding(8)
                .background(Circle().fill(Theme.popover))
        }
        .help("\(kind.label) — clique ou arraste para a folha")
    }

    private func addDecor(_ kind: DecorKind) {
        let step = CGFloat(dropCount % 8) * 26
        store.addItem(CanvasItem(kind: .decor(Decor(kind: kind)), at: CGPoint(x: 60 + step, y: 60 + step)))
        dropCount += 1
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

    // MARK: - Pen

    private var penSection: some View {
        HStack(spacing: 8) {
            Button {
                pen.isActive.toggle()
                if pen.isActive {
                    showTemplates = false
                    showDecor = false
                } else {
                    pen.isEraser = false
                }
            } label: {
                LucideIcon(name: "pencil", size: 15)
                    .foregroundStyle(pen.isActive && !pen.isEraser ? Color.white : Theme.popoverInk.opacity(0.85))
                    .frame(width: 30, height: 26)
                    .background(
                        Capsule().fill(pen.isActive && !pen.isEraser
                            ? Color(nsColor: NSColor(hex: pen.colorHex))
                            : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .help("desenhar à mão")

            if pen.isActive {
                Rectangle().fill(Theme.popoverInk.opacity(0.15)).frame(width: 1, height: 16)

                eraserToggle

                if pen.isEraser {
                    ForEach(PenSettings.widths, id: \.self) { value in
                        eraserSizeButton(value)
                    }
                }

                Rectangle().fill(Theme.popoverInk.opacity(0.15)).frame(width: 1, height: 16)

                if !pen.isEraser {
                    ForEach(PenSettings.colors, id: \.self) { hex in
                        Button {
                            pen.colorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(nsColor: NSColor(hex: hex)))
                                .frame(width: 15, height: 15)
                                .overlay(
                                    Circle().stroke(Theme.popoverInk.opacity(pen.colorHex == hex ? 0.9 : 0.2), lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Rectangle().fill(Theme.popoverInk.opacity(0.15)).frame(width: 1, height: 16)

                if !pen.isEraser {
                    ForEach(PenSettings.widths, id: \.self) { value in
                        Button {
                            pen.width = value
                        } label: {
                            Circle()
                                .fill(Theme.popoverInk.opacity(pen.width == value ? 0.9 : 0.3))
                                .frame(width: value + 4, height: value + 4)
                                .frame(width: 18, height: 18)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Rectangle().fill(Theme.popoverInk.opacity(0.15)).frame(width: 1, height: 16)

                Button(action: store.undoStroke) {
                    LucideIcon(name: "undo-2", size: 13)
                        .foregroundStyle(Theme.popoverInk.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("desfazer traço")

                Button(action: store.clearStrokes) {
                    Text("limpar")
                        .font(Theme.hand(11))
                        .foregroundStyle(Theme.popoverInk.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("apagar todos os traços da página")
            }
        }
    }

    private var eraserToggle: some View {
        Button {
            pen.isEraser.toggle()
        } label: {
            LucideIcon(name: "eraser", size: 15)
                .foregroundStyle(pen.isEraser ? Color.white : Theme.popoverInk.opacity(0.85))
                .frame(width: 30, height: 26)
                .background(Capsule().fill(pen.isEraser ? Theme.inkSoft : Color.clear))
        }
        .buttonStyle(.plain)
        .help("borracha — passe por cima do traço")
    }

    private func eraserSizeButton(_ value: Double) -> some View {
        Button {
            pen.eraserRadius = value * 5
        } label: {
            Circle()
                .strokeBorder(Theme.popoverInk.opacity(pen.eraserRadius == value * 5 ? 0.9 : 0.3), lineWidth: 1.5)
                .frame(width: value + 6, height: value + 6)
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
    }
}
