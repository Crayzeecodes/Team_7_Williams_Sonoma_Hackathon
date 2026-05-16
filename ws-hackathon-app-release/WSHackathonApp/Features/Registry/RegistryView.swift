// RegistryView.swift
// WSHackathonApp
// This is now a thin wrapper that delegates to RegistryListView.
// The old stub RegistryViewModel, Registry, RegistryEvent, RegistryItem
// are superseded by the full models in Features/Registry/Models/.

import SwiftUI

/// Entry point for the Registry tab (used by WSTabView).
/// Delegates entirely to RegistryListView which owns its own NavigationStack.
struct RegistryView: View {
    var body: some View {
        RegistryListView()
    }
}
