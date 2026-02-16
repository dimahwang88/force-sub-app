import SwiftUI

struct AdminCustomerDetailView: View {
    let customer: CustomerSummary
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
                    description: Text("This customer hasn't attended any classes yet.")
                )
            } else {
                dashboardContent
            }
        }
        .navigationTitle(customer.user.displayName)
        .task {
            if let userId = customer.user.id {
                await viewModel.loadAttendance(userId: userId)
            }
        }
    }

    private var dashboardContent: some View {
        List {
            customerInfoSection
            overviewSection
            averagesSection
            classBreakdownSection
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Customer Info

    private var customerInfoSection: some View {
        Section("Customer Info") {
            InfoRow(label: "Name", value: customer.user.displayName)
            InfoRow(label: "Email", value: customer.user.email)
            if let phone = customer.user.phone {
                InfoRow(label: "Phone", value: phone)
            }
            if let belt = customer.user.beltRank {
                InfoRow(label: "Belt Rank", value: belt.capitalized)
            }
            InfoRow(label: "Member Since", value: customer.user.createdAt.formattedShort)
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        Section("Attendance Overview") {
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

// MARK: - Reusable Components

struct StatRow: View {
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

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
