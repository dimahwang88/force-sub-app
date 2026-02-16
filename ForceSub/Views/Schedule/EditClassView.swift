import SwiftUI

struct EditClassView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditClassViewModel
    @State private var showDeleteConfirmation = false

    init(gymClass: GymClass? = nil) {
        _viewModel = State(initialValue: EditClassViewModel(gymClass: gymClass))
    }

    var body: some View {
        Form {
            classInfoSection
            scheduleSection
            detailsSection

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }

            if viewModel.isEditing {
                Section {
                    Button("Delete Class", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit Class" : "Add Class")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await viewModel.save() }
                }
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
            }
        }
        .disabled(viewModel.isLoading)
        .onChange(of: viewModel.didSave) { _, saved in
            if saved { dismiss() }
        }
        .onChange(of: viewModel.didDelete) { _, deleted in
            if deleted { dismiss() }
        }
        .alert("Delete Class", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteClass() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this class? This action cannot be undone.")
        }
    }

    // MARK: - Class Info

    private var classInfoSection: some View {
        Section("Class Info") {
            TextField("Class Name", text: $viewModel.name)
            TextField("Instructor", text: $viewModel.instructor)
            Picker("Level", selection: $viewModel.level) {
                ForEach(ClassLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }
        }
    }

    // MARK: - Schedule

    private var scheduleSection: some View {
        Section("Schedule") {
            DatePicker("Date & Time", selection: $viewModel.dateTime)
            Stepper("Duration: \(viewModel.durationMinutes) min", value: $viewModel.durationMinutes, in: 15...180, step: 15)
        }
    }

    // MARK: - Details

    private var detailsSection: some View {
        Section("Details") {
            TextField("Location", text: $viewModel.location)
            Stepper("Total Spots: \(viewModel.totalSpots)", value: $viewModel.totalSpots, in: 1...100)
            TextField("Description", text: $viewModel.description, axis: .vertical)
                .lineLimit(3...6)
        }
    }
}
