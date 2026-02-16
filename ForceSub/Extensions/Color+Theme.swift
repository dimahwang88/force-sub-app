import SwiftUI

extension Color {
    static let appPrimary = Color.blue
    static let appBackground = Color(.systemGroupedBackground)

    static func levelColor(for level: String) -> Color {
        switch level.lowercased() {
        case "beginner", "all levels": return .green
        case "intermediate": return .orange
        case "advanced", "coloured belts": return .red
        default: return .blue
        }
    }

    static func spotsColor(available: Int, total: Int) -> Color {
        let ratio = Double(available) / Double(max(total, 1))
        if ratio > 0.5 { return .green }
        if ratio > 0.15 { return .orange }
        return .red
    }
}
