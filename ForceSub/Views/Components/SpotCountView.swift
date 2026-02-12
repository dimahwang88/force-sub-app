import SwiftUI

struct SpotCountView: View {
    let available: Int
    let total: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.2")
                .font(.caption2)
            if available == 0 {
                Text("Full")
                    .font(.caption.bold())
            } else {
                Text("\(available) spot\(available == 1 ? "" : "s") left")
                    .font(.caption)
            }
        }
        .foregroundStyle(Color.spotsColor(available: available, total: total))
    }
}
