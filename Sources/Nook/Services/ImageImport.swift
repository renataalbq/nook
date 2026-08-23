import Foundation
import AppKit
import UniformTypeIdentifiers

/// Gets a picture into the library from wherever it came: the clipboard, a
/// drag out of a browser, a dropped file, or a bare URL.
///
/// GIF data is checked before the generic image types on purpose — asking the
/// pasteboard for a plain image flattens an animation to one frame.
enum ImageImport {
    struct Imported {
        let assetID: String
        let aspect: Double
    }

    static let acceptedTypes: [UTType] = [.gif, .png, .jpeg, .tiff, .heic, .webP, .image, .fileURL, .url]

    // MARK: - Clipboard

    static func fromPasteboard(_ pasteboard: NSPasteboard = .general, store: LibraryStore) async -> Imported? {
        if let data = pasteboard.data(forType: .init(UTType.gif.identifier)) {
            return save(data, ext: "gif", in: store)
        }

        if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL], let url = urls.first {
            if url.isFileURL {
                return fromFile(url, store: store)
            }
            return await fromRemote(url, store: store)
        }

        for type in [UTType.png, .jpeg, .tiff] {
            if let data = pasteboard.data(forType: .init(type.identifier)) {
                return save(data, ext: type.preferredFilenameExtension ?? "png", in: store)
            }
        }

        if let text = pasteboard.string(forType: .string),
           let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
           url.scheme?.hasPrefix("http") == true {
            return await fromRemote(url, store: store)
        }

        return nil
    }

    // MARK: - Drag and drop

    static func fromProviders(_ providers: [NSItemProvider], store: LibraryStore) async -> Imported? {
        for provider in providers {
            // GIF first so a dragged animation stays animated.
            if let data = await loadData(provider, type: .gif) {
                return save(data, ext: "gif", in: store)
            }
            if let url = await loadURL(provider), url.isFileURL {
                if let result = fromFile(url, store: store) { return result }
            }
            for type in [UTType.png, .jpeg, .tiff, .image] {
                if let data = await loadData(provider, type: type) {
                    return save(data, ext: type.preferredFilenameExtension ?? "png", in: store)
                }
            }
            // Browsers hand over a web URL rather than the bytes.
            if let url = await loadURL(provider), !url.isFileURL {
                if let result = await fromRemote(url, store: store) { return result }
            }
        }
        return nil
    }

    // MARK: - Sources

    private static func fromFile(_ url: URL, store: LibraryStore) -> Imported? {
        guard let id = store.importAsset(from: url) else { return nil }
        return Imported(assetID: id, aspect: aspect(of: NSImage(contentsOf: url)))
    }

    private static func fromRemote(_ url: URL, store: LibraryStore) async -> Imported? {
        guard let (data, response) = try? await URLSession.shared.data(from: url) else { return nil }
        let ext = response.suggestedFilename
            .flatMap { URL(fileURLWithPath: $0).pathExtension.lowercased() }
            .flatMap { $0.isEmpty ? nil : $0 }
            ?? (url.pathExtension.isEmpty ? "png" : url.pathExtension.lowercased())
        return save(data, ext: ext, in: store)
    }

    private static func save(_ data: Data, ext: String, in store: LibraryStore) -> Imported? {
        guard NSImage(data: data) != nil, let id = store.importAsset(data: data, ext: ext) else { return nil }
        return Imported(assetID: id, aspect: aspect(of: NSImage(data: data)))
    }

    private static func aspect(of image: NSImage?) -> Double {
        guard let image, image.size.height > 0 else { return 1.5 }
        return image.size.width / image.size.height
    }

    // MARK: - NSItemProvider bridging

    private static func loadData(_ provider: NSItemProvider, type: UTType) async -> Data? {
        guard provider.hasItemConformingToTypeIdentifier(type.identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: type.identifier) { data, _ in
                continuation.resume(returning: data)
            }
        }
    }

    private static func loadURL(_ provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                continuation.resume(returning: url)
            }
        }
    }
}
