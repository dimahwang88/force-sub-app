import Foundation

enum ClassLevel: String, Codable, CaseIterable, Hashable {
    case beginner
    case intermediate
    case advanced
    case allLevels = "all levels"
    case colouredBelts = "coloured belts"

    var displayName: String {
        rawValue.capitalized
    }
}
