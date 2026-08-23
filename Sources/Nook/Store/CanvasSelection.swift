import Foundation
import Observation

/// Which box on the page is selected. Lives outside the canvas view so a
/// window-level key monitor can act on it.
@Observable
final class CanvasSelection {
    var itemID: UUID?
}
