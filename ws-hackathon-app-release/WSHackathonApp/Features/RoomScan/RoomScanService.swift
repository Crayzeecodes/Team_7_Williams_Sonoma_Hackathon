//
//  RoomScanService.swift
//  WSHackathonApp
//
//  Created by Zeeshan Khan on 20/05/26.
//


import Foundation
import UIKit
import GoogleGenerativeAI

actor RoomScanService {
    static let shared = RoomScanService()

    private let model: GenerativeModel

    private init() {
        self.model = GenerativeModel(
            name: "gemini-2.5-flash-lite",
            apiKey: Self.getGeminiAPIKey()
        )
    }

    nonisolated private static func getGeminiAPIKey() -> String {
        if let path = Bundle.main.path(forResource: ".env", ofType: nil),
           let content = try? String(contentsOfFile: path) {
            for line in content.components(separatedBy: .newlines) {
                let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
                if parts.count == 2, parts[0] == "GEMINI_API_KEY" {
                    let val = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !val.isEmpty {
                        let prefix = String(val.prefix(4))
                        let suffix = String(val.suffix(4))
                        print("🔑 Room Scan service loaded Gemini API Key: \(prefix)...\(suffix) (Length: \(val.count))")
                        return val
                    }
                }
            }
        }
        
        return "YOUR_GEMINI_API_KEY_HERE"
    }

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

    func analyzeRoom(
        images: [UIImage],
        preferences: RoomScanPreferences
    ) async throws -> RoomAnalysisResult {

        guard !images.isEmpty else { throw RoomScanError.noImages }

        let prompt = """
        You are a world-class interior design AI and product recommendation engine for Williams-Sonoma.

        You will be given one or more room images alongside user preferences. Your job is to deeply analyze the visual space and return a structured JSON object that drives product recommendations — matching both the room's aesthetic and the user's stated intent.

        ---

        USER PREFERENCES:
        - Shopping for: \(preferences.dto.category.isEmpty ? "Anything" : preferences.dto.category)
        - Size preference: \(preferences.dto.size.isEmpty ? "Any" : preferences.dto.size)
        - Budget max: $\(preferences.dto.budgetMax == 0 ? 1000 : preferences.dto.budgetMax)
        - Style vibe: \(preferences.dto.styleVibe.isEmpty ? "Any" : preferences.dto.styleVibe)

        ---

        HOW TO REASON (work through each step before producing output):

        STEP 1 — IDENTIFY THE ROOM
        Determine the precise room type from the image.
        Choose exactly one: kitchen, living_room, dining_room, bedroom, bathroom, outdoor_patio.
        If ambiguous, pick the one that best fits the dominant use visible.

        STEP 2 — READ THE VISUAL FOUNDATION
        Analyze what you can directly see:
        - Wall color, paint finish, or wallpaper pattern
        - Flooring material and tone (hardwood, marble, tile, carpet, etc.)
        - Dominant furniture materials (wood, metal, upholstery, rattan, etc.)
        - Lighting style (natural, warm ambient, cool overhead)
        - Overall color palette and its temperature (warm/cool/neutral)

        STEP 3 — IDENTIFY THE DESIGN STYLE
        Name the interior design style precisely.
        Examples: minimalist, japandi, farmhouse, mid-century modern, coastal, maximalist, industrial, scandinavian, transitional, eclectic.
        Do NOT default to generic labels — use what you actually see.

        STEP 4 — DETERMINE WHAT WOULD GENUINELY COMPLEMENT THIS SPACE
        Ask: if a Williams-Sonoma stylist walked into this exact room, what product would they place first?
        Reason about both:
          a) Visual harmony — does this product's material, color, and form belong in this room?
          b) Functional fit — does this product serve the activities that happen in this room?

        Cross-check against user preferences:
          - If the user named a category, prioritize it — but only if it makes sense for this room type.
          - If the user named a style vibe, confirm it matches what you see. If it conflicts, trust the image.
          - Respect the budget max in price_max output.

        STEP 5 — SELECT CATEGORIES
        Choose from ONLY these exact category names:
        Cookware, Knives & Cutlery, Bakeware, Electrics, Kitchen Tools, Coffee & Tea, Outdoor & BBQ, Tabletop & Bar, Food & Pantry, Storage & Organization, Cleaning, Gifts & Registry, Furniture, Home Essentials, Holidays, New, Sale

        Rules:
        - recommended_categories: 2–4 categories that genuinely fit this room and user context.
        - negative_categories: categories that would look out of place or serve no function here (be specific — not just everything that isn't recommended).
        - Do NOT include a category in both lists.

        STEP 6 — WRITE REASONING
        Summarize your visual analysis as exactly 3 concise bullet points using `- ` prefix, separated by `\n`.
        Each bullet must state a specific observation from the image and explain why it drives a recommendation.
        Bad: "- The room looks modern so we suggest modern products."
        Good: "- Exposed concrete walls and matte black fixtures signal an industrial aesthetic — Tabletop & Bar products in dark metal finishes would integrate naturally.\n- The open-plan layout with a visible kitchen island suggests active cooking use — Cookware and Kitchen Tools are a functional fit.\n- Warm Edison bulb lighting and reclaimed wood shelving indicate a preference for tactile, artisan materials — Food & Pantry products in ceramic or linen packaging would complement the vibe."

        ---

        CATALOG CONTEXT:
        When selecting categories, treat each as containing products with specific names, descriptions, and materials — not just a label.
        For example: "Home Essentials" contains both sofa cushions AND outdoor rugs — recommend it only if the specific products in that category match this room's context.
        "Outdoor & BBQ" should only appear for outdoor spaces or rooms with visible grill/patio adjacency.

        ---

        Return ONLY this JSON — no markdown, no prose, no extra keys:
        {
          "room_type": "string",
          "detected_style": "string",
          "dominant_colors": ["string"],
          "dominant_materials": ["string"],
          "recommended_style_tags": ["string"],
          "recommended_categories": ["string"],
          "negative_categories": ["string"],
          "price_max": 0.0,
          "size_preference": "string",
          "reasoning": "string"
        }
        """

        var inputParts: [ModelContent.Part] = [.text(prompt)]
        for image in images {
            if let compressedData = await compressImage(image) {
                inputParts.append(.data(mimetype: "image/jpeg", compressedData))
            }
        }
        let content = ModelContent(role: "user", parts: inputParts)

        var response: GenerateContentResponse?
        var lastError: Error?
        var currentDelay: Double = 1.0
        let maxAttempts = 3

        for attempt in 1...maxAttempts {
            do {
                response = try await model.generateContent([content])
                break
            } catch {
                lastError = error
                let errStr = String(describing: error)
                if errStr.contains("503") || errStr.contains("429") || errStr.contains("unavailable") {
                    print("⚠️ Room Scan Service encountered temporary error (Attempt \(attempt)/\(maxAttempts)): \(error). Retrying in \(currentDelay)s...")
                    try? await Task.sleep(nanoseconds: UInt64(currentDelay * 1_000_000_000))
                    currentDelay *= 2.0
                } else {
                    break // Non-retriable error
                }
            }
        }

        guard let finalResponse = response else {
            let finalErr = lastError ?? RoomScanError.decodingError
            print("Gemini API error after retries: \(finalErr)")
            throw RoomScanError.networkError(finalErr)
        }

        guard let text = finalResponse.text else {
            throw RoomScanError.decodingError
        }

        let cleanedText = text
            .replacingOccurrences(of: "```json\n", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .sanitizingJSONControlCharacters()

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw RoomScanError.decodingError
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            var aiResult = try decoder.decode(RoomAnalysisResult.self, from: jsonData)

            let wsService = await WSService.shared
            let allProducts = try await wsService.fetchProducts()
            let recommendedCategories = aiResult.recommendedCategories

            let matchedProducts = allProducts.filter { product in
                recommendedCategories.contains(product.category)
            }

            aiResult.recommendedProducts = Array(matchedProducts.prefix(20))

            return aiResult
        } catch {
            print("Room analysis decoding error: \(error)")
            print("Raw text from Gemini: \(cleanedText)")
            throw RoomScanError.decodingError
        }
    }
}
