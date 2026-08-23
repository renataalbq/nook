import XCTest
@testable import Nook

/// Guards the one bug in this app that destroyed user data: adding a field to a
/// model made every older `library.json` fail to decode, and the app then
/// replaced it with a starter library.
///
/// Swift's synthesized `Codable` ignores property defaults — a missing key
/// throws `keyNotFound`. Each fixture below is a real historical shape of the
/// save file. They must all still decode.
final class SaveFileCompatibilityTests: XCTestCase {

    /// The very first schema: no strokes, no appearance, plain-text boxes.
    func testDecodesOriginalSchema() throws {
        let json = """
        {
          "nooks": [{
            "id": "\(UUID().uuidString)",
            "name": "2026",
            "tint": "blush",
            "pages": [{
              "id": "\(UUID().uuidString)",
              "paper": "grid",
              "items": [{
                "id": "\(UUID().uuidString)",
                "x": 80, "y": 80, "width": 340, "height": 130,
                "kind": { "text": { "_0": "oi" } }
              }]
            }]
          }],
          "selectedPageIDs": {}
        }
        """

        let library = try decode(json)
        XCTAssertEqual(library.nooks.count, 1)
        XCTAssertEqual(library.nooks[0].pages[0].items.count, 1)
        XCTAssertEqual(library.appearance, .system, "missing key must fall back to the default")
        XCTAssertTrue(library.nooks[0].pages[0].strokes.isEmpty)
    }

    /// The schema right before per-day checklists existed. This is the exact
    /// shape that used to wipe the library.
    func testDecodesWeekPlannerWithoutTodos() throws {
        let json = """
        {
          "nooks": [{
            "id": "\(UUID().uuidString)",
            "name": "2026",
            "tint": "sage",
            "pages": [{
              "id": "\(UUID().uuidString)",
              "paper": "ruled",
              "strokes": [],
              "items": [{
                "id": "\(UUID().uuidString)",
                "x": 40, "y": 40, "width": 340, "height": 400,
                "kind": { "week": { "_0": {
                  "start": 776000000,
                  "notes": { "2026-08-17": { "rtf": "", "plain": "gym" } }
                } } }
              }]
            }]
          }],
          "selectedPageIDs": {},
          "appearance": "dark"
        }
        """

        let library = try decode(json)
        let item = try XCTUnwrap(library.nooks.first?.pages.first?.items.first)
        guard case .week(let planner) = item.kind else {
            return XCTFail("expected a week planner, got \(item.kind)")
        }
        XCTAssertEqual(planner.notes["2026-08-17"]?.plain, "gym")
        XCTAssertTrue(planner.todos.isEmpty, "absent todos must default to empty, not throw")
    }

    /// A widget saved with only some of its fields present.
    func testDecodesPartialWidgets() throws {
        let json = """
        {
          "nooks": [{
            "id": "\(UUID().uuidString)",
            "name": "n",
            "pages": [{
              "id": "\(UUID().uuidString)",
              "items": [
                { "id": "\(UUID().uuidString)", "x": 1, "y": 1, "width": 200, "height": 90,
                  "kind": { "waterTrack": { "_0": { "goal": 8 } } } },
                { "id": "\(UUID().uuidString)", "x": 1, "y": 1, "width": 200, "height": 90,
                  "kind": { "todoList": { "_0": { "title": "hoje" } } } }
              ]
            }]
          }],
          "selectedPageIDs": {}
        }
        """

        let library = try decode(json)
        let items = try XCTUnwrap(library.nooks.first?.pages.first?.items)

        guard case .waterTrack(let water) = items[0].kind else { return XCTFail("expected water") }
        XCTAssertEqual(water.goal, 8)
        XCTAssertEqual(water.filled, 0)
        XCTAssertEqual(water.litersPerDrop, 0.35, accuracy: 0.0001)

        guard case .todoList(let todo) = items[1].kind else { return XCTFail("expected todo") }
        XCTAssertEqual(todo.title, "hoje")
        XCTAssertTrue(todo.items.isEmpty)
    }

    /// Whatever the app writes, it must be able to read back.
    func testRoundTripsCurrentSchema() throws {
        var library = Library.starter
        library.nooks[0].pages[0].items.append(
            CanvasItem(kind: .week(.current()), at: .zero)
        )
        library.nooks[0].pages[0].strokes = [
            Stroke(points: [CGPoint(x: 1, y: 2), CGPoint(x: 3, y: 4)], colorHex: 0xAABBCC, width: 3)
        ]

        let data = try JSONEncoder().encode(library)
        let restored = try JSONDecoder().decode(Library.self, from: data)

        XCTAssertEqual(restored.nooks.count, library.nooks.count)
        XCTAssertEqual(restored.nooks[0].pages[0].items.count, library.nooks[0].pages[0].items.count)
        XCTAssertEqual(restored.nooks[0].pages[0].strokes.first?.colorHex, 0xAABBCC)
    }

    private func decode(_ json: String) throws -> Library {
        try JSONDecoder().decode(Library.self, from: Data(json.utf8))
    }
}
