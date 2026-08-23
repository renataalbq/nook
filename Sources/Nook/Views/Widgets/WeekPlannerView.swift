import SwiftUI

/// A week of dated rows. Each row holds a written note and, when you want one,
/// its own checklist.
struct WeekPlannerView: View {
    let data: WeekPlanner
    let focus: EditorFocus
    let onChange: (WeekPlanner) -> Void
    /// Adding a checklist needs more room than the box has; the widget asks the
    /// canvas to grow rather than quietly clipping the new rows.
    let onGrowBy: (Double) -> Void

    private let noteHeight: CGFloat = 34
    private let todoBlockHeight: Double = 104

    var body: some View {
        VStack(spacing: 0) {
            header

            ForEach(Array(data.days.enumerated()), id: \.offset) { index, date in
                row(for: date, isLast: index == 6)
            }

            Spacer(minLength: 0)
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.paper.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.butter.opacity(0.95), lineWidth: 1)
                )
        )
    }

    private var header: some View {
        HStack(spacing: 4) {
            arrow("chevron.left") { onChange(data.shifted(by: -1)) }

            Text(data.title)
                .font(Theme.hand(12, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)

            arrow("chevron.right") { onChange(data.shifted(by: 1)) }
        }
        .padding(.bottom, 5)
    }

    private func arrow(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Theme.inkSoft)
                .frame(width: 16, height: 16)
        }
        .buttonStyle(.plain)
    }

    private func row(for date: Date, isLast: Bool) -> some View {
        DayRow(
            date: date,
            key: data.key(date),
            data: data,
            focus: focus,
            noteHeight: noteHeight,
            isLast: isLast,
            onChange: onChange,
            onToggleTodo: { key, adding in
                var copy = data
                copy.todos[key] = adding ? TodoList(title: "", items: [TodoItem()]) : nil
                onChange(copy)
                onGrowBy(adding ? todoBlockHeight : -todoBlockHeight)
            }
        )
    }
}

/// Split out so the hover state belongs to one row rather than the whole week.
private struct DayRow: View {
    let date: Date
    let key: String
    let data: WeekPlanner
    let focus: EditorFocus
    let noteHeight: CGFloat
    let isLast: Bool
    let onChange: (WeekPlanner) -> Void
    let onToggleTodo: (String, Bool) -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                VStack(spacing: -1) {
                    Text(dayNumber)
                        .font(Theme.hand(17, weight: .semibold))
                        .foregroundStyle(isToday ? Theme.water : Theme.ink)
                    Text(weekday)
                        .font(Theme.hand(9))
                        .foregroundStyle(Theme.inkSoft)
                }
                .frame(width: 30)
                .padding(.top, 2)

                VStack(alignment: .leading, spacing: 3) {
                    RichTextEditor(
                        value: Binding(
                            get: { data.notes[key] ?? RichText() },
                            set: { value in
                                var copy = data
                                copy.notes[key] = value
                                onChange(copy)
                            }
                        ),
                        lineSpacing: 2,
                        focus: focus
                    )
                    .frame(minHeight: noteHeight)

                    if let todo = data.todos[key] {
                        TodoListView(data: todo) { updated in
                            var copy = data
                            copy.todos[key] = updated
                            onChange(copy)
                        }
                    }
                }

                toggleButton
            }
            .padding(.vertical, 3)

            if !isLast {
                Rectangle()
                    .fill(Theme.ruleLine.opacity(0.8))
                    .frame(height: 1)
            }
        }
        .onHover { isHovering = $0 }
    }

    @ViewBuilder
    private var toggleButton: some View {
        let hasTodo = data.todos[key] != nil

        Button {
            onToggleTodo(key, !hasTodo)
        } label: {
            Image(systemName: hasTodo ? "checklist.checked" : "checklist")
                .font(.system(size: 10))
                .foregroundStyle(Theme.inkSoft.opacity(hasTodo ? 0.8 : 0.55))
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .opacity(isHovering || hasTodo ? 1 : 0)
        .help(hasTodo ? "tirar a listinha do dia" : "adicionar listinha ao dia")
        .padding(.top, 2)
    }

    private var dayNumber: String {
        String(Calendar(identifier: .gregorian).component(.day, from: date))
    }

    private var weekday: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).replacingOccurrences(of: ".", with: "").lowercased()
    }

    private var isToday: Bool {
        Calendar(identifier: .gregorian).isDateInToday(date)
    }
}
