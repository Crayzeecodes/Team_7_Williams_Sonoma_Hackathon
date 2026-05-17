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
            apiKey: Self.getGeminiAPIKey(),
            generationConfig: GenerationConfig(
                responseMIMEType: "application/json"
            )
        )
    }

    // MARK: - API Key Helper
    nonisolated private static func getGeminiAPIKey() -> String {
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil),
              let content = try? String(contentsOfFile: path) else {
            print("⚠️ .env file not found or could not be read! Ensure it is added to Xcode's target.")
            return ""
        }
        
        for line in content.components(separatedBy: .newlines) {
            let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2, parts[0] == "GEMINI_API_KEY" {
                return parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return ""
    }

    // MARK: - Image Compression
    /// Compresses image to max 1024px longest side, JPEG quality 0.7
    @MainActor
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
        4. Reason about what would actually *look good* in this exact space. Why did you choose these categories? Format your reasoning strictly as bullet points (use `- ` for each point, separated by `\n`).
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
        var inputParts: [ModelContent.Part] = [.text(prompt)]
        for image in images {
            if let compressedData = await compressImage(image) {
                inputParts.append(.data(mimetype: "image/jpeg", compressedData))
            }
        }
        let content = ModelContent(role: "user", parts: inputParts)

        // 3. Generate content directly from Gemini
        let response: GenerateContentResponse
        do {
            response = try await model.generateContent([content])
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
            let wsService = await WSService.shared
            let allProducts = try await wsService.fetchProducts()
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
