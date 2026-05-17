import Foundation
import SwiftUI

@Observable
final class CheckoutViewModel {
    var subtotal: Double
    var email: String = "chirag@example.com"
    var shippingMethod: String = "Standard (3-5 days)"
    var paymentMethod: String = "Apple Pay"

    init(subtotal: Double) {
        self.subtotal = subtotal
    }

    var total: Double {
        subtotal
    }
}
