import XCTest
@testable import Nook

/// Covers the loading rules that decide whether a user's notes survive.
final class LibraryStoreTests: XCTestCase {
    private var folder: URL!

    override func setUpWithError() throws {
        folder = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("NookTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: folder)
    }

    @MainActor
    func testLoadsAnExistingLibrary() throws {
        var saved = Library.starter
        saved.nooks[0].name = "diário"
        try write(saved)

        let store = LibraryStore(folder: folder)
        XCTAssertEqual(store.library.nooks.first?.name, "diário")
    }

    /// The data-loss bug: an unreadable file used to be replaced by a starter
    /// library. It must now be kept, under a new name.
    @MainActor
    func testUnreadableFileIsQuarantinedNotDestroyed() throws {
        let garbage = Data("{ not json at all".utf8)
        try garbage.write(to: libraryURL)

        _ = LibraryStore(folder: folder)

        XCTAssertFalse(
            FileManager.default.fileExists(atPath: libraryURL.path),
            "the unreadable file should have been moved aside"
        )

        let quarantined = try contents().filter { $0.hasPrefix("library-unreadable-") }
        XCTAssertEqual(quarantined.count, 1)

        let recovered = try Data(contentsOf: folder.appendingPathComponent(quarantined[0]))
        XCTAssertEqual(recovered, garbage, "quarantined bytes must be untouched")
    }

    @MainActor
    func testKeepsABackupOfTheLastGoodLoad() throws {
        var saved = Library.starter
        saved.nooks[0].name = "antes"
        try write(saved)

        _ = LibraryStore(folder: folder)

        let backup = folder.appendingPathComponent("library-backup.json")
        let restored = try JSONDecoder().decode(Library.self, from: Data(contentsOf: backup))
        XCTAssertEqual(restored.nooks.first?.name, "antes")
    }

    @MainActor
    func testStartsFreshWhenThereIsNoFile() throws {
        let store = LibraryStore(folder: folder)
        XCTAssertFalse(store.library.nooks.isEmpty)
        XCTAssertNotNil(store.selectedPage)
    }

    /// Legacy plain-text boxes are lifted to rich text exactly once, on load.
    @MainActor
    func testMigratesLegacyTextBoxes() throws {
        var saved = Library.starter
        saved.nooks[0].pages[0].items = [CanvasItem(kind: .text("oi"), at: .zero)]
        try write(saved)

        let store = LibraryStore(folder: folder)
        let kind = try XCTUnwrap(store.library.nooks.first?.pages.first?.items.first?.kind)
        guard case .richText(let value) = kind else {
            return XCTFail("expected rich text, got \(kind)")
        }
        XCTAssertEqual(value.plain, "oi")
    }

    // MARK: - Helpers

    private var libraryURL: URL { folder.appendingPathComponent("library.json") }

    private func write(_ library: Library) throws {
        try JSONEncoder().encode(library).write(to: libraryURL)
    }

    private func contents() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: folder.path)
    }
}
