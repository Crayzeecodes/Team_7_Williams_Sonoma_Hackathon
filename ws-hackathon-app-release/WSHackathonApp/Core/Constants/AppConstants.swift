
import Foundation
enum AppConstants {

    enum API {
        static var baseURL: String { APIConfig.baseURL.absoluteString }
        static var imageBasePath: String { APIConfig.baseURL.appendingPathComponent("images").absoluteString + "/" }
        static let timeout: TimeInterval = 30

    }
}
