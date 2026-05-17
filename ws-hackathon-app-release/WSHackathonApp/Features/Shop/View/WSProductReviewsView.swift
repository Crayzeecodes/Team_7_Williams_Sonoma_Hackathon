
import SwiftUI

struct WSProductReviewsView: View {
    let productId: UUID
    @Binding var reviews: [WSReview]
    @Environment(UserManager.self) private var userManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            VStack(alignment: .leading, spacing: 4) {
                Text("CUSTOMER REVIEWS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(Color.secondary)

                Text("\(reviews.count) Reviews")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.primary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 16)

            if reviews.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    Text("No reviews yet.")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(reviews.enumerated()), id: \.element.id) { index, review in
                        ReviewRowView(review: review)
                        if index < reviews.count - 1 {
                            Divider()
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
    }
}

struct ReviewRowView: View {
    let review: WSReview

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(review.userName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary)
                Spacer()
                if let date = review.createdAt {
                    Text(date, format: .dateTime.day().month(.abbreviated).year())
                        .font(.system(size: 13))
                        .foregroundStyle(Color.secondary)
                }
            }

            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= review.rating ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.black)
                }
            }

            if let comment = review.comment, !comment.isEmpty {
                Text(comment)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(review.userName), \(review.rating) stars. \(review.comment ?? "")")
    }
}
