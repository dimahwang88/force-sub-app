import SwiftUI
import PhotosUI
import AVFoundation

struct SelfieCaptureView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SelfieViewModel()
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCameraPermissionAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview area
                selfiePreview
                    .padding(.top)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Spacer()

                // Action buttons
                actionButtons
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .navigationTitle("Selfie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                if let userId = authViewModel.currentUserId {
                    await viewModel.loadSelfieURL(userId: userId)
                }
            }
            .fullScreenCover(isPresented: $viewModel.showCamera) {
                CameraView(image: $viewModel.selectedImage)
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
                Text("Please enable camera access in Settings to take a selfie.")
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

    @ViewBuilder
    private var selfiePreview: some View {
        VStack(spacing: 16) {
            if let selected = viewModel.selectedImage {
                // Show the newly picked image before upload
                Image(uiImage: selected)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.secondary, lineWidth: 2))
            } else if let urlString = viewModel.selfieURL, let url = URL(string: urlString) {
                // Show existing selfie from Firebase
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
                .frame(width: 200, height: 200)
                .clipShape(Circle())
                .overlay(Circle().stroke(.secondary, lineWidth: 2))
            } else {
                placeholderIcon
            }

            Text(viewModel.selfieURL != nil ? "Selfie on file" : "No selfie on file")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var placeholderIcon: some View {
        Image(systemName: "person.crop.circle.badge.plus")
            .font(.system(size: 80))
            .foregroundStyle(.secondary)
            .frame(width: 200, height: 200)
    }

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Source selection row
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

            // Upload button
            if viewModel.selectedImage != nil {
                Button {
                    Task {
                        if let userId = authViewModel.currentUserId {
                            await viewModel.uploadSelfie(userId: userId)
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                } label: {
                    if viewModel.isUploading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save Selfie")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isUploading)
            }

            // Delete button (only if a selfie exists)
            if viewModel.selfieURL != nil && viewModel.selectedImage == nil {
                Button(role: .destructive) {
                    Task {
                        if let userId = authViewModel.currentUserId {
                            await viewModel.deleteSelfie(userId: userId)
                        }
                    }
                } label: {
                    if viewModel.isDeleting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Remove Selfie")
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
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil else {
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

// MARK: - AVCaptureSession Camera View

struct CameraView: View {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var cameraManager = CameraManager(position: .front)

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

// MARK: - Camera Preview (UIViewRepresentable)

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Camera Manager (AVCaptureSession)

@Observable
final class CameraManager: NSObject, @preconcurrency AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let position: AVCaptureDevice.Position
    private var completion: ((UIImage?) -> Void)?

    init(position: AVCaptureDevice.Position) {
        self.position = position
        super.init()
    }

    func start() {
        guard session.inputs.isEmpty else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.startRunning()
        }
    }

    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.stopRunning()
        }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            DispatchQueue.main.async { [weak self] in
                self?.completion?(nil)
                self?.completion = nil
            }
            return
        }

        let mirrored: UIImage
        if position == .front {
            mirrored = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .leftMirrored)
        } else {
            mirrored = image
        }

        DispatchQueue.main.async { [weak self] in
            self?.completion?(mirrored)
            self?.completion = nil
        }
    }
}
