import Foundation

/// One result: a small preview for the grid, the original for the page.
struct GifResult: Identifiable, Hashable {
    let id: String
    let previewURL: URL
    let gifURL: URL
    let description: String
}

/// GIPHY v1. Tenor stopped accepting new API clients in January 2026, so this
/// is the provider you can still sign up for.
enum GiphyClient {
    static let keyDefaultsName = "giphyAPIKey"

    /// Animated GIFs or transparent stickers — GIPHY serves them from separate paths.
    enum Kind: String, CaseIterable, Identifiable {
        case gifs, stickers
        var id: String { rawValue }
        var label: String { self == .gifs ? "GIFs" : "figurinhas" }
        var path: String { rawValue }
    }

    static var apiKey: String? {
        get {
            let value = UserDefaults.standard.string(forKey: keyDefaultsName)
            return (value?.isEmpty ?? true) ? nil : value
        }
        set { UserDefaults.standard.set(newValue, forKey: keyDefaultsName) }
    }

    enum Failure: LocalizedError {
        case missingKey
        case badResponse(Int)

        var errorDescription: String? {
            switch self {
            case .missingKey: return "falta a chave da GIPHY API"
            case .badResponse(let code): return "GIPHY respondeu \(code)"
            }
        }
    }

    static func search(_ query: String, kind: Kind, limit: Int = 24) async throws -> [GifResult] {
        guard let key = apiKey else { throw Failure.missingKey }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let endpoint = trimmed.isEmpty ? "trending" : "search"

        var components = URLComponents(string: "https://api.giphy.com/v1/\(kind.path)/\(endpoint)")!
        var items = [
            URLQueryItem(name: "api_key", value: key),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "rating", value: "pg-13")
        ]
        if !trimmed.isEmpty {
            items.append(URLQueryItem(name: "q", value: trimmed))
        }
        components.queryItems = items

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw Failure.badResponse(http.statusCode)
        }
        return try decode(data)
    }

    static func download(_ url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    // MARK: - Decoding

    private struct Payload: Decodable {
        struct Item: Decodable {
            let id: String
            let title: String?
            let images: [String: Image]
        }
        struct Image: Decodable {
            let url: URL?
        }
        let data: [Item]
    }

    private static func decode(_ data: Data) throws -> [GifResult] {
        let payload = try JSONDecoder().decode(Payload.self, from: data)
        return payload.data.compactMap { item in
            guard let original = item.images["original"]?.url else { return nil }
            let preview = item.images["fixed_width_small"]?.url
                ?? item.images["preview_gif"]?.url
                ?? original
            return GifResult(
                id: item.id,
                previewURL: preview,
                gifURL: original,
                description: item.title ?? ""
            )
        }
    }
}
