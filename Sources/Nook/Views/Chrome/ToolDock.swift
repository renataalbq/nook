import SwiftUI

/// The single bar at the foot of the page: every template, stickers and the
/// pen — all flat and always visible on one dark pill, the same floating
/// language as the format popover. Every template can be clicked to drop
/// straight in or dragged onto the sheet to choose the spot.
struct ToolDock: View {
    let store: LibraryStore
    let pen: PenSettings

    /// Keeps click-to-add from stacking every new box on the same spot.
    @State private var dropCount = 0
    @State private var showGifPicker = false

    var body: some View {
        HStack(spacing: 3) {
            ForEach(TemplateKind.allCases) { kind in
                chip(kind)
            }

            stickersChip

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
    }

    // MARK: - Templates

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

    // MARK: - Stickers

    private var stickersChip: some View {
        Button {
            showGifPicker = true
        } label: {
            HStack(spacing: 5) {
                LucideIcon(name: "sparkles", size: 13)
                Text("stickers")
                    .font(Theme.hand(11, weight: .medium))
            }
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(Theme.popoverInk.opacity(0.85))
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
        .help("buscar figurinhas e imagens")
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

    // MARK: - Pen

    private var penSection: some View {
        HStack(spacing: 8) {
            Button {
                pen.isActive.toggle()
                if !pen.isActive { pen.isEraser = false }
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
