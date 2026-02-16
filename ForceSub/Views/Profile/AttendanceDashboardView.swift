import SwiftUI

struct AttendanceDashboardView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = AttendanceDashboardViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading attendance...")
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "Something went wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if viewModel.attendedBookings.isEmpty {
                ContentUnavailableView(
                    "No Attendance Yet",
                    systemImage: "chart.bar",
                    description: Text("Once you attend classes, your stats will appear here.")
                )
            } else {
                dashboardContent
            }
        }
        .navigationTitle("Attendance")
        .task {
            if let userId = authViewModel.currentUserId {
                await viewModel.loadAttendance(userId: userId)
            }
        }
        .refreshable {
            if let userId = authViewModel.currentUserId {
                await viewModel.loadAttendance(userId: userId)
            }
        }
    }

    private var dashboardContent: some View {
        List {
            overviewSection
            averagesSection
            classBreakdownSection
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Overview

    private var overviewSection: some View {
        Section("Overview") {
            StatRow(
                icon: "checkmark.circle.fill",
                iconColor: .green,
                label: "Total Classes",
                value: "\(viewModel.totalClasses)"
            )
            StatRow(
                icon: "clock.fill",
                iconColor: .blue,
                label: "Total Hours",
                value: String(format: "%.1f", viewModel.totalHours)
            )
        }
    }

    // MARK: - Averages

    private var averagesSection: some View {
        Section("Averages") {
            StatRow(
                icon: "calendar.badge.clock",
                iconColor: .orange,
                label: "Classes / Week",
                value: String(format: "%.1f", viewModel.averageClassesPerWeek)
            )
            StatRow(
                icon: "clock.badge",
                iconColor: .orange,
                label: "Hours / Week",
                value: String(format: "%.1f", viewModel.averageHoursPerWeek)
            )
            StatRow(
                icon: "calendar",
                iconColor: .purple,
                label: "Classes / Month",
                value: String(format: "%.1f", viewModel.averageClassesPerMonth)
            )
            StatRow(
                icon: "clock",
                iconColor: .purple,
                label: "Hours / Month",
                value: String(format: "%.1f", viewModel.averageHoursPerMonth)
            )
        }
    }

    // MARK: - Class Breakdown

    private var classBreakdownSection: some View {
        Section("Classes Attended") {
            ForEach(viewModel.classBreakdown) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.className)
                            .font(.body)
                        Text(String(format: "%.1f hrs", item.totalHours))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(item.count)")
                        .font(.title3.bold())
                        .foregroundStyle(.appPrimary)
                }
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - Stat Row Component

private struct StatRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 24)
            Text(label)
            Spacer()
            Text(value)
                .font(.body.bold())
                .foregroundStyle(.secondary)
        }
    }
}
