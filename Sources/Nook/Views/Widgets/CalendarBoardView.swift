import SwiftUI

/// Month grid. Clicking a day cycles: empty -> X -> O -> heart -> empty.
struct CalendarBoardView: View {
    let data: CalendarBoard
    let onChange: (CalendarBoard) -> Void

    private let weekdays = ["S", "T", "Q", "Q", "S", "S", "D"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        VStack(spacing: 5) {
            header

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, name in
                    Text(name)
                        .font(Theme.hand(9, weight: .medium))
                        .foregroundStyle(Theme.inkSoft.opacity(0.7))
                }

                ForEach(0..<data.leadingBlanks, id: \.self) { index in
                    Color.clear.frame(height: 22).id("blank\(index)")
                }

                ForEach(1...data.dayCount, id: \.self) { day in
                    dayCell(day)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.paper.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.lilac.opacity(0.9), lineWidth: 1)
                )
        )
    }

    private var header: some View {
        HStack(spacing: 4) {
            arrow("chevron.left") { onChange(data.shifted(by: -1)) }

            Text("\(data.monthName) \(String(data.year))")
                .font(Theme.hand(12, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)

            arrow("chevron.right") { onChange(data.shifted(by: 1)) }
        }
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

    private func dayCell(_ day: Int) -> some View {
        let mark = data.marks[data.key(day)]

        return ZStack {
            Text("\(day)")
                .font(Theme.hand(10))
                .foregroundStyle(Theme.inkSoft.opacity(mark == nil ? 0.85 : 0.35))

            if let mark {
                Image(systemName: mark.symbol)
                    .font(.system(size: mark == .circle ? 14 : 12, weight: .semibold))
                    .foregroundStyle(color(for: mark))
            }
        }
        .frame(height: 22)
        .contentShape(Rectangle())
        .onTapGesture {
            var copy = data
            let key = copy.key(day)
            copy.marks[key] = mark.map { $0.next } ?? .cross
            onChange(copy)
        }
    }

    private func color(for mark: DayMark) -> Color {
        switch mark {
        case .cross: return Color(red: 0.85, green: 0.45, blue: 0.42)
        case .circle: return Theme.water
        case .heart: return Color(red: 0.90, green: 0.55, blue: 0.62)
        }
    }
}
