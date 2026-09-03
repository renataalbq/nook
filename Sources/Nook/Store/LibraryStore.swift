import Foundation
import Observation
import CoreGraphics

/// Owns the library and writes it to disk. Every mutation goes through here so
/// there is exactly one place that knows how to save.
@Observable
final class LibraryStore {
    private(set) var library: Library
    /// When the debounced write last actually hit disk; drives the "salvo…" label.
    private(set) var lastSavedAt: Date?

    static var defaultFolder: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Nook", isDirectory: true)
    }

    private let fileURL: URL
    private let assetsURL: URL
    private var saveTask: Task<Void, Never>?

    /// `folder` is injectable so tests can run against a throwaway directory
    /// instead of the real Application Support library.
    init(folder: URL? = nil) {
        let folder = folder ?? Self.defaultFolder
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        self.fileURL = folder.appendingPathComponent("library.json")
        self.assetsURL = folder.appendingPathComponent("Assets", isDirectory: true)
        try? FileManager.default.createDirectory(at: assetsURL, withIntermediateDirectories: true)

        self.library = Self.load(from: fileURL, folder: folder)
        migrateLegacyTextBoxes()
    }

    /// Reads the library, and never destroys a file it could not understand.
    ///
    /// The old version fell straight back to a starter library and then saved
    /// it over the top, so one decoding slip wiped everything. Now an
    /// unreadable file is moved aside and kept.
    private static func load(from fileURL: URL, folder: URL) -> Library {
        guard let data = try? Data(contentsOf: fileURL) else { return .starter }

        if let decoded = try? JSONDecoder().decode(Library.self, from: data) {
            // Keep one known-good copy from before this session's edits.
            let backup = folder.appendingPathComponent("library-backup.json")
            try? FileManager.default.removeItem(at: backup)
            try? data.write(to: backup, options: .atomic)
            return decoded
        }

        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let quarantine = folder.appendingPathComponent("library-unreadable-\(stamp).json")
        try? FileManager.default.moveItem(at: fileURL, to: quarantine)
        return .starter
    }

    /// Boxes saved before rich text existed still decode as `.text`; lift them
    /// once on load so the rest of the app only ever sees `.richText`.
    private func migrateLegacyTextBoxes() {
        for nookIndex in library.nooks.indices {
            for pageIndex in library.nooks[nookIndex].pages.indices {
                for itemIndex in library.nooks[nookIndex].pages[pageIndex].items.indices {
                    if case .text(let string) = library.nooks[nookIndex].pages[pageIndex].items[itemIndex].kind {
                        library.nooks[nookIndex].pages[pageIndex].items[itemIndex].kind =
                            .richText(RichText(plain: string))
                    }
                }
            }
        }
    }

    // MARK: - Selection

    var selectedNook: Nook? {
        guard let id = library.selectedNookID else { return library.nooks.first }
        return library.nooks.first { $0.id == id } ?? library.nooks.first
    }

    var selectedPage: Page? {
        guard let nook = selectedNook else { return nil }
        guard let pageID = library.selectedPageIDs[nook.id] else { return nook.pages.first }
        return nook.pages.first { $0.id == pageID } ?? nook.pages.first
    }

    func selectNook(_ id: UUID) {
        library.selectedNookID = id
        scheduleSave()
    }

    func selectPage(_ id: UUID) {
        guard let nookID = selectedNook?.id else { return }
        library.selectedPageIDs[nookID] = id
        scheduleSave()
    }

    // MARK: - Nooks & pages

    func addNook() {
        let tint = TintName.allCases[library.nooks.count % TintName.allCases.count]
        let nook = Nook(name: "nook \(library.nooks.count + 1)", tint: tint)
        library.nooks.append(nook)
        library.selectedNookID = nook.id
        scheduleSave()
    }

    func renameNook(_ id: UUID, to name: String) {
        guard let index = library.nooks.firstIndex(where: { $0.id == id }) else { return }
        library.nooks[index].name = name.isEmpty ? library.nooks[index].name : name
        scheduleSave()
    }

    func deleteNook(_ id: UUID) {
        guard library.nooks.count > 1 else { return }
        library.nooks.removeAll { $0.id == id }
        library.selectedPageIDs[id] = nil
        if library.selectedNookID == id { library.selectedNookID = library.nooks.first?.id }
        scheduleSave()
    }

    func addPage() {
        guard let index = selectedNookIndex else { return }
        let page = Page(paper: library.nooks[index].pages.last?.paper ?? .grid)
        library.nooks[index].pages.append(page)
        library.selectedPageIDs[library.nooks[index].id] = page.id
        scheduleSave()
    }

    func deletePage(_ id: UUID) {
        guard let index = selectedNookIndex, library.nooks[index].pages.count > 1 else { return }
        library.nooks[index].pages.removeAll { $0.id == id }
        if library.selectedPageIDs[library.nooks[index].id] == id {
            library.selectedPageIDs[library.nooks[index].id] = library.nooks[index].pages.first?.id
        }
        scheduleSave()
    }

    func renamePage(_ id: UUID, to name: String) {
        guard let nookIndex = selectedNookIndex,
              let pageIndex = library.nooks[nookIndex].pages.firstIndex(where: { $0.id == id })
        else { return }
        library.nooks[nookIndex].pages[pageIndex].name = name
        scheduleSave()
    }

    /// Moves the page at `sourceID` to just before `destinationID` within the
    /// same nook. Dropping past the end (`destinationID == nil`) sends it last.
    func movePage(_ sourceID: UUID, before destinationID: UUID?) {
        guard let nookIndex = selectedNookIndex else { return }
        var pages = library.nooks[nookIndex].pages
        guard let sourceIndex = pages.firstIndex(where: { $0.id == sourceID }) else { return }
        let page = pages.remove(at: sourceIndex)

        if let destinationID, let destinationIndex = pages.firstIndex(where: { $0.id == destinationID }) {
            pages.insert(page, at: destinationIndex)
        } else {
            pages.append(page)
        }

        library.nooks[nookIndex].pages = pages
        scheduleSave()
    }

    func setSidebarCollapsed(_ collapsed: Bool) {
        library.sidebarCollapsed = collapsed
        scheduleSave()
    }

    func setPaper(_ style: PaperStyle) {
        mutatePage { page in
            page.paper = style
            guard style == .ruled else { return }
            for index in page.items.indices where page.items[index].kind.isText {
                page.items[index].y = Paper.snapTextTop(page.items[index].y)
            }
        }
    }

    // MARK: - Canvas items

    func addItem(_ item: CanvasItem) {
        let ruled = isRuled
        var placed = item
        placed.origin = Self.snapped(placed.origin, kind: placed.kind, ruled: ruled)
        mutatePage { $0.items.append(placed) }
    }

    func moveItem(_ id: UUID, to origin: CGPoint) {
        // Read the paper style up front. Doing it inside the mutation closure
        // reads `library` while it is already held inout, which trips Swift's
        // exclusive-access check and aborts the process.
        let ruled = isRuled
        mutateItem(id) { item in
            item.origin = Self.snapped(origin, kind: item.kind, ruled: ruled)
        }
    }

    private var isRuled: Bool { selectedPage?.paper == .ruled }

    /// On ruled paper, text sits on the rules. Widgets stay free.
    private static func snapped(_ origin: CGPoint, kind: ItemKind, ruled: Bool) -> CGPoint {
        guard kind.isText, ruled else { return origin }
        return CGPoint(x: origin.x, y: Paper.snapTextTop(origin.y))
    }

    func resizeItem(_ id: UUID, to size: CGSize) {
        mutateItem(id) { $0.size = CGSize(width: max(120, size.width), height: max(60, size.height)) }
    }

    func updateKind(_ id: UUID, to kind: ItemKind) {
        mutateItem(id) { $0.kind = kind }
    }

    func deleteItem(_ id: UUID) {
        mutatePage { $0.items.removeAll { $0.id == id } }
    }

    // MARK: - Assets

    func assetURL(for id: String) -> URL {
        assetsURL.appendingPathComponent(id)
    }

    /// Copies the picked file next to the library and hands back its stored name.
    /// Keeping our own copy means the page still renders after the original
    /// is moved, renamed or deleted.
    func importAsset(from source: URL) -> String? {
        let ext = source.pathExtension.isEmpty ? "png" : source.pathExtension.lowercased()
        let name = "\(UUID().uuidString).\(ext)"
        let destination = assetsURL.appendingPathComponent(name)
        do {
            try FileManager.default.copyItem(at: source, to: destination)
            return name
        } catch {
            return nil
        }
    }

    /// Same as `importAsset(from:)` but for bytes already in memory, such as a
    /// GIF pulled down from Tenor.
    func importAsset(data: Data, ext: String) -> String? {
        let name = "\(UUID().uuidString).\(ext)"
        do {
            try data.write(to: assetsURL.appendingPathComponent(name), options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    // MARK: - Pen

    func addStroke(_ stroke: Stroke) {
        mutatePage { $0.strokes.append(stroke) }
    }

    func undoStroke() {
        mutatePage { if !$0.strokes.isEmpty { $0.strokes.removeLast() } }
    }

    /// Rubs out whole strokes the swipe passes over. Erasing part of a stroke
    /// would mean splitting its point list, which is not worth the complexity here.
    func eraseStrokes(near point: CGPoint, radius: Double) {
        mutatePage { page in
            page.strokes.removeAll { stroke in
                stroke.points.contains { hypot($0.x - point.x, $0.y - point.y) <= radius }
            }
        }
    }

    func clearStrokes() {
        mutatePage { $0.strokes.removeAll() }
    }

    func setAppearance(_ mode: AppearanceMode) {
        library.appearance = mode
        scheduleSave()
    }

    /// Brings the item to the front so a freshly touched box is never buried.
    func raiseItem(_ id: UUID) {
        mutatePage { page in
            guard let index = page.items.firstIndex(where: { $0.id == id }),
                  index != page.items.count - 1 else { return }
            let item = page.items.remove(at: index)
            page.items.append(item)
        }
    }

    // MARK: - Plumbing

    private var selectedNookIndex: Int? {
        guard let id = selectedNook?.id else { return nil }
        return library.nooks.firstIndex { $0.id == id }
    }

    private func mutatePage(_ body: (inout Page) -> Void) {
        guard let nookIndex = selectedNookIndex,
              let pageID = selectedPage?.id,
              let pageIndex = library.nooks[nookIndex].pages.firstIndex(where: { $0.id == pageID })
        else { return }
        body(&library.nooks[nookIndex].pages[pageIndex])
        scheduleSave()
    }

    private func mutateItem(_ id: UUID, _ body: (inout CanvasItem) -> Void) {
        mutatePage { page in
            guard let index = page.items.firstIndex(where: { $0.id == id }) else { return }
            body(&page.items[index])
        }
    }

    /// Debounced so dragging a box does not hit the disk on every frame.
    private func scheduleSave() {
        saveTask?.cancel()
        let snapshot = library
        let url = fileURL
        saveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            guard let data = try? encoder.encode(snapshot) else { return }
            try? data.write(to: url, options: .atomic)
            self?.lastSavedAt = Date()
        }
    }
}
