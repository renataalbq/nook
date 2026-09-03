import SwiftUI

struct ContentView: View {
    @State private var store = LibraryStore()
    @State private var focus = EditorFocus()
    @State private var pen = PenSettings()
    @State private var selection = CanvasSelection()
    @State private var keys = KeyCommands()
    @State private var isFocusMode = false
    @State private var isEditingTitle = false
    @State private var titleDraft = ""

    var body: some View {
        HStack(spacing: 0) {
            if !isFocusMode {
                NookSidebar(store: store)
            }

            VStack(alignment: .leading, spacing: 12) {
                pageHeader

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
            .padding(.top, 34)
            .padding(.bottom, 18)
            .padding(.horizontal, 22)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isFocusMode)
        }
        .background(Theme.desk)
        .preferredColorScheme(colorScheme)
        .onAppear { keys.start(selection: selection, store: store) }
        .onDisappear { keys.stop() }
        .onChange(of: store.selectedPage?.id) { _, _ in isEditingTitle = false }
    }

    // MARK: - Page header

    /// Title, breadcrumb meta, paper-style picker and the focus toggle —
    /// everything that used to live in the window's native toolbar now lives
    /// here so the whole chrome reads as one surface instead of two.
    private var pageHeader: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                titleView
                Text(pageMeta)
                    .font(Theme.hand(12))
                    .foregroundStyle(Theme.inkSoft)
            }

            Spacer(minLength: 8)

            paperModeButtons
            focusButton
        }
    }

    /// Double-click to rename — the same gesture the sidebar's page rows
    /// already use, just reachable from the sheet itself too.
    @ViewBuilder
    private var titleView: some View {
        if isEditingTitle {
            TextField("", text: $titleDraft)
                .textFieldStyle(.plain)
                .font(Theme.title(21))
                .foregroundStyle(Theme.ink)
                .onSubmit {
                    if let id = store.selectedPage?.id {
                        store.renamePage(id, to: titleDraft)
                    }
                    isEditingTitle = false
                }
        } else {
            Text(pageTitle)
                .font(Theme.title(21))
                .foregroundStyle(Theme.ink)
                .onTapGesture(count: 2) {
                    titleDraft = store.selectedPage?.name ?? ""
                    isEditingTitle = true
                }
        }
    }

    private var paperModeButtons: some View {
        HStack(spacing: 2) {
            ForEach(PaperStyle.allCases) { style in
                let isSelected = store.selectedPage?.paper == style
                Button {
                    store.setPaper(style)
                } label: {
                    LucideIcon(name: style.symbol, size: 14)
                        .foregroundStyle(isSelected ? Color.white : Theme.inkSoft)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(isSelected ? Theme.ink : Color.clear))
                }
                .buttonStyle(.plain)
                .help(style.label)
            }
        }
        .padding(3)
        .background(Capsule().fill(Theme.surface))
    }

    private var focusButton: some View {
        Button {
            isFocusMode.toggle()
        } label: {
            HStack(spacing: 5) {
                LucideIcon(name: isFocusMode ? "eye" : "eye-off", size: 13)
                Text(isFocusMode ? "sair" : "foco")
            }
            .font(Theme.hand(12, weight: .medium))
            .foregroundStyle(Theme.inkSoft)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Theme.surface))
        }
        .buttonStyle(.plain)
        .help("esconder a barra lateral")
    }

    private var pageTitle: String {
        let name = store.selectedPage?.name ?? ""
        return name.isEmpty ? "sem título" : name
    }

    private var pageMeta: String {
        let nookName = store.selectedNook?.name ?? ""
        var parts = ["\(nookName)", "página \(pageIndex + 1) de \(pageCount)"]
        parts.append(savedLabel)
        return parts.joined(separator: " · ")
    }

    private var savedLabel: String {
        guard let date = store.lastSavedAt else { return "ainda não salvo" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.unitsStyle = .short
        return "salvo \(formatter.localizedString(for: date, relativeTo: Date()))"
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

    /// `nil` hands the window back to the system setting.
    private var colorScheme: ColorScheme? {
        switch store.library.appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private var pageCount: Int { store.selectedNook?.pages.count ?? 0 }

    private var pageIndex: Int {
        guard let nook = store.selectedNook, let page = store.selectedPage else { return 0 }
        return nook.pages.firstIndex { $0.id == page.id } ?? 0
    }
}
