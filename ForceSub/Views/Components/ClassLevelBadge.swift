import SwiftUI

struct ClassLevelBadge: View {
    let level: ClassLevel

    var body: some View {
        Text(level.displayName)
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.levelColor(for: level))
            .clipShape(Capsule())
    }
}
