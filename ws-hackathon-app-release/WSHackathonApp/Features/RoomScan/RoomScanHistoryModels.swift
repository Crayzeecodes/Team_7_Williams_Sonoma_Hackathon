
import Foundation

struct RoomScanHistoryRecord: Codable, Identifiable {
    let id: String
    let deviceId: String
    let imageUrls: [String]
    let roomType: String
    let detectedStyle: String
    let dominantColors: [String]
    let dominantMaterials: [String]
    let reasoning: String
    let recommendedProductIds: [String]
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case deviceId = "device_id"
        case imageUrls = "image_urls"
        case roomType = "room_type"
        case detectedStyle = "detected_style"
        case dominantColors = "dominant_colors"
        case dominantMaterials = "dominant_materials"
        case reasoning
        case recommendedProductIds = "recommended_product_ids"
        case createdAt = "created_at"
    }
}

struct RoomScanHistoryInsert: Codable {
    let deviceId: String
    let imageUrls: [String]
    let roomType: String
    let detectedStyle: String
    let dominantColors: [String]
    let dominantMaterials: [String]
    let reasoning: String
    let recommendedProductIds: [String]

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case imageUrls = "image_urls"
        case roomType = "room_type"
        case detectedStyle = "detected_style"
        case dominantColors = "dominant_colors"
        case dominantMaterials = "dominant_materials"
        case reasoning
        case recommendedProductIds = "recommended_product_ids"
    }
}
