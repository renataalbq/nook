import Foundation
import UniformTypeIdentifiers
import CoreTransferable
import CoreGraphics

extension UTType {
    /// Declared in Resources/Info.plist under UTExportedTypeDeclarations.
    static let nookTemplate = UTType(exportedAs: "com.nook.template")
}

/// The templates the palette can hand to the canvas.
enum TemplateKind: String, Codable, CaseIterable, Identifiable {
    case text
    case week
    case todoList
    case waterTrack

    var id: String { rawValue }

    var label: String {
        switch self {
        case .text: return "texto"
        case .week: return "semana"
        case .todoList: return "listinha"
        case .waterTrack: return "água"
        }
    }

    /// Lucide icon name — see `Design/Lucide/LucideIcon.swift`.
    var symbol: String {
        switch self {
        case .text: return "type"
        case .week: return "calendar"
        case .todoList: return "list-checks"
        case .waterTrack: return "droplet"
        }
    }

    func makeKind() -> ItemKind {
        switch self {
        case .text: return .richText(RichText())
        case .week: return .week(.current())
        case .todoList: return .todoList(TodoList())
        case .waterTrack: return .waterTrack(WaterTrack())
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
