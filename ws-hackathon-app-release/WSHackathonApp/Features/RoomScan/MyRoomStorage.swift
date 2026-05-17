
import Foundation
import SwiftUI

@Observable
class MyRoomStorage {
    static let shared = MyRoomStorage()

    var rooms: [MyRoom] = []

    private init() {
        loadRooms()
    }

    func loadRooms() {
        if let data = UserDefaults.standard.data(forKey: "my_rooms"),
           let saved = try? JSONDecoder().decode([MyRoom].self, from: data) {
            self.rooms = saved
        }
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(rooms) {
            UserDefaults.standard.set(encoded, forKey: "my_rooms")
        }
    }

    func addRoom(_ room: MyRoom) {
        rooms.append(room)
        save()
    }

    func updateRoom(_ room: MyRoom) {
        if let idx = rooms.firstIndex(where: { $0.id == room.id }) {
            rooms[idx] = room
            save()
        }
    }

    func deleteRoom(at offsets: IndexSet) {
        rooms.remove(atOffsets: offsets)
        save()
    }
}
