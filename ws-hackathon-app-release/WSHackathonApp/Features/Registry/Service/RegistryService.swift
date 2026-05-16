//
//  RegistryService.swift
//  WSHackathonApp
//

import Foundation
import Supabase

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

    private init() {}

    func loadRegistries() async throws -> [Registry] {
        try await supabase
            .from("registries")
            .select()
            .execute()
            .value
    }

    func previewRegistry(joinCode: String) async throws -> RegistryPreview {
        let previews: [RegistryPreview] = try await supabase
            .from("registries")
            .select()
            .eq("join_code", value: joinCode)
            .execute()
            .value
            
        guard let preview = previews.first else {
            throw RegistryServiceError.serverError("Registry not found")
        }
        return preview
    }

    func createRegistry(_ requestBody: CreateRegistryRequest) async throws -> Registry {
        // 1. Insert into registries table
        let registry: Registry = try await supabase
            .from("registries")
            .insert(requestBody)
            .select() // Equivalent to return=representation
            .single()
            .execute()
            .value
        
        guard let registryId = registry.supabaseId else {
            throw RegistryServiceError.invalidResponse
        }
        
        // 2. Insert into registry_members table to make the creator an admin
        let memberRequest = RegistryMemberRequest(
            registryId: registryId,
            userId: requestBody.adminId ?? "",
            role: .admin,
            contributedBudget: 0,
            joinedAt: Date()
        )
        
        try await supabase
            .from("registry_members")
            .insert(memberRequest)
            .execute()
            
        return registry
    }

    func joinRegistry(code: String, contributedBudget: Double?) async throws -> Registry {
        // The mock backend used a custom RPC or endpoint for this. 
        // We might need to implement this as an RPC or manual logic.
        // Assuming we look up the registry, then insert a member.
        let registry = try await previewRegistry(joinCode: code)
        guard let registryId = registry.supabaseId else { throw RegistryServiceError.invalidResponse }
        
        guard let session = try? await supabase.auth.session else {
            throw RegistryServiceError.serverError("Please log in to join.")
        }
        
        let memberRequest = RegistryMemberRequest(
            registryId: registryId,
            userId: session.user.id.uuidString,
            role: .collaborator,
            contributedBudget: contributedBudget ?? 0,
            joinedAt: Date()
        )
        
        try await supabase
            .from("registry_members")
            .insert(memberRequest)
            .execute()
            
        return try await loadRegistry(id: registryId)
    }

    func loadRegistry(id: String) async throws -> Registry {
        let registries: [Registry] = try await supabase
            .from("registries")
            .select()
            .eq("id", value: id)
            .execute()
            .value
            
        guard let registry = registries.first else {
            throw RegistryServiceError.serverError("Registry not found")
        }
        return registry
    }

    func leaveRegistry(id: String) async throws -> LeaveRegistryResponse {
        guard let session = try? await supabase.auth.session else {
            throw RegistryServiceError.serverError("Please log in to leave.")
        }
        
        try await supabase
            .from("registry_members")
            .delete()
            .eq("registry_id", value: id)
            .eq("user_id", value: session.user.id.uuidString)
            .execute()
            
        return LeaveRegistryResponse(deleted: true, registryId: id, registry: nil)
    }

    func addCartItem(registryId: String, requestBody: AddRegistryCartItemRequest) async throws -> CartUpdatePayload {
        throw RegistryServiceError.serverError("RPC not implemented natively yet.")
    }

    func removeCartItem(registryId: String, itemId: String) async throws -> CartUpdatePayload {
        throw RegistryServiceError.serverError("RPC not implemented natively yet.")
    }

    func refreshSuggestions(registryId: String, forceRefresh: Bool) async throws -> [RegistryAISuggestion] {
        // Mock returning empty for now as it used a custom endpoint
        return []
    }

    func loadMembers(registryId: String) async throws -> [RegistryMemberDisplay] {
        try await supabase
            .from("registry_members")
            .select()
            .eq("registry_id", value: registryId)
            .execute()
            .value
    }
}

struct LeaveRegistryResponse: Codable {
    let deleted: Bool
    let registryId: String?
    let registry: Registry?
}
