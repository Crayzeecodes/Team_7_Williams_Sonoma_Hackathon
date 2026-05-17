
import SwiftUI

@available(iOS 18.0, *)
struct RoomScanRootView: View {
    @State private var selectedMode = 0
    @State private var showingCreateRoom = false
    @State private var newRoomName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                Picker("Mode", selection: $selectedMode) {
                    Text("AI Suggestions").tag(0)
                    Text("My Rooms").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Group {
                    if selectedMode == 0 {
                        RoomScanContainerView()
                    } else {
                        MyRoomsListView()
                    }
                }
                .animation(.none, value: selectedMode)
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedMode == 1 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingCreateRoom = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
            }
            .alert("Create Room", isPresented: $showingCreateRoom) {
                TextField("Room Name (e.g. Living Room)", text: $newRoomName)
                Button(role: .cancel) { newRoomName = "" } label: {
                    Image(systemName: "xmark")
                }
                Button("Create") {
                    let room = MyRoom(id: UUID(), name: newRoomName, screenshotData: [], productIds: [])
                    MyRoomStorage.shared.addRoom(room)
                    newRoomName = ""
                }
            }
        }
    }
}
