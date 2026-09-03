import SwiftUI

/// Left panel: nooks and their pages together, collapsible to a dot rail.
/// Only the selected nook shows its pages — picking another nook both
/// selects it and expands it, so there is never more than one open at once.
struct NookSidebar: View {
    let store: LibraryStore

    @State private var renamingNookID: UUID?
    @State private var nookDraft = ""
    @State private var renamingPageID: UUID?
    @State private var pageDraft = ""

    private var isCollapsed: Bool { store.library.sidebarCollapsed }

    var body: some View {
        // Collapsed content (icon badges, dots) is narrower than the 64px
        // rail itself, so it needs centre alignment there — left-aligned, it
        // stacked flush against the window edge instead of sitting in the rail.
        VStack(alignment: isCollapsed ? .center : .leading, spacing: 0) {
            header

            if isCollapsed {
                collapsedNooks
            } else {
                expandedBody
            }

            Spacer(minLength: 12)

            footer
        }
        .padding(.horizontal, isCollapsed ? 0 : 14)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .frame(width: isCollapsed ? 64 : 232)
        .frame(maxHeight: .infinity)
        .background(Theme.surface)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isCollapsed)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            if isCollapsed {
                appIconBadge
                collapseButton
            } else {
                HStack(spacing: 8) {
                    wordmark
                    Spacer()
                    collapseButton
                }
            }

