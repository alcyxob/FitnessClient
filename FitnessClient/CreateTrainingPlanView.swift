// CreateTrainingPlanView.swift
import SwiftUI

struct CreateTrainingPlanView: View {
    // Create the ViewModel specific to this instance of the view
    @StateObject var viewModel: CreateTrainingPlanViewModel
    @Environment(\.dismiss) var dismiss // To close the sheet

    // Initializer takes dependencies needed by the ViewModel
    init(client: UserResponse, apiService: APIService) {
        _viewModel = StateObject(wrappedValue: CreateTrainingPlanViewModel(client: client, apiService: apiService))
    }

    var body: some View {
        NavigationView { // Provides structure for title and buttons in a sheet
            Form {
                Section(header: Text("Plan Details")) {
                    TextField("Plan Name (Required)", text: $viewModel.planName)
                    TextField("Description (Optional)", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...)
                }

                Section(header: Text("Schedule (Optional)")) {
                    // Start Date
                    Toggle("Set Start Date", isOn: $viewModel.includeStartDate.animation())
                    if viewModel.includeStartDate {
                        DatePicker(
                            "Start Date",
                            selection: Binding(
                                get: { viewModel.startDate ?? Date() }, // Default to now if nil
                                set: { viewModel.startDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                        // Optional: Set a range, e.g., .in(Date()...)
                    }

                    // End Date
                    Toggle("Set End Date", isOn: $viewModel.includeEndDate.animation())
                    if viewModel.includeEndDate {
                         DatePicker(
                            "End Date",
                            selection: Binding(
                                get: { viewModel.endDate ?? (viewModel.startDate ?? Date()).addingTimeInterval(86400 * 7) }, // Default to 1 week after start/now if nil
                                set: { viewModel.endDate = $0 }
                            ),
                             in: (viewModel.startDate ?? Date())..., // Ensure end date is after start date
                             displayedComponents: [.date]
                         )
                    }
                }
                
                Section(header: Text("Status")) {
                    Toggle("Set as Active Plan", isOn: $viewModel.isActive)
                        .tint(.green) // Optional styling
                    if viewModel.isActive {
                        Text("Note: Setting this plan as active might deactivate other active plans for this client (if backend enforces this).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    if viewModel.isLoading {
                        ProgressView("Creating Plan...")
                    } else {
                        Button("Create Plan") {
                            // Dismiss keyboard? (Can be done with FocusState if needed)
                            Task { await viewModel.createTrainingPlan() }
                        }
                        .disabled(!viewModel.canCreatePlan) // Use computed property
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                    }
                }
            } // End Form
            .navigationTitle("New Training Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                // Optional: Add Save button in toolbar instead of form if preferred
                // ToolbarItem(placement: .navigationBarTrailing) {
                //     Button("Save") { Task { await viewModel.createTrainingPlan() } }
                //        .disabled(!viewModel.canCreatePlan)
                // }
            }
            .onChange(of: viewModel.didCreateSuccessfully) { success in
                if success {
                    print("CreatePlanView: Plan created successfully, dismissing.")
                    dismiss() // Dismiss the sheet automatically on success
                }
            }

        } // End NavigationView
    }
}

// Preview Provider
struct CreateTrainingPlanView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuth = AuthService()
        let mockAPI = APIService(authService: mockAuth)
        let previewClient = UserResponse(id: "clientPreview123", name: "Alice Preview", email: "alice@preview.com", role: "client", createdAt: Date(), clientIds: nil, trainerId: "trainerPreview456")

        CreateTrainingPlanView(client: previewClient, apiService: mockAPI)
            // Provide environment objects if any sub-sub-views needed them (unlikely here)
            // .environmentObject(mockAPI)
            // .environmentObject(mockAuth)
    }
}
