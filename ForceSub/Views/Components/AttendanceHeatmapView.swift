import SwiftUI

private struct MonthLabel: Identifiable {
    let id: Int
    let label: String
    let column: Int
}

struct AttendanceHeatmapView: View {
    let attendanceDays: [Date: Int]

    private let columns = 20
    private let cellSize: CGFloat = 13
    private let cellSpacing: CGFloat = 3
    private let dayLabels = ["Mon", "", "Wed", "", "Fri", "", "Sun"]
    private let calendar = Calendar.current

    /// The Monday that starts the grid (columns * 7 days ago from this week's Monday).
    private var gridStartDate: Date {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        // .weekday: 1=Sun,2=Mon,...7=Sat → offset to Monday
        let daysToMonday = (weekday + 5) % 7
        let thisMonday = calendar.date(byAdding: .day, value: -daysToMonday, to: calendar.startOfDay(for: today))!
        return calendar.date(byAdding: .day, value: -(columns - 1) * 7, to: thisMonday)!
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month labels
            monthLabelsRow

            HStack(alignment: .top, spacing: 0) {
                // Day-of-week labels
                VStack(alignment: .trailing, spacing: cellSpacing) {
                    ForEach(0..<7, id: \.self) { row in
                        Text(dayLabels[row])
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .frame(height: cellSize)
                    }
                }
                .padding(.trailing, 4)

                // Grid of cells
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: cellSpacing) {
                        ForEach(0..<columns, id: \.self) { col in
                            VStack(spacing: cellSpacing) {
                                ForEach(0..<7, id: \.self) { row in
                                    cellView(column: col, row: row)
                                }
                            }
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Spacer()
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                ForEach([0, 1, 2, 3], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.heatmapColor(count: level))
                        .frame(width: cellSize, height: cellSize)
                }
                Text("More")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func cellView(column: Int, row: Int) -> some View {
        let date = dateFor(column: column, row: row)
        let count = attendanceDays[calendar.startOfDay(for: date)] ?? 0
        let isFuture = date > Date()

        RoundedRectangle(cornerRadius: 2)
            .fill(isFuture ? Color.clear : Color.heatmapColor(count: count))
            .frame(width: cellSize, height: cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isFuture ? Color(uiColor: .systemGray5) : .clear, lineWidth: 0.5)
            )
    }

    private var monthLabelsRow: some View {
        HStack(spacing: 0) {
            // Offset for day labels column
            Color.clear.frame(width: 28)
            ZStack(alignment: .leading) {
                Color.clear.frame(height: 14)
                ForEach(monthPositions()) { item in
                    Text(item.label)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .offset(x: CGFloat(item.column) * (cellSize + cellSpacing))
                }
            }
        }
    }

    private func dateFor(column: Int, row: Int) -> Date {
        let dayOffset = column * 7 + row
        return calendar.date(byAdding: .day, value: dayOffset, to: gridStartDate)!
    }

    private func monthPositions() -> [MonthLabel] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var result: [MonthLabel] = []
        var lastMonth = -1
        for col in 0..<columns {
            let date = dateFor(column: col, row: 0)
            let month = calendar.component(.month, from: date)
            if month != lastMonth {
                result.append(MonthLabel(id: col, label: formatter.string(from: date), column: col))
                lastMonth = month
            }
        }
        return result
    }
}
