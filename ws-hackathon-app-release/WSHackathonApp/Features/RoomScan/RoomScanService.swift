//
//  RoomScanService.swift
//  WSHackathonApp
//
//  Handles API communication directly with Gemini using GoogleGenerativeAI.
//

import Foundation
import UIKit
import GoogleGenerativeAI

actor RoomScanService {
    static let shared = RoomScanService()

    private let model: GenerativeModel

    private init() {
        self.model = GenerativeModel(
            name: "gemini-2.5-flash",
            apiKey: AppConstants.API.geminiAPIKey,
            generationConfig: GenerationConfig(
                responseMimeType: "application/json"
            )
        )
    }

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

        // 1. Build the prompt
        let prompt = """
        You are a world-class interior design AI for Williams-Sonoma.
        Analyze the provided room image(s) and user preferences carefully.

        User preferences:
        - Shopping for: \(preferences.dto.category.isEmpty ? "Anything" : preferences.dto.category)
        - Size preference: \(preferences.dto.size.isEmpty ? "Any" : preferences.dto.size)
        - Budget max: $\(preferences.dto.budgetMax == 0 ? 1000 : preferences.dto.budgetMax)
        - Style: \(preferences.dto.styleVibe.isEmpty ? "Any" : preferences.dto.styleVibe)

        Your job:
        1. Identify the room type precisely (kitchen, living_room, dining_room, bedroom, bathroom, outdoor_patio).
        2. Deeply analyze the visual foundation of the room: look at the background colors, the wall paint, any wallpaper patterns, flooring, and dominant textures.
        3. Identify the overall design style (e.g., minimalist, rustic, farmhouse, mid-century modern).
        4. Reason about what would actually *look good* in this exact space. Would a certain material clash with the wallpaper? Would a specific color pop beautifully against the wall paint?
        5. Based on this visual harmony, recommend Williams-Sonoma product categories that would genuinely complement the room. Use these exact category names where applicable: Cookware, Knives & Cutlery, Bakeware, Electrics, Kitchen Tools, Coffee & Tea, Outdoor & BBQ, Tabletop & Bar, Food & Pantry, Storage & Organization, Cleaning, Gifts & Registry.
        6. Return structured JSON only — no prose, no markdown, no explanation.

        Return ONLY this JSON schema format exactly (use snake_case keys):
        {
          "room_type": "string",
          "detected_style": "string",
          "dominant_colors": ["string"],
          "dominant_materials": ["string"],
          "recommended_style_tags": ["string"],
          "recommended_categories": ["string"],
          "price_max": 100.0,
          "size_preference": "string",
          "reasoning": "string",
          "negative_categories": ["string"]
        }
        """

        // 2. Prepare inputs (text + images)
        var inputParts: [PartsRepresentable] = [prompt]
        for image in images {
            if let compressedData = compressImage(image), let compressedImage = UIImage(data: compressedData) {
                inputParts.append(compressedImage)
            } else {
                inputParts.append(image)
            }
        }

        // 3. Generate content directly from Gemini
        let response: GenerateContentResponse
        do {
            response = try await model.generateContent(inputParts)
        } catch {
            print("Gemini API error: \(error)")
            throw RoomScanError.serverError(500)
        }

        guard let text = response.text else {
            throw RoomScanError.decodingError
        }

        // 4. Clean JSON string (remove markdown block if present)
        let cleanedText = text
            .replacingOccurrences(of: "```json\n", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw RoomScanError.decodingError
        }

        // 5. Decode to RoomAnalysisResult
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            var aiResult = try decoder.decode(RoomAnalysisResult.self, from: jsonData)
            
            // 6. Fetch products matching recommended categories locally from WSService
            let allProducts = try await WSService.shared.fetchProducts()
            let recommendedCategories = aiResult.recommendedCategories
            
            let matchedProducts = allProducts.filter { product in
                recommendedCategories.contains(product.category)
            }
            
            // Limit to 20 for UI performance, just like the backend did
            aiResult.recommendedProducts = Array(matchedProducts.prefix(20))
            
            return aiResult
        } catch {
            print("Room analysis decoding error: \(error)")
            print("Raw text from Gemini: \(cleanedText)")
            throw RoomScanError.decodingError
        }
    }
}
