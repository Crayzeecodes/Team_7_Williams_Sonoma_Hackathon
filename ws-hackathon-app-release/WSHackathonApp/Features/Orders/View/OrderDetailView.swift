import SwiftUI

struct OrderDetailView: View {
    let order: WSOrderWithItems
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Order Status")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                        Text(order.status.uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.primary)
                    }
                    
                    Spacer()
                    
                    if let date = order.createdAt {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Items")
                        .font(.system(size: 18, weight: .bold))
                        .padding(.horizontal, 16)
                    
                    ForEach(order.orderItems) { item in
                        HStack(alignment: .top, spacing: 16) {
                            if let imageUrlStr = item.productImage, let url = URL(string: imageUrlStr) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        Rectangle().fill(Color(uiColor: .secondarySystemBackground))
                                    case .success(let image):
                                        image.resizable().scaledToFill()
                                    case .failure:
                                        Rectangle().fill(Color(uiColor: .secondarySystemBackground))
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                            } else {
                                Rectangle()
                                    .fill(Color(uiColor: .secondarySystemBackground))
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.productName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                                
                                Text("Qty: \(item.quantity)")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.secondary)
                                
                                Text(String(format: "$%.2f", item.price))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.primary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Order Summary")
                        .font(.system(size: 18, weight: .bold))
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 12) {
                        summaryRow(title: "Subtotal", value: String(format: "$%.2f", order.totalAmount))
                        summaryRow(title: "Shipping", value: "Free")
                        summaryRow(title: "Tax", value: "Included")
                        
                        Divider().padding(.vertical, 4)
                        
                        summaryRow(title: "Total", value: String(format: "$%.2f", order.totalAmount), isBold: true)
                    }
                    .padding(16)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color(uiColor: .separator).opacity(0.5), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("ORDER-\(order.id.uuidString.prefix(8).uppercased())")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func summaryRow(title: String, value: String, isBold: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: isBold ? .bold : .regular))
                .foregroundStyle(Color.primary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: isBold ? .bold : .regular))
                .foregroundStyle(Color.primary)
        }
    }
}
