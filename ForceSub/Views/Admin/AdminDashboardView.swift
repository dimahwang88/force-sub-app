import SwiftUI

struct AdminDashboardView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = AdminDashboardViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading dashboard...")
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "Something went wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                dashboardContent
            }
        }
        .navigationTitle("Dashboard")
        .task {
            await viewModel.loadDashboard()
        }
    }

    private var dashboardContent: some View {
        List {
            // Summary stats
            Section("Overview") {
                NavigationLink {
                    CustomerListView(customers: viewModel.customers, allBookings: viewModel.allBookings)
                } label: {
                    StatRow(icon: "person.2.fill", label: "Total Customers", value: "\(viewModel.totalCustomers)", color: .blue)
                }
                StatRow(icon: "checkmark.circle.fill", label: "Classes Attended", value: "\(viewModel.totalClassesAttended)", color: .green)
                StatRow(icon: "calendar.badge.clock", label: "Upcoming Bookings", value: "\(viewModel.upcomingBookingsCount)", color: .orange)
            }

            // Admin Invite Codes
            Section {
                if let code = viewModel.generatedCode {
                    HStack {
                        Text(code)
                            .font(.title3.monospaced().bold())
                        Spacer()
                        Button {
                            UIPasteboard.general.string = code
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                    .padding(.vertical, 4)
                }

                Button {
                    Task {
                        if let userId = authViewModel.currentUserId {
                            await viewModel.generateInviteCode(createdBy: userId)
                        }
                    }
                } label: {
                    Label("Generate Invite Code", systemImage: "plus.circle.fill")
                }

                ForEach(viewModel.adminCodes) { code in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(code.id ?? "—")
                                .font(.subheadline.monospaced())
                            Text(code.isUsed ? "Used" : "Available")
                                .font(.caption)
                                .foregroundStyle(code.isUsed ? .red : .green)
                        }
                        Spacer()
                        if !code.isUsed, let codeId = code.id {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteInviteCode(codeId) }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                        }
                    }
                }
            } header: {
                Text("Admin Invite Codes")
            } footer: {
                Text("Share an invite code with someone to let them sign up as an admin.")
            }

            // Daily attendance chart (last 30 days)
            if !viewModel.dailyAttendance.isEmpty {
                Section("Attendance — Last 30 Days") {
                    DailyAttendanceChartView(data: viewModel.dailyAttendance)
                        .frame(height: 160)
                        .padding(.vertical, 4)
                }
            }

            // Class popularity
            if !viewModel.classPopularity.isEmpty {
                Section("Popular Classes") {
                    ForEach(viewModel.classPopularity.prefix(5)) { item in
                        HStack {
                            Text(item.className)
                                .font(.subheadline)
                            Spacer()
                            Text("\(item.count) attended")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Per-customer attendance
            Section {
                if viewModel.customerAttendance.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "person.slash")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("No customers yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(viewModel.customerAttendance) { row in
                        CustomerAttendanceRowView(row: row)
                    }
                }
            } header: {
                HStack {
                    Text("Customer Attendance")
                    Spacer()
                    Text("\(viewModel.customerAttendance.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Stat Row

private struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Label {
                Text(label)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(color)
            }
            Spacer()
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
        }
    }
}

// MARK: - Customer Attendance Row

private struct CustomerAttendanceRowView: View {
    let row: CustomerAttendanceRow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.displayName)
                        .font(.subheadline.bold())
                    Text(row.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let belt = row.beltRank, !belt.isEmpty {
                    Text(belt.capitalized)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.beltColor(for: belt).opacity(0.2))
                        .foregroundStyle(Color.beltColor(for: belt))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 16) {
                Label("\(row.attendedCount) attended", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.green)
                Label("\(row.upcomingCount) upcoming", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.orange)
                if let last = row.lastAttendedDate {
                    Spacer()
                    Text("Last: \(last.formattedShort)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Daily Attendance Bar Chart

private struct DailyAttendanceChartView: View {
    let data: [DailyAttendance]

    private var maxCount: Int {
        max(data.map(\.count).max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Y-axis label
            Text("Classes / day")
                .font(.caption2)
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                HStack(alignment: .bottom, spacing: 1.5) {
                    ForEach(data) { item in
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(item.count > 0 ? Color.blue : Color(uiColor: .systemGray5))
                                .frame(height: max(2, CGFloat(item.count) / CGFloat(maxCount) * (geo.size.height - 20)))
                        }
                    }
                }
            }

            // X-axis labels
            HStack {
                Text(xLabel(for: data.first?.date))
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Today")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func xLabel(for date: Date?) -> String {
        guard let date else { return "" }
        return date.formattedShort
    }
}
