import Foundation

/// Water intake. `goal` is how many drops the widget shows.
struct WaterTrack: Codable, Hashable {
    var goal: Int = 5
    var filled: Int = 0
    var litersPerDrop: Double = 0.35

    var totalLiters: Double { Double(filled) * litersPerDrop }
}

/// A sticky note: one tint, an optional bold title line, freeform body text.
/// Reuses `TintName` rather than a raw hex so it gets the same light/dark
/// deepening every other pastel surface already has, for free.
struct PostIt: Codable, Hashable {
    var tint: TintName = .butter
    /// Empty when the note has no title — pressing return on an empty title
    /// field skips straight to the body.
    var title: String = ""
    var body: String = ""
}

struct TodoItem: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var text: String = ""
    var done: Bool = false
}

struct TodoList: Codable, Hashable {
    var title: String = "to-do"
    var items: [TodoItem] = [TodoItem(), TodoItem(), TodoItem()]
}

/// What a marked day shows.
enum DayMark: String, Codable, Hashable, CaseIterable {
    case cross, circle, heart

    /// Lucide icon name — see `Design/Lucide/LucideIcon.swift`.
    var symbol: String {
        switch self {
        case .cross: return "x"
        case .circle: return "circle"
        case .heart: return "heart"
        }
    }

    /// Click order: none -> cross -> circle -> heart -> none.
    var next: DayMark? {
        switch self {
        case .cross: return .circle
        case .circle: return .heart
        case .heart: return nil
        }
    }
}

/// A month view with per-day marks. Marks are keyed by full date so paging
/// between months never loses them.
struct CalendarBoard: Codable, Hashable {
    var year: Int
    var month: Int
    var marks: [String: DayMark] = [:]

    func key(_ day: Int) -> String { String(format: "%04d-%02d-%02d", year, month, day) }

    static func current() -> CalendarBoard {
        let parts = Calendar.current.dateComponents([.year, .month], from: Date())
        return CalendarBoard(year: parts.year ?? 2026, month: parts.month ?? 1)
    }

    var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        let index = max(1, min(12, month)) - 1
        return (formatter.standaloneMonthSymbols?[index] ?? "").lowercased()
    }

    /// Weekday of the 1st, Monday-first (0 = Monday).
    var leadingBlanks: Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        guard let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { return 0 }
        return (calendar.component(.weekday, from: first) + 5) % 7
    }

    var dayCount: Int {
        let calendar = Calendar(identifier: .gregorian)
        guard let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: first) else { return 30 }
        return range.count
    }

    func shifted(by delta: Int) -> CalendarBoard {
        let total = (year * 12) + (month - 1) + delta
        return CalendarBoard(year: total / 12, month: (total % 12) + 1, marks: marks)
    }
}

/// A picture or GIF on the page. Only the asset id is stored; the file itself
/// lives beside the library so the JSON stays small and copyable.
struct ImageBox: Codable, Hashable {
    var assetID: String?
    /// Remembered so a freshly dropped picture can size itself to its own shape.
    var aspect: Double = 1.5
}

/// Seven dated rows you can write into. The dates are the point; there is no
/// month grid here.
struct WeekPlanner: Codable, Hashable {
    /// Always a Monday.
    var start: Date
    /// Notes keyed by yyyy-MM-dd so shifting weeks never loses what you wrote.
    var notes: [String: RichText] = [:]
    /// Optional checklist per day, keyed the same way.
    var todos: [String: TodoList] = [:]

    static func current() -> WeekPlanner {
        WeekPlanner(start: Self.mondayOfWeek(containing: Date()))
    }

    static func mondayOfWeek(containing date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    var days: [Date] {
        let calendar = Calendar(identifier: .gregorian)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    func key(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func shifted(by weeks: Int) -> WeekPlanner {
        let calendar = Calendar(identifier: .gregorian)
        let moved = calendar.date(byAdding: .day, value: weeks * 7, to: start) ?? start
        return WeekPlanner(start: moved, notes: notes, todos: todos)
    }

    /// "agosto 2026 · semana 34"
    var title: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMMM yyyy"

        let week = calendar.component(.weekOfYear, from: start)
        return "\(formatter.string(from: start).lowercased()) · semana \(week)"
    }
}
