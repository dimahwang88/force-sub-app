import SwiftUI
import PhotosUI
import AVFoundation

struct GroupPhotoCaptureView: View {
    let classId: String
    @Binding var groupPhotoURL: String?
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = GroupPhotoViewModel()
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCameraPermissionAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                photoPreview
                    .padding(.top)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Spacer()

                actionButtons
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .navigationTitle("Group Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                viewModel.groupPhotoURL = groupPhotoURL
            }
            .fullScreenCover(isPresented: $viewModel.showCamera) {
                GroupCameraView(image: $viewModel.selectedImage)
                    .ignoresSafeArea()
            }
            .alert("Camera Access Required", isPresented: $showCameraPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable camera access in Settings to take a group photo.")
            }
            .onChange(of: photosPickerItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        viewModel.selectedImage = uiImage
                    }
                }
            }
        }
    }

    // MARK: - Photo Preview

    @ViewBuilder
    private var photoPreview: some View {
        VStack(spacing: 16) {
            if let selected = viewModel.selectedImage {
                Image(uiImage: selected)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.secondary, lineWidth: 1)
                    )
                    .padding(.horizontal)
            } else if let urlString = viewModel.groupPhotoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderIcon
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderIcon
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.secondary, lineWidth: 1)
                )
                .padding(.horizontal)
            } else {
                placeholderIcon
            }

            Text(viewModel.groupPhotoURL != nil ? "Group photo on file" : "No group photo yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var placeholderIcon: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            Text("Take or upload a group photo")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 250)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    requestCameraAccess()
                } label: {
                    Label("Camera", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                PhotosPicker(
                    selection: $photosPickerItem,
                    matching: .images
                ) {
                    Label("Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            if viewModel.selectedImage != nil {
                Button {
                    Task {
                        await viewModel.uploadGroupPhoto(classId: classId)
                        if viewModel.errorMessage == nil {
                            groupPhotoURL = viewModel.groupPhotoURL
                            dismiss()
                        }
                    }
                } label: {
                    if viewModel.isUploading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save Group Photo")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isUploading)
            }

            if viewModel.groupPhotoURL != nil && viewModel.selectedImage == nil {
                Button(role: .destructive) {
                    Task {
                        await viewModel.deleteGroupPhoto(classId: classId)
                        if viewModel.errorMessage == nil {
                            groupPhotoURL = nil
                        }
                    }
                } label: {
                    if viewModel.isDeleting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Remove Group Photo")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(viewModel.isDeleting)
            }
        }
    }

    private func requestCameraAccess() {
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil else {
            viewModel.errorMessage = "Camera is not available on this device."
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            viewModel.showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        viewModel.showCamera = true
                    } else {
                        showCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionAlert = true
        @unknown default:
            showCameraPermissionAlert = true
        }
    }
}

// MARK: - Group Camera (rear-facing)

struct GroupCameraView: View {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var cameraManager = CameraManager(position: .back)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreviewView(session: cameraManager.session)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                        .padding()
                    Spacer()
                }
                Spacer()
                Button {
                    cameraManager.capturePhoto { capturedImage in
                        image = capturedImage
                        dismiss()
                    }
                } label: {
                    Circle()
                        .fill(.white)
                        .frame(width: 72, height: 72)
                        .overlay(Circle().stroke(Color.gray, lineWidth: 3).frame(width: 62, height: 62))
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear { cameraManager.start() }
        .onDisappear { cameraManager.stop() }
    }
}
