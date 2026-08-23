import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// A picture or GIF on the page. Empty until a file is picked.
struct ImageBoxView: View {
    let data: ImageBox
    let store: LibraryStore
    let onChange: (ImageBox) -> Void
    let onResize: (CGSize) -> Void

    var body: some View {
        Group {
            if let id = data.assetID {
                AnimatedImage(url: store.assetURL(for: id))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                placeholder
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { pick() }
        .contextMenu {
            Button("escolher arquivo…") { pick() }
        }
    }

    private var placeholder: some View {
        VStack(spacing: 5) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 20))
                .foregroundStyle(Theme.inkSoft.opacity(0.7))
            Text("clique 2x para escolher")
                .font(Theme.hand(11))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.desk.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Theme.inkSoft.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
        )
    }

    private func pick() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .gif, .heic, .tiff, .webP]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let id = store.importAsset(from: url) else { return }

        var copy = data
        copy.assetID = id
        if let image = NSImage(contentsOf: url), image.size.height > 0 {
            copy.aspect = image.size.width / image.size.height
        }
        onChange(copy)

        // Resize the box to the picture's own shape so nothing arrives squashed.
        let width = 260.0
        onResize(CGSize(width: width, height: width / max(0.2, copy.aspect)))
    }
}

/// NSImageView renders animated GIFs on its own; SwiftUI's Image shows frame one.
private struct AnimatedImage: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.imageScaling = .scaleProportionallyUpOrDown
        view.animates = true
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    func updateNSView(_ view: NSImageView, context: Context) {
        if context.coordinator.loaded != url {
            view.image = NSImage(contentsOf: url)
            context.coordinator.loaded = url
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var loaded: URL?
    }
}
