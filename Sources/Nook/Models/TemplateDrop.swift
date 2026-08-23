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
    case waterTrack
    case todoList
    case week

    var id: String { rawValue }

    var label: String {
        switch self {
        case .text: return "Texto"
        case .waterTrack: return "Water Track"
        case .todoList: return "To-do List"
        case .week: return "Semana"
        }
    }

    var symbol: String {
        switch self {
        case .text: return "textformat"
        case .waterTrack: return "drop.fill"
        case .todoList: return "checklist"
        case .week: return "calendar.day.timeline.left"
        }
    }

    func makeKind() -> ItemKind {
        switch self {
        case .text: return .richText(RichText())
        case .waterTrack: return .waterTrack(WaterTrack())
        case .todoList: return .todoList(TodoList())
        case .week: return .week(.current())
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
