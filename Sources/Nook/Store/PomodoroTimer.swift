import Foundation
import Observation
import AppKit

/// A focus/break countdown living in the sidebar: 25 minutes of focus, then
/// a 5 minute break, alternating for as long as it keeps running. Session-
/// only — it does not persist the countdown itself across launches (picking
/// up mid-break after quitting isn't something anyone actually wants); only
/// the daily cycle count survives, via `LibraryStore.recordPomodoroCycle()`.
@Observable
final class PomodoroTimer {
    enum Phase { case focus, rest }

    static let focusSeconds = 25 * 60
    static let restSeconds = 5 * 60

    private(set) var phase: Phase = .focus
    private(set) var secondsLeft = PomodoroTimer.focusSeconds
    private(set) var isRunning = false
    var soundEnabled = true

    /// Fires right as a focus block finishes, before switching to break —
    /// the sidebar hooks this to bump the persisted daily count.
    var onFocusComplete: (() -> Void)?

    private var task: Task<Void, Never>?

    var label: String {
        String(format: "%02d:%02d", secondsLeft / 60, secondsLeft % 60)
    }

    var phaseLabel: String {
        phase == .focus ? "foco · 25 min" : "pausa · 5 min"
    }

    var progress: Double {
        let total = phase == .focus ? Self.focusSeconds : Self.restSeconds
        return 1 - Double(secondsLeft) / Double(total)
    }

    func toggle() {
        isRunning ? pause() : start()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        task = Task { @MainActor [weak self] in
            while let self, self.isRunning {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, self.isRunning else { return }
                if self.secondsLeft > 0 {
                    self.secondsLeft -= 1
                } else {
                    self.advancePhase()
                }
            }
        }
    }

    func pause() {
        isRunning = false
        task?.cancel()
    }

    func reset() {
        pause()
        phase = .focus
        secondsLeft = Self.focusSeconds
    }

    /// A finished phase hands off to the next one without stopping — the
    /// loop in `start()` just keeps ticking down whatever `secondsLeft`
    /// becomes here.
    private func advancePhase() {
        if soundEnabled { NSSound.beep() }

        if phase == .focus {
            onFocusComplete?()
            phase = .rest
            secondsLeft = Self.restSeconds
        } else {
            phase = .focus
            secondsLeft = Self.focusSeconds
        }
    }
}
