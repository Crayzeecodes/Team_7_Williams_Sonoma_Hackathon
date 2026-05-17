//
//  RoomScanEntryView.swift
//  WSHackathonApp
//
//  Camera/photo capture options screen — first step of Room Scan flow.
//

import SwiftUI

struct RoomScanEntryView: View {
    @Bindable var viewModel: RoomScanViewModel
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var newCameraImage: UIImage? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(Color.primary)
                    .padding(.bottom, 4)

                Text("Scan Your Room")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.primary)

                Text("Take photos of your room and we'll recommend\nproducts that perfectly complement your space.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)

            Spacer().frame(height: 36)

            // Capture Options
            VStack(spacing: 12) {
                captureButton(
                    icon: "camera.fill",
                    title: "Take Photo",
                    subtitle: "Capture your room with the camera",
                    action: { showCamera = true }
                )

                captureButton(
                    icon: "photo.on.rectangle.angled",
                    title: "Choose from Library",
                    subtitle: "Select 2–4 photos from different angles",
                    action: { showPhotoPicker = true }
                )
            }
            .padding(.horizontal, 16)

            // Thumbnail Previews
            if !viewModel.capturedImages.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(viewModel.capturedImages.count) photo\(viewModel.capturedImages.count == 1 ? "" : "s") selected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(viewModel.capturedImages.enumerated()), id: \.offset) { index, image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
                                        )

                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.removeImage(at: index)
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(.white, Color.black.opacity(0.7))
                                    }
                                    .offset(x: 6, y: -6)
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            // CTA Button
            Button(action: {
                viewModel.proceedToQuestions()
            }) {
                Text("ANALYSE MY ROOM")
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(viewModel.canAnalyze ? Color.black : Color(uiColor: .tertiaryLabel))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
            }
            .disabled(!viewModel.canAnalyze)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView(capturedImage: $newCameraImage)
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoLibraryPickerView(
                selectedImages: Binding(
                    get: { viewModel.capturedImages },
                    set: { viewModel.capturedImages = $0 }
                ),
                maxSelection: 4 - viewModel.capturedImages.count
            )
        }
        .onChange(of: newCameraImage) { _, newValue in
            if let image = newValue {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.addImage(image)
                }
                newCameraImage = nil
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.capturedImages.count)
    }

    // MARK: - Capture Option Button
    private func captureButton(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .frame(width: 44, height: 44)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    Text(subtitle)
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
        .buttonStyle(WSPressButtonStyle())
    }
}
