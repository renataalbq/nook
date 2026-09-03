import Foundation
import Observation

/// A focus countdown living in the sidebar. Session-only — it does not
/// persist across launches, and doesn't yet know about break cycles, sound,
/// or a daily count; just start/pause on one 25-minute block.
@Observable
final class PomodoroTimer {
    static let focusSeconds = 25 * 60

    private(set) var secondsLeft = PomodoroTimer.focusSeconds
    private(set) var isRunning = false

    private var task: Task<Void, Never>?

    var label: String {
        String(format: "%02d:%02d", secondsLeft / 60, secondsLeft % 60)
    }

    var progress: Double {
        1 - Double(secondsLeft) / Double(Self.focusSeconds)
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
                    self.reset()
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
        secondsLeft = Self.focusSeconds
    }
}
