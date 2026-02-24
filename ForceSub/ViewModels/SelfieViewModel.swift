import Foundation
import UIKit
import Observation

@Observable
final class SelfieViewModel {
    var selfieURL: String?
    var selectedImage: UIImage?
    var isUploading = false
    var isDeleting = false
    var errorMessage: String?
    var showCamera = false
    var showPhotoPicker = false
    var showSourcePicker = false

    private let selfieService = SelfieService()

    /// Upload the selected image as the user's selfie.
    func uploadSelfie(userId: String) async {
        guard let image = selectedImage else { return }

        isUploading = true
        errorMessage = nil
        do {
            let url = try await selfieService.uploadSelfie(image: image, userId: userId)
            selfieURL = url
            selectedImage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isUploading = false
    }

    /// Delete the user's selfie from storage and Firestore.
    func deleteSelfie(userId: String) async {
        isDeleting = true
        errorMessage = nil
        do {
            try await selfieService.deleteSelfie(userId: userId)
            selfieURL = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isDeleting = false
    }

    /// Load the current selfie URL from Firestore.
    func loadSelfieURL(userId: String) async {
        do {
            selfieURL = try await selfieService.fetchSelfieURL(userId: userId)
        } catch {
            // Non-critical; the profile still works without a selfie
        }
    }
}
