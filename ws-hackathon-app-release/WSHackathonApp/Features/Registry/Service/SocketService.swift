//
//  SocketService.swift
//  WSHackathonApp
//

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

    // TODO: Replace with Supabase Realtime (RealtimeChannel)
    /*
    #if canImport(SocketIO)
    private let manager = SocketManager(socketURL: APIConfig.socketURL, config: [.log(false), .compress])
    private lazy var socket = manager.defaultSocket
    #endif
    */

    private init() {
        /*
        #if canImport(SocketIO)
        registerEvents()
        #endif
        */
    }

    func connect(registryId: String) {
        self.registryId = registryId
        // Supabase Realtime connection logic goes here
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

    /*
    #if canImport(SocketIO)
    private func registerEvents() {
        // ... Socket.io implementation removed for Supabase migration ...
    }
    #endif
    */
}
