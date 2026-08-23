import SwiftUI

/// Two-axis scroller with soft pastel indicators.
///
/// SwiftUI gives no control over scrollbar colour, so the system ones are
/// hidden and these are drawn instead. They are a read-out, not a control:
/// scrolling still happens with the trackpad.
struct PastelScrollView<Content: View>: View {
    let contentSize: CGSize
    @ViewBuilder let content: () -> Content

    @State private var offset: CGPoint = .zero
    @State private var viewport: CGSize = .zero
    @State private var isShowing = false
    @State private var fadeTask: Task<Void, Never>?

    private let thickness: CGFloat = 7
    private let inset: CGFloat = 4

    private var space: String { "pastel-scroll" }

    var body: some View {
        GeometryReader { proxy in
            ScrollView([.horizontal, .vertical]) {
                content()
                    .background(
                        GeometryReader { inner in
                            Color.clear.preference(
                                key: OffsetKey.self,
                                value: inner.frame(in: .named(space)).origin
                            )
                        }
                    )
            }
            .scrollIndicators(.hidden)
            .coordinateSpace(name: space)
            .onPreferenceChange(OffsetKey.self) { origin in
                offset = CGPoint(x: -origin.x, y: -origin.y)
                viewport = proxy.size
                flash()
            }
            .overlay(alignment: .bottomTrailing) { bar(.horizontal) }
            .overlay(alignment: .bottomTrailing) { bar(.vertical) }
            .onAppear { viewport = proxy.size }
        }
    }

    @ViewBuilder
    private func bar(_ axis: Axis) -> some View {
        let visible = axis == .vertical ? viewport.height : viewport.width
        let total = axis == .vertical ? contentSize.height : contentSize.width

        if total > visible + 1, visible > 0 {
            let ratio = visible / total
            let length = max(36, (visible - inset * 2) * ratio)
            let travel = (visible - inset * 2) - length
            let progress = min(1, max(0, (axis == .vertical ? offset.y : offset.x) / (total - visible)))

            Capsule()
                .fill(Theme.inkSoft.opacity(0.28))
                .frame(
                    width: axis == .vertical ? thickness : length,
                    height: axis == .vertical ? length : thickness
                )
                .offset(
                    x: axis == .vertical ? -inset : -(travel * (1 - progress)) - inset - thickness,
                    y: axis == .vertical ? -(travel * (1 - progress)) - inset - thickness : -inset
                )
                .opacity(isShowing ? 1 : 0)
                .animation(.easeOut(duration: 0.35), value: isShowing)
                .allowsHitTesting(false)
        }
    }

    /// Indicators appear while the page moves and fade out once it settles.
    private func flash() {
        isShowing = true
        fadeTask?.cancel()
        fadeTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1100))
            guard !Task.isCancelled else { return }
            isShowing = false
        }
    }
}

/// Declared outside the generic view: a nested type cannot hold the static
/// storage `PreferenceKey` requires.
private struct OffsetKey: PreferenceKey {
    static let defaultValue = CGPoint.zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}
