import SwiftUI
import AppKit

struct ContentView: View {
    @State private var store = LibraryStore()
    @State private var focus = EditorFocus()
    @State private var pen = PenSettings()
    @State private var selection = CanvasSelection()
    @State private var keys = KeyCommands()

    var body: some View {
        HStack(spacing: 0) {
            NookRail(store: store)

            VStack(spacing: 10) {
                FormatBar(focus: focus)

                ZStack(alignment: .bottom) {
                    if let page = store.selectedPage {
                        // The sheet scrolls in both directions and never shrinks
                        // below its content, so a small window hides nothing.
                        GeometryReader { proxy in
                            let extent = Self.contentExtent(of: page)
                            let sheet = CGSize(
                                width: max(proxy.size.width, extent.width),
                                height: max(proxy.size.height, extent.height)
                            )

                            PastelScrollView(contentSize: sheet) {
                                PageCanvas(page: page, store: store, focus: focus, pen: pen, selection: selection)
                                    .frame(width: sheet.width, height: sheet.height)
                            }
                        }
                        .id(page.id)
                    } else {
                        Color.clear
                    }

                    ToolDock(store: store, pen: pen)
                        .padding(.bottom, 14)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 18)
            .padding(.trailing, 22)
        }
        .background(Theme.desk)
        .preferredColorScheme(colorScheme)
        .onAppear { keys.start(selection: selection, store: store) }
        .onDisappear { keys.stop() }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                wordmark
            }

            ToolbarItem {
                pageNavigator
            }

            ToolbarItem {
                Picker("Folha", selection: paperBinding) {
                    ForEach(PaperStyle.allCases) { style in
                        Label(style.label, systemImage: style.symbol).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 130)
            }

            ToolbarItem {
                Picker("Aparência", selection: appearanceBinding) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Label(mode.label, systemImage: mode.symbol).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 110)
            }
        }
    }

    /// How much room the page's contents actually need, with a margin so there
    /// is always somewhere to drop the next thing.
    private static func contentExtent(of page: Page) -> CGSize {
        let margin: CGFloat = 120

        let itemRight = page.items.map { $0.x + $0.width }.max() ?? 0
        let itemBottom = page.items.map { $0.y + $0.height }.max() ?? 0

        let strokePoints = page.strokes.flatMap(\.points)
        let strokeRight = strokePoints.map(\.x).max() ?? 0
        let strokeBottom = strokePoints.map(\.y).max() ?? 0

        return CGSize(
            width: max(itemRight, strokeRight) + margin,
            height: max(itemBottom, strokeBottom) + margin
        )
    }

    /// One pastel per letter, in the icon's palette. Slightly deeper than the
    /// sheet pastels so the word stays legible at 16pt.
    private var wordmark: some View {
        HStack(spacing: 0) {
            ForEach(Array("nook".enumerated()), id: \.offset) { index, letter in
                Text(String(letter))
                    .font(Theme.hand(17, weight: .bold))
                    .foregroundStyle(Self.wordmarkColors[index % Self.wordmarkColors.count])
            }
        }
        .padding(14)
    }

    private static let wordmarkColors: [Color] = [
        Color(nsColor: NSColor(hex: 0xE79BAE)),
        Color(nsColor: NSColor(hex: 0x9DB584)),
        Color(nsColor: NSColor(hex: 0xE3BC6B)),
        Color(nsColor: NSColor(hex: 0xA9A2D6))
    ]

    /// `nil` hands the window back to the system setting.
    private var colorScheme: ColorScheme? {
        switch store.library.appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// Pages live on now that the numbered rail is gone.
    private var pageNavigator: some View {
        HStack(spacing: 4) {
            Button {
                step(-1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(pageIndex <= 0)

            Text("\(pageIndex + 1)/\(pageCount)")
                .font(Theme.hand(12, weight: .medium))
                .foregroundStyle(Theme.inkSoft)
                .monospacedDigit()
                .frame(minWidth: 32)

            Button {
                step(1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(pageIndex >= pageCount - 1)

            Button(action: store.addPage) {
                Image(systemName: "plus")
            }
            .help("nova página")

            Button {
                if let id = store.selectedPage?.id { store.deletePage(id) }
            } label: {
                Image(systemName: "trash")
            }
            .disabled(pageCount <= 1)
            .help("apagar página")
        }
    }

    private var pageCount: Int { store.selectedNook?.pages.count ?? 0 }

    private var pageIndex: Int {
        guard let nook = store.selectedNook, let page = store.selectedPage else { return 0 }
        return nook.pages.firstIndex { $0.id == page.id } ?? 0
    }

    private func step(_ delta: Int) {
        guard let nook = store.selectedNook else { return }
        let target = pageIndex + delta
        guard nook.pages.indices.contains(target) else { return }
        store.selectPage(nook.pages[target].id)
    }

    private var paperBinding: Binding<PaperStyle> {
        Binding(
            get: { store.selectedPage?.paper ?? .grid },
            set: { store.setPaper($0) }
        )
    }

    private var appearanceBinding: Binding<AppearanceMode> {
        Binding(
            get: { store.library.appearance },
            set: { store.setAppearance($0) }
        )
    }
}
