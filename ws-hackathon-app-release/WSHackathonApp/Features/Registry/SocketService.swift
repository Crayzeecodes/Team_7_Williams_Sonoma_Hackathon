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

    #if canImport(SocketIO)
    private let manager = SocketManager(socketURL: APIConfig.socketURL, config: [.log(false), .compress])
    private lazy var socket = manager.defaultSocket
    #endif

    private init() {
        #if canImport(SocketIO)
        registerEvents()
        #endif
    }

    func connect(registryId: String) {
        self.registryId = registryId
        #if canImport(SocketIO)
        if socket.status != .connected {
            socket.connect()
        } else {
            socket.emit("joinRoom", registryId)
        }
        #endif
    }

    func disconnect() {
        #if canImport(SocketIO)
        if let registryId {
            socket.emit("leaveRoom", registryId)
        }
        socket.disconnect()
        #endif
        registryId = nil
    }

    func onCartUpdated(_ handler: @escaping (CartUpdatePayload) -> Void) {
        cartHandler = handler
    }

    func onMemberChanged(_ handler: @escaping (MemberPayload) -> Void) {
        memberHandler = handler
    }

    #if canImport(SocketIO)
    private func registerEvents() {
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            guard let self, let registryId = self.registryId else { return }
            self.socket.emit("joinRoom", registryId)
        }

        socket.on("registry:cartUpdated") { [weak self] data, _ in
            guard
                let payload = Self.decodeEvent(CartUpdatePayload.self, from: data.first)
            else { return }
            self?.cartHandler?(payload)
        }

        socket.on("registry:memberJoined") { [weak self] data, _ in
            guard
                let payload = Self.decodeEvent(MemberPayload.self, from: data.first)
            else { return }
            self?.memberHandler?(payload)
        }

        socket.on("registry:memberLeft") { [weak self] data, _ in
            guard
                let payload = Self.decodeEvent(MemberPayload.self, from: data.first)
            else { return }
            self?.memberHandler?(payload)
        }
    }

    private static func decodeEvent<T: Decodable>(_ type: T.Type, from value: Any?) -> T? {
        guard
            let value,
            JSONSerialization.isValidJSONObject(value),
            let data = try? JSONSerialization.data(withJSONObject: value)
        else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: data)
    }
    #endif
}
