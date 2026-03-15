import Foundation
import UIKit
import FirebaseFirestore
import FirebaseStorage

enum GroupPhotoError: LocalizedError {
    case compressionFailed
    case uploadFailed
    case noClassId

    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Failed to process the image."
        case .uploadFailed: return "Failed to upload the group photo."
        case .noClassId: return "No class ID found."
        }
    }
}

final class GroupPhotoService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    /// Uploads a group photo to Firebase Storage and saves the download URL
    /// to the class's Firestore document.
    /// Images are stored at `classPhotos/{classId}.jpg`.
    func uploadGroupPhoto(image: UIImage, classId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GroupPhotoError.compressionFailed
        }

        let storageRef = storage.reference().child("classPhotos/\(classId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putData(imageData, metadata: metadata)

        let downloadURL = try await storageRef.downloadURL()
        let urlString = downloadURL.absoluteString

        try await db.collection("classes").document(classId).updateData([
            "groupPhotoURL": urlString
        ])

        return urlString
    }

    /// Deletes the group photo from Firebase Storage and removes the URL
    /// from the class's Firestore document.
    func deleteGroupPhoto(classId: String) async throws {
        let storageRef = storage.reference().child("classPhotos/\(classId).jpg")

        do {
            try await storageRef.delete()
        } catch let error as NSError {
            if error.code == StorageErrorCode.objectNotFound.rawValue {
                // File already deleted or never existed
            } else {
                throw error
            }
        }

        try await db.collection("classes").document(classId).updateData([
            "groupPhotoURL": FieldValue.delete()
        ])
    }
}
