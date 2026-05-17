//
//  RoomScanHistoryService.swift
//  WSHackathonApp
//
//  Service for managing Room Scan history via Supabase.
//

import Foundation
import Supabase
import UIKit

@MainActor
final class RoomScanHistoryService {
    static let shared = RoomScanHistoryService()
    
    private init() {}
    
    private var deviceId: String {
        if let id = UserDefaults.standard.string(forKey: "ws_device_id") {
            return id
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "ws_device_id")
        return newId
    }
    
    /// Uploads an image to Supabase Storage and returns the public URL
    func uploadImage(_ image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw URLError(.badServerResponse)
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        let path = "scans/\(fileName)"
        
        try await supabase.storage.from("room_scans").upload(
            path,
            data: data,
            options: FileOptions(contentType: "image/jpeg")
        )
        
        let url = try supabase.storage.from("room_scans").getPublicURL(path: path)
        return url.absoluteString
    }
    
    /// Saves the scan result to Supabase
    func saveScanResult(images: [UIImage], result: RoomAnalysisResult, recommendedProducts: [WSProduct]) async throws {
        var imageUrls: [String] = []
        for image in images {
            let url = try await uploadImage(image)
            imageUrls.append(url)
        }
        
        let insertData = RoomScanHistoryInsert(
            deviceId: deviceId,
            imageUrls: imageUrls,
            roomType: result.roomType,
            detectedStyle: result.detectedStyle,
            dominantColors: result.dominantColors,
            dominantMaterials: result.dominantMaterials,
            reasoning: result.reasoning,
            recommendedProductIds: recommendedProducts.map { $0.id.uuidString }
        )
        
        try await supabase.from("room_scan_history").insert(insertData).execute()
    }
    
    /// Fetches all past scans for the current device
    func fetchHistory() async throws -> [RoomScanHistoryRecord] {
        let records: [RoomScanHistoryRecord] = try await supabase
            .from("room_scan_history")
            .select()
            .eq("device_id", value: deviceId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return records
    }
}
