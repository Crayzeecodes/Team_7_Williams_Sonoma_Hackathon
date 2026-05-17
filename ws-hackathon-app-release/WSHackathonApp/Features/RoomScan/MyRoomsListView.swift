//
//  MyRoomsListView.swift
//  WSHackathonApp
//
//  Displays the user's custom rooms for AR placement.
//

import SwiftUI

struct MyRoom: Identifiable, Codable {
    let id: UUID
    var name: String
    var screenshotData: [Data] // Store screenshot JPEG data locally
    var productIds: [String]
    
    // Legacy compat
    var screenshotUrls: [String] { [] }
}

@available(iOS 18.0, *)
struct MyRoomsListView: View {
    var body: some View {
        Group {
            if MyRoomStorage.shared.rooms.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "house")
                            .font(.system(size: 60, weight: .ultraLight))
                            .foregroundStyle(Color.secondary)
                        Text("No Rooms Yet")
                            .font(.title2).bold()
                        Text("Tap + above to create a room and start placing furniture in AR.")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else {
                    List {
                        VStack(spacing: 8) {
                            Image(systemName: "house")
                                .font(.system(size: 48, weight: .ultraLight))
                                .foregroundStyle(Color.primary)
                                .padding(.bottom, 4)

                            Text("My Rooms")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color.primary)

                            Text("View your saved rooms and AR snapshots.")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                        .padding(.bottom, 16)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        
                        ForEach(MyRoomStorage.shared.rooms) { room in
                        ZStack {
                            NavigationLink(destination: MyRoomDetailView(roomId: room.id)) {
                                EmptyView()
                            }
                            .opacity(0)
                            
                            HStack(spacing: 14) {
                                // Thumbnail
                                if let firstScreenshot = room.screenshotData.first,
                                   let uiImage = UIImage(data: firstScreenshot) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 64, height: 64)
                                        .clipShape(RoundedRectangle(cornerRadius: 25))
                                } else {
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color(uiColor: .tertiarySystemFill))
                                        .frame(width: 64, height: 64)
                                        .overlay(
                                            Image(systemName: "cube.transparent")
                                                .font(.system(size: 24, weight: .light))
                                                .foregroundStyle(.secondary)
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(room.name)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(Color.primary)
                                    HStack(spacing: 12) {
                                        Label("\(room.screenshotData.count) snaps", systemImage: "camera")
                                        Label("\(room.productIds.count) products", systemImage: "cube")
                                    }
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
                            }
                        .padding(14)
                        .frame(minHeight: 80)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                    .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                        .onDelete(perform: MyRoomStorage.shared.deleteRoom)
                    }
                    .listStyle(.plain)
                }
        }
    }
}