            if isCollapsed {
                Rectangle()
                    .fill(Theme.inkSoft.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, 6)
            }
        }
        .padding(.bottom, isCollapsed ? 14 : 18)
    }

    private var wordmark: some View {
        HStack(spacing: 6) {
            appIconBadge

            HStack(spacing: 0) {
                ForEach(Array("nook".enumerated()), id: \.offset) { index, letter in
                    Text(String(letter))
                        .font(Theme.title(16))
                        .foregroundStyle(Theme.wordmarkColors[index % Theme.wordmarkColors.count])
                }
            }
        }
    }

    private var appIconBadge: some View {
        LucideIcon(name: "book-open", size: 14)
            .foregroundStyle(Theme.accent)
            .frame(width: 28, height: 28)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Theme.blush.fill))
    }

    private var collapseButton: some View {
        Button {
            store.setSidebarCollapsed(!isCollapsed)
        } label: {
            LucideIcon(name: "panel-left", size: 15)
                .foregroundStyle(Theme.inkSoft)
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Theme.surface.opacity(0.7)))
        }
        .buttonStyle(.plain)
        .help(isCollapsed ? "expandir" : "colapsar")
    }

    // MARK: - Expanded: nooks + pages

    private var expandedBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("NOOKS")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.inkSoft.opacity(0.8))
                    .padding(.leading, 4)

                ForEach(store.library.nooks) { nook in
                    nookSection(nook)
                }

                addNookButton
            }
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func nookSection(_ nook: Nook) -> some View {
        let isActive = store.selectedNook?.id == nook.id

        VStack(alignment: .leading, spacing: 2) {
            nookRow(nook, isActive: isActive)

            if isActive {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(nook.pages) { page in
                        pageRow(page, in: nook)
                    }
                }
                .padding(.leading, 18)
                .padding(.top, 2)

                addPageButton
                    .padding(.leading, 18)
            }
        }
    }

    private func nookRow(_ nook: Nook, isActive: Bool) -> some View {
        HStack(spacing: 7) {
            dot(nook.tint, size: 8)

            if renamingNookID == nook.id {
                TextField("", text: $nookDraft)
                    .textFieldStyle(.plain)
                    .font(Theme.hand(13, weight: .medium))
                    .onSubmit {
                        store.renameNook(nook.id, to: nookDraft)
                        renamingNookID = nil
                    }
            } else {
                Text(nook.name)
                    .font(Theme.hand(13, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(Theme.ink.opacity(isActive ? 1 : 0.75))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if isActive {
                LucideIcon(name: "chevron-down", size: 11)
                    .foregroundStyle(Theme.inkSoft.opacity(0.6))
            } else if nook.pages.count > 1 {
                Text("\(nook.pages.count)")
                    .font(Theme.hand(11))
                    .foregroundStyle(Theme.inkSoft.opacity(0.7))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(isActive ? Theme.accent.opacity(0.16) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { store.selectNook(nook.id) }
        .contextMenu {
            Button("renomear") {
                nookDraft = nook.name
                renamingNookID = nook.id
            }
            Button("apagar", role: .destructive) { store.deleteNook(nook.id) }
                .disabled(store.library.nooks.count <= 1)
        }
    }

    private func pageRow(_ page: Page, in nook: Nook) -> some View {
        let isSelected = store.selectedPage?.id == page.id

        return HStack(spacing: 6) {
            LucideIcon(name: page.paper.symbol, size: 12)
                .foregroundStyle(Theme.inkSoft.opacity(0.7))
                .frame(width: 14)

            if renamingPageID == page.id {
                TextField("", text: $pageDraft)
                    .textFieldStyle(.plain)
                    .font(Theme.hand(12, weight: .medium))
                    .onSubmit {
                        store.renamePage(page.id, to: pageDraft)
                        renamingPageID = nil
                    }
            } else {
                Text(page.name.isEmpty ? "sem título" : page.name)
                    .font(Theme.hand(12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(Theme.ink.opacity(isSelected ? 1 : 0.8))
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if isSelected {
                dot(nook.tint, size: 6)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Theme.surface : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { store.selectPage(page.id) }
        .onTapGesture(count: 2) {
            pageDraft = page.name
            renamingPageID = page.id
        }
        .draggable(page.id.uuidString) { Text(page.name.isEmpty ? "sem título" : page.name).font(Theme.hand(12)) }
        .dropDestination(for: String.self) { items, _ in
            guard let raw = items.first, let sourceID = UUID(uuidString: raw), sourceID != page.id else { return false }
            store.movePage(sourceID, before: page.id)
            return true
        }
        .contextMenu {
            Button("renomear") {
                pageDraft = page.name
                renamingPageID = page.id
            }
            Button("apagar", role: .destructive) { store.deletePage(page.id) }
                .disabled(nook.pages.count <= 1)
        }
    }

    /// A tint dot with a faint stroke so pale tints (blush especially, close
    /// in value to the sidebar itself) stay legible instead of nearly
    /// disappearing into the background.
    private func dot(_ tint: TintName, size: CGFloat) -> some View {
        Circle()
            .fill(Theme.tint(tint).accent)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(Theme.ink.opacity(0.18), lineWidth: 1))
    }

    private var addPageButton: some View {
        Button(action: store.addPage) {
            HStack(spacing: 5) {
                LucideIcon(name: "plus", size: 11)
                Text("nova página")
            }
            .font(Theme.hand(11))
            .foregroundStyle(Theme.inkSoft)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 7)
        .padding(.top, 3)
    }

    private var addNookButton: some View {
        Button(action: store.addNook) {
            HStack(spacing: 5) {
                LucideIcon(name: "plus", size: 12)
                Text("novo nook")
            }
            .font(Theme.hand(12, weight: .medium))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Theme.inkSoft.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        )
    }

    // MARK: - Collapsed: dot rail

    private var collapsedNooks: some View {
        VStack(spacing: 10) {
            ForEach(store.library.nooks) { nook in
                let isActive = store.selectedNook?.id == nook.id
                Circle()
                    .fill(Theme.tint(nook.tint).accent)
                    .frame(width: isActive ? 22 : 16, height: isActive ? 22 : 16)
                    .overlay(
                        Circle().stroke(Theme.ink.opacity(isActive ? 0.3 : 0.18), lineWidth: isActive ? 1.5 : 1)
                    )
                    .contentShape(Circle())
                    .onTapGesture { store.selectNook(nook.id) }
                    .help(nook.name)
            }
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        if isCollapsed {
            appearanceButtonCompact
        } else {
            appearanceToggle
        }
    }

    private var appearanceToggle: some View {
        HStack(spacing: 4) {
            ForEach(AppearanceMode.allCases) { mode in
                let isSelected = store.library.appearance == mode
                Button {
                    store.setAppearance(mode)
                } label: {
                    HStack(spacing: 4) {
                        LucideIcon(name: mode.symbol, size: 11)
                        Text(mode.label)
                            .font(Theme.hand(11, weight: isSelected ? .semibold : .regular))
                    }
                    .foregroundStyle(isSelected ? Theme.ink : Theme.inkSoft)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(isSelected ? Theme.surface : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(Theme.desk.opacity(0.6)))
    }

    private var appearanceButtonCompact: some View {
        Button {
            store.setAppearance(AppearanceMode.allCases[(currentAppearanceIndex + 1) % AppearanceMode.allCases.count])
        } label: {
            LucideIcon(name: store.library.appearance.symbol, size: 14)
                .foregroundStyle(Theme.inkSoft)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Theme.surface.opacity(0.6)))
        }
        .buttonStyle(.plain)
        .help(store.library.appearance.label)
    }

    private var currentAppearanceIndex: Int {
        AppearanceMode.allCases.firstIndex(of: store.library.appearance) ?? 0
    }
}
