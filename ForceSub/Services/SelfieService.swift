import Foundation
import UIKit
import FirebaseFirestore
import FirebaseStorage

enum SelfieError: LocalizedError {
    case compressionFailed
    case uploadFailed(String)
    case downloadURLFailed(String)
    case noUser
    case storageBucketMissing

    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Failed to process the image."
        case .uploadFailed(let detail): return "Upload failed: \(detail)"
        case .downloadURLFailed(let detail): return "Download URL failed: \(detail)"
        case .noUser: return "No authenticated user found."
        case .storageBucketMissing: return "Firebase Storage bucket is not configured. Check GoogleService-Info.plist has a STORAGE_BUCKET value."
        }
    }
}

final class SelfieService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    /// Uploads a selfie image to Firebase Storage and saves the download URL
    /// to the user's Firestore document for later face recognition retrieval.
    ///
    /// Images are stored at `selfies/{userId}` — one selfie per user,
    /// overwritten on re-upload to keep storage lean.
    func uploadSelfie(image: UIImage, userId: String) async throws -> String {
        // Verify Storage bucket is configured
        let bucket = storage.reference().bucket
        if bucket.isEmpty {
            throw SelfieError.storageBucketMissing
        }

        // Compress to JPEG (quality 0.8 balances size vs face-recognition fidelity)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw SelfieError.compressionFailed
        }

        let storageRef = storage.reference().child("selfies/\(userId)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Step 1: Upload
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                storageRef.putData(imageData, metadata: metadata) { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            throw SelfieError.uploadFailed("\(error.localizedDescription) [bucket: \(bucket)]")
        }

        // Step 2: Get download URL
        let urlString: String
        do {
            let downloadURL = try await storageRef.downloadURL()
            urlString = downloadURL.absoluteString
        } catch {
            throw SelfieError.downloadURLFailed(error.localizedDescription)
        }

        // Step 3: Persist the URL in Firestore
        try await db.collection("users").document(userId).updateData([
            "selfieURL": urlString
        ])

        return urlString
    }

    /// Deletes the user's selfie from Firebase Storage and removes the URL
    /// from their Firestore document.
    func deleteSelfie(userId: String) async throws {
        let storageRef = storage.reference().child("selfies/\(userId)")

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
