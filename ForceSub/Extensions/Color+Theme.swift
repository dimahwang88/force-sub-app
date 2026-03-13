import SwiftUI

extension Color {
    // Brand colors matching the Force Submission logo
    static let appPrimary = Color(red: 0.48, green: 0.33, blue: 0.65) // #7B54A6
    static let appSecondary = Color(red: 0.58, green: 0.44, blue: 0.72) // #9470B8
    static let appBackground = Color(.systemGroupedBackground)

    static func levelColor(for level: String) -> Color {
        switch level.lowercased() {
        case "beginner", "all levels": return .green
        case "intermediate": return .orange
        case "advanced", "coloured belts": return .red
        default: return .appPrimary
        }
    }

    static func spotsColor(available: Int, total: Int) -> Color {
        let ratio = Double(available) / Double(max(total, 1))
        if ratio > 0.5 { return .green }
        if ratio > 0.15 { return .orange }
        return .red
    }

    static func beltColor(for belt: String) -> Color {
        switch belt.lowercased() {
        case "white": return .gray
        case "blue": return .blue
        case "purple": return .purple
        case "brown": return .brown
        case "black": return .primary
        case "yellow": return .yellow
        case "orange": return .orange
        case "green": return .green
        case "red": return .red
        default: return .secondary
        }
    }

    static func heatmapColor(count: Int) -> Color {
        switch count {
        case 0: return Color(.systemGray5)
        case 1: return Color.appPrimary.opacity(0.3)
        case 2: return Color.appPrimary.opacity(0.6)
        default: return Color.appPrimary.opacity(0.9)
        }
    }
}
