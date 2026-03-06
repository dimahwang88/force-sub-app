import Foundation
import UIKit
import Observation

@Observable
final class GroupPhotoViewModel {
    var groupPhotoURL: String?
    var selectedImage: UIImage?
    var isUploading = false
    var isDeleting = false
    var errorMessage: String?
    var showCamera = false

    private let groupPhotoService = GroupPhotoService()

    /// Upload the selected image as the class group photo.
    func uploadGroupPhoto(classId: String) async {
        guard let image = selectedImage else { return }

        isUploading = true
        errorMessage = nil
        do {
            let url = try await groupPhotoService.uploadGroupPhoto(image: image, classId: classId)
            groupPhotoURL = url
            selectedImage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isUploading = false
    }

    /// Delete the class group photo from storage and Firestore.
    func deleteGroupPhoto(classId: String) async {
        isDeleting = true
        errorMessage = nil
        do {
            try await groupPhotoService.deleteGroupPhoto(classId: classId)
            groupPhotoURL = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isDeleting = false
    }
}
