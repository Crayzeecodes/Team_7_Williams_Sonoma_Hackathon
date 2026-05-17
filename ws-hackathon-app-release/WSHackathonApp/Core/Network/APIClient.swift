
import Foundation
import UIKit

final class APIClient {
    static let shared = APIClient()
    private init() {}

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let (data, _) = try await requestData(endpoint)
        return try decode(data: data)
    }

    func request<T: Decodable, Body: Encodable>(
        _ endpoint: Endpoint,
        body: Body
    ) async throws -> T {
        let (data, _) = try await requestData(endpoint, body: body)
        return try decode(data: data)
    }

    func requestData(
        _ endpoint: Endpoint,
        body: (any Encodable)? = nil
    ) async throws -> (Data, URLResponse) {

        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = AppConstants.API.timeout

        var allHeaders = APIConfig.defaultHeaders
        endpoint.headers?.forEach { allHeaders[$0.key] = $0.value }

        allHeaders.forEach {
            request.addValue($0.value, forHTTPHeaderField: $0.key)
        }

        if let body = body {
            if endpoint.method == .get {
                assertionFailure("GET request should not have body")
            }

            request.httpBody = try encode(body)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }

        return (data, response)
    }

    private func encode(_ value: any Encodable) throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(AnyEncodable(value))
    }

    private func decode<T: Decodable>(data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    func downloadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let image = UIImage(data: data) else {
            throw NetworkError.decodingError
        }

        return image
    }
}

struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        encodeFunc = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
