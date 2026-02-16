import SwiftUI

struct AdminCustomerListView: View {
    @State private var viewModel = AdminCustomersViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading customers...")
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "Something went wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if viewModel.filteredCustomers.isEmpty {
                if viewModel.searchText.isEmpty {
                    ContentUnavailableView(
                        "No Customers",
                        systemImage: "person.2",
                        description: Text("No customer accounts found.")
                    )
                } else {
                    ContentUnavailableView.search(text: viewModel.searchText)
                }
            } else {
                customerList
            }
        }
        .navigationTitle("Customers")
        .searchable(text: $viewModel.searchText, prompt: "Search by name or email")
        .task {
            await viewModel.loadCustomers()
        }
        .refreshable {
            await viewModel.loadCustomers()
        }
    }

    private var customerList: some View {
        List(viewModel.filteredCustomers) { summary in
            NavigationLink {
                AdminCustomerDetailView(customer: summary)
            } label: {
                CustomerRowView(summary: summary)
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Customer Row

private struct CustomerRowView: View {
    let summary: CustomerSummary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(summary.user.displayName)
                    .font(.body.bold())
                Text(summary.user.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(summary.totalClasses)")
                    .font(.title3.bold())
                    .foregroundStyle(.appPrimary)
                Text(summary.totalClasses == 1 ? "class" : "classes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
