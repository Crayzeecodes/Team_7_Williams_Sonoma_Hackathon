
import Foundation
extension Endpoint {

    static func products() -> Endpoint {
        Endpoint(
            path: "/skus",
            method: .get
        )
    }
}
