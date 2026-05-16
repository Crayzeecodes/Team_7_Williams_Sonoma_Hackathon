//
//  RegistryListViewModel.swift
//  WSHackathonApp
//

import Foundation
import Combine

@MainActor
final class RegistryListViewModel: ObservableObject {
    @Published var registries: [Registry] = []
    @Published var searchText: String = ""
    @Published var filter: RegistryFilter = .all
    @Published var isLoading: Bool = false
    @Published var isPresentingCreateRegistry: Bool = false
    @Published var createRegistryType: RegistryType = .event
    @Published var isPresentingJoinRegistry: Bool = false
    @Published var joinCode: String = ""
    @Published var joinContributionText: String = ""
    @Published var joinPreview: RegistryPreview?
    @Published var joinErrorMessage: String?
    @Published var isJoining: Bool = false

    private let registryService: RegistryService

    init() {
        self.registryService = .shared
    }

    var filteredRegistries: [Registry] {
        registries
            .filter { registry in
                switch filter {
                case .all:
                    return true
                case .events:
                    return registry.registryType == .event
                case .gifting:
                    return registry.registryType == .gifting
                }
            }
            .filter { registry in
                guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return true }
                let query = searchText.lowercased()
                return registry.name.lowercased().contains(query) || registry.eventType.title.lowercased().contains(query)
            }
            .sorted { $0.eventDate < $1.eventDate }
    }

    func loadRegistries() async {
        isLoading = true
        defer { isLoading = false }

        do {
            registries = try await registryService.loadRegistries()
        } catch {
            joinErrorMessage = error.localizedDescription
        }
    }

    func joinRegistry(code: String) async throws {
        isJoining = true
        defer { isJoining = false }

        let budgetContribution = Double(joinContributionText.filter { "0123456789.".contains($0) })
        let joined = try await registryService.joinRegistry(code: code, contributedBudget: budgetContribution)
        if !registries.contains(where: { $0.id == joined.id }) {
            registries.append(joined)
        }
        registries.sort { $0.eventDate < $1.eventDate }
        resetJoinFlow()
    }

    func prepareCreate(_ type: RegistryType) {
        createRegistryType = type
        isPresentingCreateRegistry = true
    }

    func previewJoinRegistry() async {
        let uppercased = String(joinCode.uppercased().prefix(6))
        if joinCode != uppercased {
            joinCode = uppercased
        }

        guard joinCode.count == 6 else {
            joinPreview = nil
            joinContributionText = ""
            return
        }

        do {
            joinPreview = try await registryService.previewRegistry(joinCode: joinCode)
            joinErrorMessage = nil
        } catch {
            joinPreview = nil
            joinErrorMessage = error.localizedDescription
        }
    }

    func resetJoinFlow() {
        joinCode = ""
        joinContributionText = ""
        joinPreview = nil
        joinErrorMessage = nil
        isPresentingJoinRegistry = false
    }

    func appendCreatedRegistry(_ registry: Registry) {
        if !registries.contains(where: { $0.id == registry.id }) {
            registries.append(registry)
            registries.sort { $0.eventDate < $1.eventDate }
        }
    }
}
