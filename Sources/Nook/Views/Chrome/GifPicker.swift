import SwiftUI
import AppKit

/// GIPHY search, the way Discord does it: type, pick, it lands on the page.
struct GifPicker: View {
    let store: LibraryStore
    let onPick: (String, Double) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var kind: GiphyClient.Kind = .gifs
    @State private var results: [GifResult] = []
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var keyDraft = ""
    @State private var hasKey = GiphyClient.apiKey != nil
    @State private var searchTask: Task<Void, Never>?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: 10) {
            header

            if hasKey {
                searchField
                content
            } else {
                keySetup
            }
        }
        .padding(14)
        .frame(width: 460, height: 520)
        .background(Theme.desk)
        .task { await load() }
    }

    private var header: some View {
        HStack {
            Text("figurinhas & GIFs")
                .font(Theme.hand(15, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            if hasKey {
                Button("trocar chave") {
                    keyDraft = GiphyClient.apiKey ?? ""
                    hasKey = false
                }
                .buttonStyle(.plain)
                .font(Theme.hand(11))
                .foregroundStyle(Theme.inkSoft)
            }
            Button("fechar") { dismiss() }
                .buttonStyle(.plain)
                .font(Theme.hand(11))
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            LucideIcon(name: "search", size: 13)
                .foregroundStyle(Theme.inkSoft)

            TextField("buscar…", text: $query)
                .textFieldStyle(.plain)
                .font(Theme.hand(13))
                .foregroundStyle(Theme.ink)
                .onSubmit { trigger() }
                .onChange(of: query) { _, _ in trigger(debounced: true) }

            Picker("", selection: $kind) {
                ForEach(GiphyClient.Kind.allCases) { value in
                    Text(value.label).tag(value)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 150)
            .onChange(of: kind) { _, _ in trigger() }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule().fill(Theme.surface)
                .overlay(Capsule().stroke(Theme.ruleLine, lineWidth: 1))
        )
    }

    @ViewBuilder
    private var content: some View {
        if let errorText {
            message(errorText)
        } else if isLoading && results.isEmpty {
            ProgressView().frame(maxHeight: .infinity)
        } else if results.isEmpty {
            message("nada encontrado")
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(results) { result in
                        RemoteAnimatedImage(url: result.previewURL)
                            .frame(height: 92)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .contentShape(Rectangle())
                            .onTapGesture { pick(result) }
                            .help(result.description)
                    }
                }
            }
        }
    }

    private var keySetup: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("cole sua chave da GIPHY API")
                .font(Theme.hand(13, weight: .medium))
                .foregroundStyle(Theme.ink)

            Text("developers.giphy.com → Create an App → API do tipo GIF → a chave aparece na hora. É grátis e não precisa de cartão.")
                .font(Theme.hand(11))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            TextField("AIza…", text: $keyDraft)
                .textFieldStyle(.roundedBorder)
                .font(Theme.hand(12))

            Button("salvar") {
                GiphyClient.apiKey = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                hasKey = GiphyClient.apiKey != nil
                trigger()
            }
            .disabled(keyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Spacer()
        }
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(Theme.hand(12))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    /// Debounced so typing does not fire a request per keystroke.
    private func trigger(debounced: Bool = false) {
        searchTask?.cancel()
        searchTask = Task {
            if debounced {
                try? await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled else { return }
            }
            await load()
        }
    }

    private func load() async {
        guard hasKey else { return }
        isLoading = true
        errorText = nil
        do {
            results = try await GiphyClient.search(query, kind: kind)
        } catch {
            results = []
            errorText = error.localizedDescription
        }
        isLoading = false
    }

    private func pick(_ result: GifResult) {
        Task {
            guard let data = try? await GiphyClient.download(result.gifURL),
                  let id = store.importAsset(data: data, ext: "gif")
            else { return }

            let aspect = NSImage(data: data).map { image -> Double in
                image.size.height > 0 ? image.size.width / image.size.height : 1.5
            } ?? 1.5

            onPick(id, aspect)
            dismiss()
        }
    }
}

/// Loads a remote GIF and lets NSImageView animate it.
struct RemoteAnimatedImage: View {
    let url: URL

    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                AnimatedNSImage(image: image)
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.surface)
            }
        }
        .task(id: url) {
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
            image = NSImage(data: data)
        }
    }
}

struct AnimatedNSImage: NSViewRepresentable {
    let image: NSImage

    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.imageScaling = .scaleProportionallyUpOrDown
        view.animates = true
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    func updateNSView(_ view: NSImageView, context: Context) {
        view.image = image
    }
}
