import SwiftUI

/// Editable checklist with an editable title.
struct TodoListView: View {
    let data: TodoList
    let onChange: (TodoList) -> Void

    @State private var titleDraft = ""
    @State private var isHovering = false

    private var doneCount: Int { data.items.filter(\.done).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                TextField("título", text: $titleDraft)
                    .textFieldStyle(.plain)
                    .font(Theme.title(16))
                    .foregroundStyle(Theme.ink)
                    .onAppear { titleDraft = data.title }
                    .onChange(of: titleDraft) { _, new in
                        var copy = data
                        copy.title = new
                        onChange(copy)
                    }
                    .onChange(of: data.title) { _, new in if new != titleDraft { titleDraft = new } }

                Spacer(minLength: 4)

                if !data.items.isEmpty {
                    Text("\(doneCount)/\(data.items.count)")
                        .font(Theme.hand(11, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }

            ForEach(data.items) { item in
                TodoRow(item: item) { updated in
                    var copy = data
                    guard let index = copy.items.firstIndex(where: { $0.id == item.id }) else { return }
                    copy.items[index] = updated
                    onChange(copy)
                } onDelete: {
                    var copy = data
                    copy.items.removeAll { $0.id == item.id }
                    onChange(copy)
                }
            }

            if isHovering {
                Button {
                    var copy = data
                    copy.items.append(TodoItem())
                    onChange(copy)
                } label: {
                    HStack(spacing: 4) {
                        LucideIcon(name: "plus", size: 11)
                        Text("item")
                    }
                    .font(Theme.hand(11))
                    .foregroundStyle(Theme.inkSoft)
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }

            Spacer(minLength: 0)
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                .fill(Theme.paper.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous)
                        .stroke(Theme.blush.border.opacity(0.9), lineWidth: 1)
                )
        )
        .onHover { isHovering = $0 }
    }
}

private struct TodoRow: View {
    let item: TodoItem
    let onChange: (TodoItem) -> Void
    let onDelete: () -> Void

    @State private var draft = ""
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            checkbox

            TextField("", text: $draft)
                .textFieldStyle(.plain)
                .font(Theme.hand(13))
                .foregroundStyle(Theme.ink.opacity(item.done ? 0.45 : 1))
                .strikethrough(item.done, color: Theme.inkSoft)
                .onAppear { draft = item.text }
                .onChange(of: draft) { _, new in
                    var copy = item
                    copy.text = new
                    onChange(copy)
                }
                .onChange(of: item.text) { _, new in if new != draft { draft = new } }

            if isHovering {
                Button(action: onDelete) {
                    LucideIcon(name: "circle-minus", size: 12)
                        .foregroundStyle(Theme.inkSoft.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 3)
        .onHover { isHovering = $0 }
    }

    /// Filled rounded square with a white check when done, an outlined one
    /// otherwise — matches the prototype's pill-shaped boxes instead of the
    /// plain system checkbox glyph.
    private var checkbox: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(item.done ? Theme.accent : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(item.done ? Color.clear : Theme.inkSoft.opacity(0.35), lineWidth: 1.5)
            )
            .overlay {
                if item.done {
                    LucideIcon(name: "check", size: 11)
                        .foregroundStyle(Color.white)
                }
            }
            .frame(width: 19, height: 19)
            .contentShape(Rectangle())
            .onTapGesture {
                var copy = item
                copy.done.toggle()
                onChange(copy)
            }
    }
}
