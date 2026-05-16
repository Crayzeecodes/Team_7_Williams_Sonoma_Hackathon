//
//  SupabaseClient.swift
//  WSHackathonApp
//

import Foundation
import Supabase

/// A globally accessible, shared Supabase client instance.
/// The SDK automatically handles token storage, refreshing, and HTTP headers.
let supabase = SupabaseClient(
    supabaseURL: URL(string: APIConfig.defaultBaseURLString)!,
    supabaseKey: APIConfig.supabaseAnonKey
)
