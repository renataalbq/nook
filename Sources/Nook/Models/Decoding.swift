import Foundation

/// Swift's synthesized `Codable` ignores property default values: a key missing
/// from the JSON throws `keyNotFound` instead of falling back. That turns every
/// new field into a save-file breaker, so each model below decodes by hand and
/// treats an absent key as "use the default".
extension KeyedDecodingContainer {
    func value<T: Decodable>(_ key: Key, _ fallback: T) -> T {
        guard let decoded = try? decodeIfPresent(T.self, forKey: key) else { return fallback }
        return decoded ?? fallback
    }
}

extension WaterTrack {
    private enum Keys: String, CodingKey { case goal, filled, litersPerDrop }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        self.init(
            goal: c.value(.goal, 5),
            filled: c.value(.filled, 0),
            litersPerDrop: c.value(.litersPerDrop, 0.35)
        )
    }
}

extension TodoItem {
    private enum Keys: String, CodingKey { case id, text, done }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        self.init(id: c.value(.id, UUID()), text: c.value(.text, ""), done: c.value(.done, false))
    }
}

extension TodoList {
    private enum Keys: String, CodingKey { case title, items }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        self.init(title: c.value(.title, "to-do"), items: c.value(.items, []))
    }
}

extension CalendarBoard {
    private enum Keys: String, CodingKey { case year, month, marks }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        self.init(year: c.value(.year, 2026), month: c.value(.month, 1), marks: c.value(.marks, [:]))
    }
}

extension WeekPlanner {
    private enum Keys: String, CodingKey { case start, notes, todos }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        self.init(
            start: c.value(.start, Self.mondayOfWeek(containing: Date())),
            notes: c.value(.notes, [:]),
            todos: c.value(.todos, [:])
        )
    }
}

extension ImageBox {
    private enum Keys: String, CodingKey { case assetID, aspect }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        self.init(assetID: c.value(.assetID, nil), aspect: c.value(.aspect, 1.5))
    }
}

extension Stroke {
    private enum Keys: String, CodingKey { case id, points, colorHex, width }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        self.init(
            id: c.value(.id, UUID()),
            points: c.value(.points, []),
            colorHex: c.value(.colorHex, 0xE59AAF),
            width: c.value(.width, 2.5)
        )
    }
}

extension RichText {
    private enum Keys: String, CodingKey { case rtf, plain }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        self.init(rtf: c.value(.rtf, Data()), plain: c.value(.plain, ""))
    }
}

extension CanvasItem {
    private enum Keys: String, CodingKey { case id, x, y, width, height, kind }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        // Assigned field by field: the custom `init(kind:at:size:)` in the
        // declaration suppresses the memberwise initialiser.
        self.id = c.value(.id, UUID())
        self.x = c.value(.x, 40)
        self.y = c.value(.y, 40)
        self.width = c.value(.width, 260)
        self.height = c.value(.height, 90)
        self.kind = try c.decode(ItemKind.self, forKey: Keys.kind)
    }
}

extension Page {
    private enum Keys: String, CodingKey { case id, name, paper, items, strokes }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        self.init(
            id: c.value(.id, UUID()),
            name: c.value(.name, ""),
            paper: c.value(.paper, .grid),
            items: c.value(.items, []),
            strokes: c.value(.strokes, [])
        )
    }
}

extension Nook {
    private enum Keys: String, CodingKey { case id, name, tint, pages }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        self.init(
            id: c.value(.id, UUID()),
            name: c.value(.name, "nook"),
            tint: c.value(.tint, .blush),
            pages: c.value(.pages, [Page()])
        )
    }
}

extension Library {
    private enum Keys: String, CodingKey { case nooks, selectedNookID, selectedPageIDs, appearance, sidebarCollapsed }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        self.init(
            nooks: c.value(.nooks, []),
            selectedNookID: c.value(.selectedNookID, nil),
            selectedPageIDs: c.value(.selectedPageIDs, [:]),
            appearance: c.value(.appearance, .system),
            sidebarCollapsed: c.value(.sidebarCollapsed, false)
        )
    }
}
