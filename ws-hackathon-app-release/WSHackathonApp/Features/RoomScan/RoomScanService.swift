//
//  RoomScanService.swift
//  WSHackathonApp
//
//  Handles API communication with the FastAPI room analysis backend.
//

import Foundation
import UIKit

actor RoomScanService {
    static let shared = RoomScanService()

    // MARK: - Image Compression
    /// Compresses image to max 1024px longest side, JPEG quality 0.7
    private func compressImage(_ image: UIImage) -> Data? {
        let maxDimension: CGFloat = 1024
        let size = image.size

        let scale: CGFloat
        if max(size.width, size.height) > maxDimension {
            scale = maxDimension / max(size.width, size.height)
        } else {
            scale = 1.0
        }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized?.jpegData(compressionQuality: 0.7)
    }

    // MARK: - Analyze Room
    func analyzeRoom(
        images: [UIImage],
        preferences: RoomScanPreferences
    ) async throws -> RoomAnalysisResult {

        guard !images.isEmpty else { throw RoomScanError.noImages }

        // 1. Compress and encode images
        var base64Images: [String] = []
        for image in images {
            guard let data = compressImage(image) else {
                throw RoomScanError.compressionFailed
            }
            base64Images.append(data.base64EncodedString())
        }

        // 2. Build request body
        let requestBody = RoomAnalyzeRequest(
            images: base64Images,
            preferences: preferences.dto
        )

        // 3. Build URL request
        guard let url = URL(string: AppConstants.API.aiBaseURL + "/room/analyze") else {
            throw RoomScanError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // Claude analysis can take a moment

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)

        // 4. Execute request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RoomScanError.decodingError
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw RoomScanError.serverError(httpResponse.statusCode)
        }

        // 5. Decode response
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(RoomAnalysisResult.self, from: data)
        } catch {
            print("Room analysis decoding error: \(error)")
            throw RoomScanError.decodingError
        }
    }
}
