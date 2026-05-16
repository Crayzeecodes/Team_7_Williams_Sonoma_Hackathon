// RegistryListViewModel.swift
// WSHackathonApp

import Foundation
import Combine

// MARK: - Filter

enum RegistryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case events = "Events"
    case gifting = "Gifting"
    var id: String { rawValue }
}

// MARK: - ViewModel

@MainActor
final class RegistryListViewModel: ObservableObject {

    // MARK: - Published

    @Published var registries: [RegistryModel] = []
    @Published var searchText: String = ""
    @Published var selectedFilter: RegistryFilter = .all
    @Published var isLoading: Bool = false
    @Published var error: String?

    // Sheet / cover state
    @Published var showCreateEventSheet: Bool = false
    @Published var showCreateGiftingSheet: Bool = false
    @Published var showJoinSheet: Bool = false
    @Published var showCreateActionSheet: Bool = false

    // MARK: - Computed: filtered list

    var filteredRegistries: [RegistryModel] {
        var result = registries

        // Type filter
        switch selectedFilter {
        case .all:
            break
        case .events:
            result = result.filter { $0.registryType == .event }
        case .gifting:
            result = result.filter { $0.registryType == .gifting }
        }

        // Search filter
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                ($0.eventType?.displayName.lowercased().contains(query) ?? false) ||
                ($0.creatorName?.lowercased().contains(query) ?? false)
            }
        }

        return result
    }

    // MARK: - Load

    func loadRegistries() async {
        isLoading = true
        error = nil
        do {
            let loaded = try await RegistryService.shared.loadAll()
            registries = loaded
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Join

    func joinRegistry(code: String, budget: Double?) async throws -> RegistryModel {
        let joined = try await RegistryService.shared.join(code: code, contributedBudget: budget)
        // Append only if not already in list
        if !registries.contains(where: { $0.id == joined.id }) {
            registries.append(joined)
        }
        return joined
    }

    // MARK: - Append after create

    func appendRegistry(_ registry: RegistryModel) {
        registries.append(registry)
    }

    // MARK: - Remove after leave

    func removeRegistry(id: String) {
        registries.removeAll { $0.id == id }
    }
}
