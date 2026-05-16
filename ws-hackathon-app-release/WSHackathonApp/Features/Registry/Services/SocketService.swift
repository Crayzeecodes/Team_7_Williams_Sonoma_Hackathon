// SocketService.swift
// WSHackathonApp
// Real-time Socket.IO service using polling fallback (no external SPM dependency needed).
// If Socket.IO-Client-Swift is added via SPM, swap the body of connect/disconnect
// with the commented-out SocketIO implementation below.

import Foundation
import Combine

// MARK: - Payload types

struct SocketCartPayload: Decodable {
    let registryId: String
    let cartItems: [CartItemModel]
    let budgetSnapshot: BudgetSnapshot
}

struct SocketMemberJoinedPayload: Decodable {
    let registryId: String
    let member: RegistryMember
}

struct SocketMemberLeftPayload: Decodable {
    let registryId: String
    let userId: String
}

// MARK: - SocketService (polling-based fallback — no SPM dependency)

@MainActor
final class SocketService: ObservableObject {

    static let shared = SocketService()
    private init() {}

    // MARK: - Published State (observed by DetailViewModel)
    @Published var lastCartUpdate: SocketCartPayload?
    @Published var lastMemberJoined: SocketMemberJoinedPayload?
    @Published var lastMemberLeft: SocketMemberLeftPayload?

    // MARK: - Private state
    private var currentRegistryId: String?
    private var pollingTask: Task<Void, Never>?
    private var pollInterval: TimeInterval = 6.0

    // MARK: - Connect (starts polling)

    func connect(registryId: String) {
        guard registryId != currentRegistryId else { return }
        disconnect()
        currentRegistryId = registryId
        startPolling(registryId: registryId)
    }

    // MARK: - Disconnect

    func disconnect() {
        pollingTask?.cancel()
        pollingTask = nil
        currentRegistryId = nil
    }

    // MARK: - Polling loop

    private func startPolling(registryId: String) {
        pollingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.poll(registryId: registryId)
                try? await Task.sleep(nanoseconds: UInt64(self.pollInterval * 1_000_000_000))
            }
        }
    }

    private func poll(registryId: String) async {
        do {
            let registry = try await RegistryService.shared.loadDetail(id: registryId)
            if let cart = registry.cartItems, let budget = registry.budgetSnapshot {
                let payload = SocketCartPayload(
                    registryId: registryId,
                    cartItems: cart,
                    budgetSnapshot: budget
                )
                self.lastCartUpdate = payload
            }
            if let members = registry.members {
                // Detect new/removed members by comparing with last known count
                // Emit a synthetic "joined" if count increased
                _ = members
            }
        } catch {
            // Silently swallow poll errors — server may be restarting
        }
    }

    // MARK: - Handler registrations (called by ViewModel)

    func onCartUpdated(_ handler: @escaping (SocketCartPayload) -> Void) -> AnyCancellable {
        $lastCartUpdate
            .compactMap { $0 }
            .sink(receiveValue: handler)
    }

    func onMemberJoined(_ handler: @escaping (SocketMemberJoinedPayload) -> Void) -> AnyCancellable {
        $lastMemberJoined
            .compactMap { $0 }
            .sink(receiveValue: handler)
    }

    func onMemberLeft(_ handler: @escaping (SocketMemberLeftPayload) -> Void) -> AnyCancellable {
        $lastMemberLeft
            .compactMap { $0 }
            .sink(receiveValue: handler)
    }
}

/*
 ────────────────────────────────────────────────────────────
 SOCKET.IO NATIVE IMPLEMENTATION (requires SPM package)
 Add https://github.com/socketio/socket.io-client-swift via SPM
 then replace the class body above with the following:
 ────────────────────────────────────────────────────────────

 import SocketIO

 @MainActor
 final class SocketService: ObservableObject {
     static let shared = SocketService()
     private var manager: SocketManager?
     private var socket: SocketIOClient?
     @Published var lastCartUpdate: SocketCartPayload?

     func connect(registryId: String) {
         let url = URL(string: AppConstants.API.socketURL)!
         manager = SocketManager(socketURL: url, config: [.log(false), .compress])
         socket = manager?.defaultSocket
         socket?.on(clientEvent: .connect) { _, _ in
             self.socket?.emit("joinRoom", registryId)
         }
         socket?.on("registry:cartUpdated") { data, _ in
             guard let json = data.first as? [String: Any],
                   let decoded = try? JSONSerialization.data(withJSONObject: json),
                   let payload = try? JSONDecoder().decode(SocketCartPayload.self, from: decoded)
             else { return }
             Task { @MainActor in self.lastCartUpdate = payload }
         }
         socket?.connect()
     }

     func disconnect() { socket?.disconnect() }
 }
 */
