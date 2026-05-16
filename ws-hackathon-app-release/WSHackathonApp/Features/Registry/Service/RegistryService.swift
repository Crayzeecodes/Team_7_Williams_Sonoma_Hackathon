//
//  RegistryService.swift
//  WSHackathonApp
//

import Foundation

enum RegistryServiceError: LocalizedError {
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .serverError(let message):
            return message
        }
    }
}

final class RegistryService {
    static let shared = RegistryService()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init(session: URLSession = .shared) {
        self.session = session

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = ISO8601DateFormatter.withFractionalSeconds.date(from: value) ?? ISO8601DateFormatter.standard.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date string")
        }

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(ISO8601DateFormatter.withFractionalSeconds.string(from: date))
        }
    }

    func loadRegistries() async throws -> [Registry] {
        try await request(path: APIConfig.registryBasePath, method: "GET")
    }

    func previewRegistry(joinCode: String) async throws -> RegistryPreview {
        try await request(
            path: APIConfig.registryBasePath,
            method: "GET",
            queryItems: [URLQueryItem(name: "joinCode", value: joinCode)]
        )
    }

    func createRegistry(_ requestBody: CreateRegistryRequest) async throws -> Registry {
        try await request(path: APIConfig.registryBasePath, method: "POST", body: requestBody)
    }

    func joinRegistry(code: String, contributedBudget: Double?) async throws -> Registry {
        try await request(
            path: "\(APIConfig.registryBasePath)/join",
            method: "POST",
            body: JoinRegistryRequest(joinCode: code, contributedBudget: contributedBudget)
        )
    }

    func loadRegistry(id: String) async throws -> Registry {
        try await request(path: "\(APIConfig.registryBasePath)/\(id)", method: "GET")
    }

    func leaveRegistry(id: String) async throws -> LeaveRegistryResponse {
        try await request(path: "\(APIConfig.registryBasePath)/\(id)/leave", method: "DELETE")
    }

    func addCartItem(registryId: String, requestBody: AddRegistryCartItemRequest) async throws -> CartUpdatePayload {
        try await request(path: "\(APIConfig.registryBasePath)/\(registryId)/cart", method: "POST", body: requestBody)
    }

    func removeCartItem(registryId: String, itemId: String) async throws -> CartUpdatePayload {
        try await request(path: "\(APIConfig.registryBasePath)/\(registryId)/cart/\(itemId)", method: "DELETE")
    }

    func refreshSuggestions(registryId: String, forceRefresh: Bool) async throws -> [RegistryAISuggestion] {
        try await request(
            path: "\(APIConfig.registryBasePath)/\(registryId)/suggest",
            method: "POST",
            body: RegistrySuggestionRefreshRequest(forceRefresh: forceRefresh)
        )
    }

    func loadMembers(registryId: String) async throws -> [RegistryMemberDisplay] {
        try await request(path: "\(APIConfig.registryBasePath)/\(registryId)/members", method: "GET")
    }

    private func request<T: Decodable, Body: Encodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Body
    ) async throws -> T {
        var request = try makeRequest(path: path, method: method, queryItems: queryItems)
        request.httpBody = try encoder.encode(body)
        return try await execute(request)
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        let request = try makeRequest(path: path, method: method, queryItems: queryItems)
        return try await execute(request)
    }

    private func makeRequest(path: String, method: String, queryItems: [URLQueryItem]) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: APIConfig.baseURL),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw RegistryServiceError.invalidResponse
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let resolvedURL = components.url else {
            throw RegistryServiceError.invalidResponse
        }

        var request = URLRequest(url: resolvedURL)
        request.httpMethod = method
        request.timeoutInterval = APIConfig.requestTimeout
        APIConfig.defaultHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RegistryServiceError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            if let message = try? JSONDecoder().decode(ServerErrorResponse.self, from: data).message {
                throw RegistryServiceError.serverError(message)
            }
            throw RegistryServiceError.serverError("Request failed with status \(httpResponse.statusCode)")
        }

        return try decoder.decode(T.self, from: data)
    }
}

struct LeaveRegistryResponse: Codable {
    let deleted: Bool
    let registryId: String?
    let registry: Registry?
}

private struct ServerErrorResponse: Codable {
    let message: String
}

private extension ISO8601DateFormatter {
    static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
