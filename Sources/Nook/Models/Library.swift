import Foundation
import CoreGraphics

/// How the page background is drawn.
enum PaperStyle: String, Codable, CaseIterable, Identifiable {
    case plain, ruled, grid

    var id: String { rawValue }

    var label: String {
        switch self {
        case .plain: return "sem linhas"
        case .ruled: return "pautada"
        case .grid: return "quadriculada"
        }
    }

    /// Lucide icon name — see `Design/Lucide/LucideIcon.swift`.
    var symbol: String {
        switch self {
        case .plain: return "square"
        case .ruled: return "list"
        case .grid: return "grid-3x3"
        }
    }
}

/// Everything that can sit on a page. New templates get a case here.
enum ItemKind: Codable, Hashable {
    /// Legacy plain-text box. Migrated to `.richText` when the library loads.
    case text(String)
    case richText(RichText)
    case waterTrack(WaterTrack)
    case todoList(TodoList)
    case calendar(CalendarBoard)
    case image(ImageBox)
    case week(WeekPlanner)

    var defaultSize: CGSize {
        switch self {
        case .text, .richText: return CGSize(width: 300, height: 84)
        case .waterTrack: return CGSize(width: 250, height: 100)
        case .todoList: return CGSize(width: 240, height: 170)
        case .calendar: return CGSize(width: 268, height: 236)
        case .image(let box): return CGSize(width: 260, height: 260 / max(0.2, box.aspect))
        case .week: return CGSize(width: 340, height: 400)
        }
    }

    var isText: Bool {
        switch self {
        case .text, .richText: return true
        default: return false
        }
    }
}

/// A positioned box on the canvas. Origin is the top-left corner, page-relative.
struct CanvasItem: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var kind: ItemKind

    var origin: CGPoint {
        get { CGPoint(x: x, y: y) }
        set { x = newValue.x; y = newValue.y }
    }

    var size: CGSize {
        get { CGSize(width: width, height: height) }
        set { width = newValue.width; height = newValue.height }
    }

    init(kind: ItemKind, at point: CGPoint, size: CGSize? = nil) {
        let resolved = size ?? kind.defaultSize
        self.x = point.x
        self.y = point.y
        self.width = resolved.width
        self.height = resolved.height
        self.kind = kind
    }
}

/// One sheet inside a nook.
struct Page: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    /// Empty until the user names it; the sidebar and header show "sem título" then.
    var name: String = ""
    var paper: PaperStyle = .grid
    var items: [CanvasItem] = []
    /// Freehand pen marks, drawn above the sheet and below nothing else.
    var strokes: [Stroke] = []
}

/// An isolated workspace. Pages in one nook never leak into another.
struct Nook: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var tint: TintName = .blush
    var pages: [Page] = [Page()]
}

/// Named pastel tints so the palette stays consistent and is Codable.
enum TintName: String, Codable, CaseIterable, Identifiable {
    case blush, sky, sage, butter, lilac
    var id: String { rawValue }
}

/// Root persisted document.
struct Library: Codable {
    var nooks: [Nook]
    var selectedNookID: UUID?
    var selectedPageIDs: [UUID: UUID] = [:]
    var appearance: AppearanceMode = .system
    /// Whether the nooks/pages panel is showing as the 64px dot rail.
    var sidebarCollapsed: Bool = false

    static var starter: Library {
        var welcome = Page()
        welcome.paper = .grid
        welcome.items = [
            CanvasItem(
                kind: .richText(RichText(plain: """
                bem-vinda ao nook \u{2728}

                barra de baixo: T escreve, \u{2728} busca figurinhas,
                \u{229E} abre templates, o l\u{E1}pis desenha.
                clique pra soltar na folha, ou arraste pra escolher o lugar.

                mova a caixa pelos pontinhos no topo dela.
                selecionada, Delete apaga.

                barra de cima: negrito, cor, fonte, estilo da folha e p\u{E1}ginas.
                """)),
                at: CGPoint(x: 80, y: 80),
                size: CGSize(width: 400, height: 210)
            ),
            CanvasItem(kind: .waterTrack(WaterTrack(goal: 5, filled: 2)), at: CGPoint(x: 80, y: 330))
        ]
        let nook = Nook(name: "2026", tint: .blush, pages: [welcome])
        return Library(nooks: [nook], selectedNookID: nook.id)
    }
}
