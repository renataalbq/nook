import SwiftUI

/// Editable checklist with an editable title.
struct TodoListView: View {
    let data: TodoList
    let onChange: (TodoList) -> Void

    @State private var titleDraft = ""
    @FocusState private var focusedItemID: UUID?

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

            ForEach(Array(data.items.enumerated()), id: \.element.id) { index, item in
                TodoRow(item: item, isFocused: $focusedItemID) { updated in
                    var copy = data
                    guard let index = copy.items.firstIndex(where: { $0.id == item.id }) else { return }
                    copy.items[index] = updated
                    onChange(copy)
                } onDelete: {
                    deleteItem(item.id, focusPrevious: index > 0 ? data.items[index - 1].id : nil)
                } onSubmit: {
                    insertItem(after: item.id)
                } onDeleteEmpty: {
                    // TodoRow already checked its own live `draft` before
                    // calling this — re-checking `item.text` here used stale
                    // data: `item` is this render pass's snapshot, and it
                    // hadn't caught up with the character that was just
                    // deleted yet, so the guard silently failed.
                    guard data.items.count > 1 else { return }
                    deleteItem(item.id, focusPrevious: index > 0 ? data.items[index - 1].id : nil)
                }
            }

            Button {
                appendItem()
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
    }

    /// Enter used to mean "click the tiny + item button instead" — now it
    /// just adds the next row and hands it the caret, same as every other
    /// checklist app.
    private func insertItem(after id: UUID) {
        var copy = data
        guard let index = copy.items.firstIndex(where: { $0.id == id }) else { return }
        let new = TodoItem()
        copy.items.insert(new, at: index + 1)
        onChange(copy)
        focusedItemID = new.id
    }

    private func appendItem() {
        var copy = data
        let new = TodoItem()
        copy.items.append(new)
        onChange(copy)
        focusedItemID = new.id
    }

    /// Backspace on an empty row deletes it and hands the caret to the row
    /// above — the read side of the same "feels like one text flow" deal.
    /// Never drops the list's last row this way.
    private func deleteItem(_ id: UUID, focusPrevious previousID: UUID?) {
        var copy = data
        copy.items.removeAll { $0.id == id }
        onChange(copy)
        focusedItemID = previousID
    }
}

private struct TodoRow: View {
    let item: TodoItem
    var isFocused: FocusState<UUID?>.Binding
    let onChange: (TodoItem) -> Void
    let onDelete: () -> Void
    let onSubmit: () -> Void
    let onDeleteEmpty: () -> Void

    @State private var draft = ""

    var body: some View {
        HStack(spacing: 8) {
            checkbox

            TextField("", text: $draft)
                .textFieldStyle(.plain)
                .font(Theme.hand(13))
                .foregroundStyle(Theme.ink.opacity(item.done ? 0.45 : 1))
                .strikethrough(item.done, color: Theme.inkSoft)
                .focused(isFocused, equals: item.id)
                .onSubmit(onSubmit)
                .onKeyPress(.delete) {
                    guard draft.isEmpty else { return .ignored }
                    onDeleteEmpty()
                    return .handled
                }
                .onAppear { draft = item.text }
                .onChange(of: draft) { _, new in
                    var copy = item
                    copy.text = new
                    onChange(copy)
                }
                .onChange(of: item.text) { _, new in if new != draft { draft = new } }

            // Always on screen now, not hover-gated — a button that only
            // shows up if you happen to be hovering exactly the right spot
            // is a button people can't find.
            Button(action: onDelete) {
                LucideIcon(name: "circle-minus", size: 12)
                    .foregroundStyle(Theme.inkSoft.opacity(0.5))
            }
            .buttonStyle(.plain)
            .help("apagar item")
        }
        .padding(.horizontal, 3)
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
