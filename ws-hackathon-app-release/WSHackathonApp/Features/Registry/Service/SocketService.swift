
import Foundation
import Combine

#if canImport(SocketIO)
import SocketIO
#endif

@MainActor
final class SocketService: ObservableObject {
    static let shared = SocketService()

    private var cartHandler: ((CartUpdatePayload) -> Void)?
    private var memberHandler: ((MemberPayload) -> Void)?
    private var registryId: String?

    private init() {

    }

    func connect(registryId: String) {
        self.registryId = registryId

        print("SocketService: Ready for Supabase Realtime for registry \(registryId)")
    }

    func disconnect() {
        registryId = nil
        print("SocketService: Disconnected")
    }

    func onCartUpdated(_ handler: @escaping (CartUpdatePayload) -> Void) {
        cartHandler = handler
    }

    func onMemberChanged(_ handler: @escaping (MemberPayload) -> Void) {
        memberHandler = handler
    }

}
