import SwiftUI

struct ScheduleView: View {
    @State private var viewModel = ScheduleViewModel()
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())

    var body: some View {
        VStack(spacing: 0) {
            dayPicker
            Divider()
            classList
        }
        .navigationTitle("Schedule")
        .task {
            await viewModel.loadClasses(for: selectedDate)
        }
        .onChange(of: selectedDate) { _, newDate in
            Task { await viewModel.loadClasses(for: newDate) }
        }
    }

    // MARK: - Day Picker

    private var dayPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.weekDays, id: \.self) { date in
                    DayButton(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    ) {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Class List

    private var classList: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading classes...")
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "Something went wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if viewModel.classesForSelectedDay.isEmpty {
                ContentUnavailableView(
                    "No Classes",
                    systemImage: "calendar.badge.minus",
                    description: Text("No classes scheduled for this day.")
                )
            } else {
                List(viewModel.classesForSelectedDay) { gymClass in
                    NavigationLink(value: gymClass) {
                        ClassRowView(gymClass: gymClass)
                    }
                }
                .listStyle(.plain)
                .navigationDestination(for: GymClass.self) { gymClass in
                    ClassDetailView(gymClass: gymClass)
                }
            }
        }
    }
}

// MARK: - Day Button

struct DayButton: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(date.dayAbbreviation)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : .secondary)
                Text(date.dayNumber)
                    .font(.title3.bold())
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(width: 48, height: 56)
            .background(isSelected ? Color.appPrimary : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
