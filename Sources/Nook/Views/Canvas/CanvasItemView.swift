import SwiftUI

/// A single box on the page: drag to move, corner handle to resize, hover for delete.
struct CanvasItemView: View {
    let item: CanvasItem
    let paper: PaperStyle
    let isSelected: Bool
    let store: LibraryStore
    let focus: EditorFocus
    let onSelect: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var resizeDelta: CGSize = .zero
    @State private var isHovering = false

    private var liveSize: CGSize {
        CGSize(
            width: max(120, item.width + resizeDelta.width),
            height: max(60, item.height + resizeDelta.height)
        )
    }

    var body: some View {
        content
            .frame(width: liveSize.width, height: liveSize.height, alignment: .topLeading)
            .overlay(alignment: .bottomTrailing) { resizeHandle }
            .overlay(alignment: .topTrailing) { deleteButton }
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.inkSoft.opacity(outlineOpacity), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .padding(-4)
            )
            .position(
                x: item.x + dragOffset.width + liveSize.width / 2,
                y: item.y + dragOffset.height + liveSize.height / 2
            )
            .onHover { isHovering = $0 }
            .gesture(moveGesture, including: isTextItem ? .subviews : .all)
    }

    private var isTextItem: Bool { item.kind.isText }

    /// The outline is a selection cue, not decoration: an unselected box the
    /// pointer is not over shows nothing at all. Text boxes skip it entirely —
    /// their own grab-strip dots and the format popover already say "this is
    /// the one", and a dashed rectangle around live text just adds noise.
    private var outlineOpacity: Double {
        if isTextItem { return 0 }
        if isSelected { return 0.45 }
        if isHovering { return 0.35 }
        return 0
    }

    /// The text view swallows drags so it can place the caret, so text boxes
    /// move by this strip instead. It always occupies space; only its dots fade in.
    private var grabStrip: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(Theme.inkSoft.opacity(isHovering ? 0.55 : 0.2))
                    .frame(width: 3, height: 3)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 13)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .gesture(moveGesture)
    }

    @ViewBuilder
    private var content: some View {
        switch item.kind {
        case .text(let string):
            richTextBox(RichText(plain: string))
        case .richText(let value):
            richTextBox(value)
        case .waterTrack(let data):
            WaterTrackView(data: data) { store.updateKind(item.id, to: .waterTrack($0)) }
        case .todoList(let data):
            TodoListView(data: data) { store.updateKind(item.id, to: .todoList($0)) }
        case .postIt(let data):
            PostItView(data: data) { store.updateKind(item.id, to: .postIt($0)) }
        case .mood(let data):
            MoodTrackerView(data: data) { store.updateKind(item.id, to: .mood($0)) }
        case .calendar(let data):
            CalendarBoardView(data: data) { store.updateKind(item.id, to: .calendar($0)) }
        case .week(let data):
            WeekPlannerView(
                data: data,
                focus: focus,
                onChange: { store.updateKind(item.id, to: .week($0)) },
                onGrowBy: { delta in
                    store.resizeItem(item.id, to: CGSize(width: item.width, height: item.height + delta))
                }
            )
        case .image(let data):
            ImageBoxView(
                data: data,
                store: store,
                onChange: { store.updateKind(item.id, to: .image($0)) },
                onResize: { store.resizeItem(item.id, to: $0) }
            )
        }
    }

    /// Text boxes need the body free for the caret, so they move by their edges only.
    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in dragOffset = value.translation }
            .onEnded { value in
                dragOffset = .zero
                onSelect()
                store.raiseItem(item.id)
                store.moveItem(item.id, to: CGPoint(
                    x: max(0, item.x + value.translation.width),
                    y: max(0, item.y + value.translation.height)
                ))
            }
    }

    private var resizeHandle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Theme.inkSoft.opacity(isHovering ? 0.5 : 0))
            .frame(width: 12, height: 12)
            .offset(x: 6, y: 6)
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { resizeDelta = $0.translation }
                    .onEnded { value in
                        resizeDelta = .zero
                        store.resizeItem(item.id, to: CGSize(
                            width: item.width + value.translation.width,
                            height: item.height + value.translation.height
                        ))
                    }
            )
    }

    @ViewBuilder
    private var deleteButton: some View {
        if isHovering {
            Button {
                store.deleteItem(item.id)
            } label: {
                LucideIcon(name: "circle-x", size: 15)
                    .foregroundStyle(Theme.inkSoft.opacity(0.6))
            }
            .buttonStyle(.plain)
            .offset(x: 7, y: -7)
        }
    }

    private func richTextBox(_ value: RichText) -> some View {
        VStack(spacing: 0) {
            grabStrip
            editor(value)
        }
    }

    private func editor(_ value: RichText) -> some View {
        RichTextEditor(
            value: Binding(
                get: { value },
                set: { store.updateKind(item.id, to: .richText($0)) }
            ),
            lineSpacing: paper == .ruled ? Paper.ruledLineSpacing : 2,
            focus: focus
        )
    }
}
