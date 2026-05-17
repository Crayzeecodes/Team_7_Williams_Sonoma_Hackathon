
import Foundation
import Supabase

@MainActor
final class WSOrderService {
    static let shared = WSOrderService()
    private init() {}

    func placeOrder(userId: UUID, cartItems: [WSCartItem], totalAmount: Double, shippingAddress: [String: String], paymentMethod: String) async throws -> WSOrder {

        let newOrder = WSOrder(
            id: UUID(),
            userId: userId,
            status: "paid",
            totalAmount: totalAmount,
            shippingAddress: shippingAddress,
            paymentMethod: paymentMethod,
            paymentStatus: "paid",
            createdAt: nil,
            updatedAt: nil
        )

        let insertedOrder: WSOrder = try await supabase
            .from("orders")
            .insert(newOrder)
            .select()
            .single()
            .execute()
            .value

        let orderItems = cartItems.map { item in
            WSOrderItem(
                id: UUID(),
                orderId: insertedOrder.id,
                productId: item.product.id,
                quantity: item.quantity,
                price: item.product.salePrice ?? item.product.price,
                productName: item.product.name,
                productImage: item.product.primaryImageURL?.absoluteString ?? ""
            )
        }

        if !orderItems.isEmpty {
            try await supabase
                .from("order_items")
                .insert(orderItems)
                .execute()
        }

        return insertedOrder
    }

    func fetchOrders(userId: UUID) async throws -> [WSOrderWithItems] {
        let selectQuery = """
        id,
        user_id,
        status,
        total_amount,
        created_at,
        order_items (
            id,
            order_id,
            product_id,
            quantity,
            price,
            product_name,
            product_image
        )
        """

        let orders: [WSOrderWithItems] = try await supabase
            .from("orders")
            .select(selectQuery)
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return orders
    }
}
