import SwiftUI
import PhotosUI

struct SelfieCaptureView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SelfieViewModel()
    @State private var photosPickerItem: PhotosPickerItem?

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
            .sheet(isPresented: $viewModel.showCamera) {
                CameraView(image: $viewModel.selectedImage)
                    .ignoresSafeArea()
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
                    viewModel.showCamera = true
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
}

// MARK: - Camera UIViewControllerRepresentable

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
