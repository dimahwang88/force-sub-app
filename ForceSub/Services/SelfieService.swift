import Foundation
import UIKit
import FirebaseFirestore
import FirebaseStorage

enum SelfieError: LocalizedError {
    case compressionFailed
    case uploadFailed
    case noUser

    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Failed to process the image."
        case .uploadFailed: return "Failed to upload the selfie."
        case .noUser: return "No authenticated user found."
        }
    }
}

final class SelfieService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    /// Uploads a selfie image to Firebase Storage and saves the download URL
    /// to the user's Firestore document for later face recognition retrieval.
    ///
    /// Images are stored at `selfies/{userId}.jpg` — one selfie per user,
    /// overwritten on re-upload to keep storage lean.
    func uploadSelfie(image: UIImage, userId: String) async throws -> String {
        // Compress to JPEG (quality 0.8 balances size vs face-recognition fidelity)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw SelfieError.compressionFailed
        }

        let storageRef = storage.reference().child("selfies/\(userId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Upload the image data
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)

        // Get the download URL
        let downloadURL = try await storageRef.downloadURL()
        let urlString = downloadURL.absoluteString

        // Persist the URL in the user's Firestore document
        try await db.collection("users").document(userId).updateData([
            "selfieURL": urlString
        ])

        return urlString
    }

    /// Deletes the user's selfie from Firebase Storage and removes the URL
    /// from their Firestore document.
    func deleteSelfie(userId: String) async throws {
        let storageRef = storage.reference().child("selfies/\(userId).jpg")

        do {
            try await storageRef.delete()
        } catch let error as NSError {
            // StorageErrorCode.objectNotFound == 404 — file already gone
            if error.code == StorageErrorCode.objectNotFound.rawValue {
                // File already deleted or never existed — continue
            } else {
                throw error
            }
        }

        try await db.collection("users").document(userId).updateData([
            "selfieURL": FieldValue.delete()
        ])
    }

    /// Fetches the selfie download URL for a given user.
    /// Returns `nil` if the user has no selfie on file.
    func fetchSelfieURL(userId: String) async throws -> String? {
        let doc = try await db.collection("users").document(userId).getDocument()
        return doc.data()?["selfieURL"] as? String
    }
}
