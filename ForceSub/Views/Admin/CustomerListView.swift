import SwiftUI

struct CustomerListView: View {
    let customers: [AppUser]
    let allBookings: [Booking]

    @State private var searchText = ""

    private var filteredCustomers: [AppUser] {
        if searchText.isEmpty { return customers }
        return customers.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List(filteredCustomers) { customer in
            NavigationLink {
                CustomerDetailView(customer: customer, bookings: bookings(for: customer))
            } label: {
                CustomerRowView(customer: customer, bookings: bookings(for: customer))
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search customers")
        .navigationTitle("Customers")
        .overlay {
            if filteredCustomers.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    private func bookings(for customer: AppUser) -> [Booking] {
        guard let id = customer.id else { return [] }
        return allBookings.filter { $0.userId == id }
            .sorted { $0.classDateTime > $1.classDateTime }
    }
}

// MARK: - Customer Row

private struct CustomerRowView: View {
    let customer: AppUser
    let bookings: [Booking]

    private var attendedCount: Int {
        bookings.filter { $0.classDateTime < Date() }.count
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(customer.displayName)
                    .font(.headline)
                Text(customer.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let belt = customer.beltRank, !belt.isEmpty {
                Text(belt.capitalized)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.beltColor(for: belt).opacity(0.2))
                    .foregroundStyle(Color.beltColor(for: belt))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}
