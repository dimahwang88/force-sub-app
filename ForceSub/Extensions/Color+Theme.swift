import SwiftUI

extension Color {
    static let appPrimary = Color.blue
    static let appBackground = Color(.systemGroupedBackground)

    static func levelColor(for level: ClassLevel) -> Color {
        switch level {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }

    static func spotsColor(available: Int, total: Int) -> Color {
        let ratio = Double(available) / Double(max(total, 1))
        if ratio > 0.5 { return .green }
        if ratio > 0.15 { return .orange }
        return .red
    }
}
