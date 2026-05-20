
import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: APIConfig.defaultBaseURLString)!,
    supabaseKey: APIConfig.supabaseAnonKey,
    options: SupabaseClientOptions(
        auth: SupabaseClientOptions.AuthOptions(
            emitLocalSessionAsInitialSession: true
        )
    )
)
