
import Foundation

struct RoomScanPreferences {
    var category: String = ""
    var size: String = ""
    var budgetMax: Double = 0
    var styleVibe: String = ""

    var dto: RoomScanPreferencesDTO {
        RoomScanPreferencesDTO(
            category: category.lowercased()
                .replacingOccurrences(of: " & ", with: "_")
                .replacingOccurrences(of: " ", with: "_"),
            size: size.lowercased()
                .replacingOccurrences(of: " ", with: "_"),
            budgetMax: budgetMax,
            styleVibe: styleVibe.lowercased()
        )
    }
}

struct RoomAnalyzeRequest: Encodable {
    let images: [String]
    let preferences: RoomScanPreferencesDTO
}

struct RoomScanPreferencesDTO: Encodable {
    let category: String
    let size: String
    let budgetMax: Double
    let styleVibe: String

    enum CodingKeys: String, CodingKey {
        case category, size
        case budgetMax = "budget_max"
        case styleVibe = "style_vibe"
    }
}

struct RoomAnalysisResult: Codable {
    let roomType: String
    let detectedStyle: String
    let dominantColors: [String]
    let dominantMaterials: [String]
    let recommendedStyleTags: [String]
    let recommendedCategories: [String]
    let priceMax: Double
    let sizePreference: String
    let reasoning: String
    let negativeCategories: [String]
    var recommendedProducts: [WSProduct]?

    enum CodingKeys: String, CodingKey {
        case roomType = "room_type"
        case detectedStyle = "detected_style"
        case dominantColors = "dominant_colors"
        case dominantMaterials = "dominant_materials"
        case recommendedStyleTags = "recommended_style_tags"
        case recommendedCategories = "recommended_categories"
        case priceMax = "price_max"
        case sizePreference = "size_preference"
        case reasoning
        case negativeCategories = "negative_categories"
        case recommendedProducts = "recommended_products"
    }
}

enum RoomScanQuestions {

    static let categoryOptions = [
        "Furniture", "Cookware & Kitchen", "Tabletop & Bar",
        "Home Textiles", "Outdoor", "Everything"
    ]

    static func sizeOptions(for category: String) -> [String] {
        switch category {
        case "Furniture":
            return ["Twin", "Queen", "King", "Other"]
        case "Cookware & Kitchen":
            return ["Small (1-3qt)", "Medium (4-6qt)", "Large (7qt+)"]
        case "Tabletop & Bar":
            return ["2 place", "4 place", "6 place", "8 place+"]
        default:
            return ["Compact", "Standard", "Large", "Extra Large"]
        }
    }

    static let budgetOptions = ["Under $100", "$100–$300", "$300–$700", "$700+"]

    static func budgetMax(for option: String) -> Double {
        switch option {
        case "Under $100": return 100
        case "$100–$300": return 300
        case "$300–$700": return 700
        default: return 10_000
        }
    }

    static let styleOptions = [
        "Modern", "Rustic", "Farmhouse",
        "Coastal", "Industrial", "Traditional"
    ]
}

enum RoomScanError: LocalizedError {
    case noImages
    case compressionFailed
    case invalidURL
    case serverError(Int)
    case decodingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noImages:          return "No images provided for analysis."
        case .compressionFailed: return "Failed to compress images."
        case .invalidURL:        return "Invalid server URL."
        case .serverError(let code): return "Server error (\(code)). Please try again."
        case .decodingError:     return "Failed to parse analysis results."
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        }
    }
}
