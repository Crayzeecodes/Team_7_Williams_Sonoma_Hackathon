//
//  RegistryViewModel.swift
//  WSHackathonApp
//
//  Created by Nilesh Mahajan on 05/04/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class RegistryViewModel: ObservableObject {
    
    @Published private(set) var registry: Registry?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Bind Repository
    
    func bind(repository: RegistryRepository) {
        repository.$currentRegistry
            .receive(on: RunLoop.main)
            .assign(to: &$registry)
    }
    
    // MARK: - Computed
    
    var hasRegistry: Bool {
        registry != nil
    }
    
    var hasItems: Bool {
        !(registry?.items.isEmpty ?? true)
    }
    
    var items: [RegistryItem] {
        registry?.items ?? []
    }
    
    var displayTitle: String {
        registry?.displayName ?? ""
    }
    
    var displayDate: String {
        guard let date = registry?.date else { return "" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
    
    // MARK: - Instructions
    
    var instructions: [RegistryInstruction] {
        [
            RegistryInstruction(
                title: AppStrings.Registry.exclusiveProduct,
                description: AppStrings.Registry.exclusiveProductsDesc
            ),
            RegistryInstruction(
                title: AppStrings.Registry.expertAdvice,
                description: AppStrings.Registry.expertAdviceDesc
            ),
            RegistryInstruction(
                title: AppStrings.Registry.discountTitle,
                description: AppStrings.Registry.discountDesc
            ),
            RegistryInstruction(
                title: AppStrings.Registry.inStoreTitle,
                description: AppStrings.Registry.instStoreDesc
            )
        ]
    }
    
    // MARK: - Actions
    
    func deleteRegistry(using repository: RegistryRepository) {
        repository.deleteRegistry()
    }
}
