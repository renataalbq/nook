import SwiftUI
import AppKit

/// Styling controls for whichever text box holds the caret.
struct FormatBar: View {
    let focus: EditorFocus

    @State private var fontIndex = 0
    @State private var size: CGFloat = Paper.textSize

    var body: some View {
        HStack(spacing: 6) {
            group {
                traitButton("bold", "B", weight: .bold) { TextFormatting.toggleTrait(.boldFontMask, in: $0) }
                traitButton("italic", "I", italic: true) { TextFormatting.toggleTrait(.italicFontMask, in: $0) }
                traitButton("underline", "U", underline: true) { TextFormatting.toggleUnderline(in: $0) }
                traitButton("strikethrough", "S", strike: true) { TextFormatting.toggleStrikethrough(in: $0) }
            }

            group {
                Picker("", selection: $fontIndex) {
                    ForEach(Array(TextFormatting.fonts.enumerated()), id: \.offset) { index, entry in
                        Text(entry.label).tag(index)
                    }
                }
                .labelsHidden()
                .frame(width: 118)
                .onChange(of: fontIndex) { _, index in
                    run { TextFormatting.setFamily(TextFormatting.fonts[index].name, in: $0) }
                }

                Picker("", selection: $size) {
                    ForEach(TextFormatting.sizes, id: \.self) { value in
                        Text("\(Int(value))").tag(value)
                    }
                }
                .labelsHidden()
                .frame(width: 62)
                .onChange(of: size) { _, value in
                    run { TextFormatting.setSize(value, in: $0) }
                }
            }

            group {
                ForEach(TextFormatting.palette, id: \.self) { hex in
                    swatch(hex, shape: Circle()) {
                        run { TextFormatting.setColor(hex, in: $0) }
                    }
                }
            }

            group {
                Image(systemName: "highlighter")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkSoft)

                ForEach(TextFormatting.highlights, id: \.self) { hex in
                    swatch(hex, shape: RoundedRectangle(cornerRadius: 4)) {
                        run { TextFormatting.setHighlight(hex, in: $0) }
                    }
                }

                Button {
                    run { TextFormatting.setHighlight(nil, in: $0) }
                } label: {
                    Image(systemName: "slash.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.inkSoft)
                }
                .buttonStyle(.plain)
                .help("tirar marca-texto")
            }

            Button {
                run { TextFormatting.clearFormatting(in: $0) }
            } label: {
                Image(systemName: "eraser")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(width: 26, height: 24)
                    .background(capsuleBackground)
            }
            .buttonStyle(.plain)
            .help("limpar formatação")

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.chrome)
                .shadow(color: Theme.cardShadow, radius: 8, y: 3)
        )
    }

    // MARK: - Pieces

    private func group<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 4) { content() }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Theme.desk.opacity(0.7))
            )
    }

    private func traitButton(
        _ id: String,
        _ label: String,
        weight: Font.Weight = .regular,
        italic: Bool = false,
        underline: Bool = false,
        strike: Bool = false,
        action: @escaping (NSTextView) -> Void
    ) -> some View {
        Button {
            run(action)
        } label: {
            Text(label)
                .font(.system(size: 12, weight: weight, design: .serif))
                .italic(italic)
                .underline(underline)
                .strikethrough(strike)
                .foregroundStyle(Theme.ink)
                .frame(width: 24, height: 22)
                .background(capsuleBackground)
        }
        .buttonStyle(.plain)
    }

    private func swatch<S: Shape>(_ hex: UInt32, shape: S, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            shape
                .fill(Color(nsColor: NSColor(hex: hex)))
                .frame(width: 16, height: 16)
                .overlay(shape.stroke(Theme.inkSoft.opacity(0.25), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private var capsuleBackground: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Theme.chrome)
    }

    /// Every command needs a focused text view; without one there is nothing to style.
    private func run(_ action: (NSTextView) -> Void) {
        guard let textView = focus.textView else { return }
        action(textView)
    }
}
