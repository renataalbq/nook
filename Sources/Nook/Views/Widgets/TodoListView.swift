import SwiftUI

/// Editable checklist with an editable title.
struct TodoListView: View {
    let data: TodoList
    let onChange: (TodoList) -> Void

    @State private var titleDraft = ""
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            TextField("título", text: $titleDraft)
                .textFieldStyle(.plain)
                .font(Theme.hand(13, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Theme.blush.opacity(0.55))
                )
                .onAppear { titleDraft = data.title }
                .onChange(of: titleDraft) { _, new in
                    var copy = data
                    copy.title = new
                    onChange(copy)
                }
                .onChange(of: data.title) { _, new in if new != titleDraft { titleDraft = new } }

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
                    Label("item", systemImage: "plus")
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
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.paper.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.blush.opacity(0.9), lineWidth: 1)
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
        HStack(spacing: 6) {
            Image(systemName: item.done ? "checkmark.square.fill" : "square")
                .font(.system(size: 13))
                .foregroundStyle(item.done ? Theme.ink.opacity(0.7) : Theme.inkSoft.opacity(0.6))
                .onTapGesture {
                    var copy = item
                    copy.done.toggle()
                    onChange(copy)
                }

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
                    Image(systemName: "minus.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.inkSoft.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 3)
        .onHover { isHovering = $0 }
    }
}
