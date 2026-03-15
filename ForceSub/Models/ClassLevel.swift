import Foundation

enum ClassLevel: String, Codable, CaseIterable, Hashable {
    case beginner
    case intermediate
    case advanced
    case allLevels = "all levels"
    case colouredBelts = "coloured belts"
    case kids = "4-8 yrs old"
    case teens = "9-15 yrs old"

    var displayName: String {
        switch self {
        case .kids: return "4-8 Yrs Old"
        case .teens: return "9-15 Yrs Old"
        case .colouredBelts: return "Coloured Belts"
        case .allLevels: return "All Levels"
        default: return rawValue.capitalized
        }
    }

    /// Decodes gracefully — unknown level strings fall back to `.allLevels`
    /// so documents are never silently dropped.
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = ClassLevel(rawValue: raw) ?? .allLevels
    }
}
