import SwiftUI

/// A sticky note: one tint, a folded corner, an optional bold title and a
/// freeform body. The title is just the first line, styled like every other
/// widget heading — press return on an empty title to skip it and land
/// straight in the body, exactly like a note with no title at all.
struct PostItView: View {
    let data: PostIt
    let onChange: (PostIt) -> Void

    @State private var titleDraft = ""
    @State private var bodyDraft = ""
    @State private var isHovering = false
    @FocusState private var focusedField: Field?

    private enum Field { case title, body }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            TextField("", text: $titleDraft)
                .textFieldStyle(.plain)
                .font(Theme.title(14))
                .foregroundStyle(Theme.ink)
                .focused($focusedField, equals: .title)
                .onSubmit { focusedField = .body }
                .onAppear { titleDraft = data.title }
                .onChange(of: titleDraft) { _, new in
                    var copy = data
                    copy.title = new
                    onChange(copy)
                }
                .onChange(of: data.title) { _, new in if new != titleDraft { titleDraft = new } }

            TextEditor(text: $bodyDraft)
                .font(Theme.hand(13, weight: .medium))
                .foregroundStyle(Theme.ink)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($focusedField, equals: .body)
                // Backspacing into an empty body hands the caret back to the
                // title line — the same "merge into the line above" feel as
                // a normal paragraph break, without actually merging text.
                .onKeyPress(.delete) {
                    guard bodyDraft.isEmpty else { return .ignored }
                    focusedField = .title
                    return .handled
                }
                .onAppear { bodyDraft = data.body }
                .onChange(of: bodyDraft) { _, new in
                    var copy = data
                    copy.body = new
                    onChange(copy)
                }
                .onChange(of: data.body) { _, new in if new != bodyDraft { bodyDraft = new } }

            if isHovering {
                swatches
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.tint(data.tint).fill)
        .overlay(alignment: .bottomTrailing) {
            FoldedCorner()
                .fill(Theme.ink.opacity(0.12))
                .frame(width: 20, height: 20)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                .stroke(Theme.ink.opacity(0.08), lineWidth: 1)
        )
        .onHover { isHovering = $0 }
    }

    private var swatches: some View {
        HStack(spacing: 5) {
            ForEach(TintName.allCases) { tint in
                Button {
                    var copy = data
                    copy.tint = tint
                    onChange(copy)
                } label: {
                    Circle()
                        .fill(Theme.tint(tint).fill)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Theme.ink.opacity(data.tint == tint ? 0.6 : 0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// A small triangle in the bottom-right corner, suggesting a dog-eared page.
private struct FoldedCorner: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX - rect.width, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - rect.height))
        path.closeSubpath()
        return path
    }
}
