import SwiftUI

/// Left-hand tabs: one per nook. Each nook is a fully separate workspace.
struct NookRail: View {
    let store: LibraryStore

    @State private var renamingID: UUID?
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ForEach(store.library.nooks) { nook in
                tab(for: nook)
            }

            Button(action: store.addNook) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(width: 84, height: 30)
                    .background(
                        UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8, style: .continuous)
                            .fill(Theme.sage.opacity(0.45))
                    )
            }
            .buttonStyle(.plain)
            .help("novo nook")

            Spacer()
        }
        .padding(.top, 40)
        .frame(width: 92)
    }

    @ViewBuilder
    private func tab(for nook: Nook) -> some View {
        let isActive = store.selectedNook?.id == nook.id

        Group {
            if renamingID == nook.id {
                TextField("", text: $draft)
                    .textFieldStyle(.plain)
                    .font(Theme.hand(12, weight: .medium))
                    .multilineTextAlignment(.center)
                    .onSubmit {
                        store.renameNook(nook.id, to: draft)
                        renamingID = nil
                    }
            } else {
                Text(nook.name)
                    .font(Theme.hand(12, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(Theme.ink.opacity(isActive ? 1 : 0.6))
                    .lineLimit(1)
            }
        }
        .frame(width: isActive ? 92 : 84, height: 38)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 10, style: .continuous)
                .fill(Theme.tint(nook.tint).opacity(isActive ? 1 : 0.55))
        )
        .contentShape(Rectangle())
        .onTapGesture { store.selectNook(nook.id) }
        .contextMenu {
            Button("renomear") {
                draft = nook.name
                renamingID = nook.id
            }
            Button("apagar", role: .destructive) { store.deleteNook(nook.id) }
                .disabled(store.library.nooks.count <= 1)
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: isActive)
    }
}
