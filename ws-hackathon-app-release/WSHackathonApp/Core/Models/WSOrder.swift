
import Foundation

struct WSOrder: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let status: String
    let totalAmount: Double
    let shippingAddress: [String: String]?
    let paymentMethod: String?
    let paymentStatus: String
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case status
        case totalAmount = "total_amount"
        case shippingAddress = "shipping_address"
        case paymentMethod = "payment_method"
        case paymentStatus = "payment_status"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct WSOrderItem: Identifiable, Codable, Hashable {
    let id: UUID
    let orderId: UUID
    let productId: UUID
    let quantity: Int
    let price: Double
    let productName: String
    let productImage: String?

    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case productId = "product_id"
        case quantity
        case price
        case productName = "product_name"
        case productImage = "product_image"
    }
}

struct WSOrderWithItems: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let status: String
    let totalAmount: Double
    let createdAt: Date?
    let orderItems: [WSOrderItem]

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case status
        case totalAmount = "total_amount"
        case createdAt = "created_at"
        case orderItems = "order_items"
    }
}
