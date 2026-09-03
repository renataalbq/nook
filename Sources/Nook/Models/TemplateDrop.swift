import Foundation
import UniformTypeIdentifiers
import CoreTransferable
import CoreGraphics

extension UTType {
    /// Declared in Resources/Info.plist under UTExportedTypeDeclarations.
    static let nookTemplate = UTType(exportedAs: "com.nook.template")
    /// Same idea, for stickers and washi tape dragged in from the dock —
    /// kept separate from `nookTemplate` since decor carries a `DecorKind`
    /// rather than a `TemplateKind`.
    static let nookDecor = UTType(exportedAs: "com.nook.decor")
}

/// The templates the palette can hand to the canvas.
enum TemplateKind: String, Codable, CaseIterable, Identifiable {
    case text
    case week
    case todoList
    case waterTrack
    case postIt
    case mood

    var id: String { rawValue }

    var label: String {
        switch self {
        case .text: return "texto"
        case .week: return "semana"
        case .todoList: return "listinha"
        case .waterTrack: return "água"
        case .postIt: return "post-it"
        case .mood: return "mood"
        }
    }

    /// Lucide icon name — see `Design/Lucide/LucideIcon.swift`.
    var symbol: String {
        switch self {
        case .text: return "type"
        case .week: return "calendar"
        case .todoList: return "list-checks"
        case .waterTrack: return "droplet"
        case .postIt: return "sticky-note"
        case .mood: return "face-slightly-smiling"
        }
    }

    func makeKind() -> ItemKind {
        switch self {
        case .text: return .richText(RichText())
        case .week: return .week(.current())
        case .todoList: return .todoList(TodoList())
        case .waterTrack: return .waterTrack(WaterTrack())
        case .postIt: return .postIt(PostIt())
        case .mood: return .mood(MoodTracker())
        }
    }
}

/// Payload carried by a drag from the palette to a page.
struct TemplateDrop: Codable, Transferable {
    var kind: TemplateKind

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .nookTemplate)
    }
}

/// Payload carried by a drag of a sticker or washi-tape chip to a page.
struct DecorDrop: Codable, Transferable {
    var kind: DecorKind

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .nookDecor)
    }
}
