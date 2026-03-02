import Foundation
import FirebaseFirestore

enum AccountType: String, Codable, CaseIterable {
    case customer
    case admin

    var displayName: String {
        switch self {
        case .customer: return "Customer"
        case .admin: return "Admin"
        }
    }
}

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    let email: String
    var displayName: String
    let createdAt: Date
    var beltRank: String?
    var phone: String?
    var isAdmin: Bool?
    var accountType: String?
    /// Download URL for the user's selfie stored in Firebase Storage
    var selfieURL: String?

    var admin: Bool {
        isAdmin ?? false || resolvedAccountType == .admin
    }

    var resolvedAccountType: AccountType {
        if let accountType, let type = AccountType(rawValue: accountType) {
            return type
        }
        return (isAdmin ?? false) ? .admin : .customer
    }
}
