// AssignExerciseView.swift
import SwiftUI

struct AssignExerciseView: View {
    @StateObject var viewModel: AssignExerciseViewModel
    @Environment(\.dismiss) var dismiss

    // Optional: Pass initial selections if navigating from specific client/exercise
    init(apiService: APIService, authService: AuthService, initialClientId: String? = nil, initialExerciseId: String? = nil) {
        let vm = AssignExerciseViewModel(apiService: apiService, authService: authService)
        // Set initial selections if provided
        vm.selectedClientId = initialClientId
        vm.selectedExerciseId = initialExerciseId
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        NavigationView {
            Form {
                // --- Client Selection ---
                Section(header: Text("Select Client")) {
                    if viewModel.isLoadingClients {
                        ProgressView()
                    } else if viewModel.clients.isEmpty {
                        Text("No clients found. Add clients first.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Client", selection: $viewModel.selectedClientId) {
                            Text("Select a Client").tag(String?.none) // Placeholder
                            ForEach(viewModel.clients) { client in
                                Text(client.name).tag(Optional(client.id))
                            }
                        }
                        // Consider .pickerStyle(.navigationLink) for long lists
                    }
                }

                // --- Exercise Selection ---
                Section(header: Text("Select Exercise")) {
                    if viewModel.isLoadingExercises {
                        ProgressView()
                    } else if viewModel.exercises.isEmpty {
                        Text("No exercises found. Create exercises first.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Exercise", selection: $viewModel.selectedExerciseId) {
                            Text("Select an Exercise").tag(String?.none) // Placeholder
                            ForEach(viewModel.exercises) { exercise in
                                Text(exercise.name).tag(Optional(exercise.id))
                            }
                        }
                         // Consider .pickerStyle(.navigationLink) for long lists
                    }
                }

                // --- Due Date (Optional) ---
                Section(header: Text("Due Date (Optional)")) {
                    Toggle("Set Due Date", isOn: $viewModel.includeDueDate.animation())
                    
                    if viewModel.includeDueDate {
                        DatePicker(
                            "Due Date",
                            selection: Binding( // Binding to handle optional Date
                                get: { viewModel.selectedDueDate ?? Date() },
                                set: { viewModel.selectedDueDate = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        // Optional: Set a minimum date, e.g., .in(Date()...)
                    }
                }

                // --- Assign Button ---
                Section {
                    if viewModel.isAssigning {
                        ProgressView("Assigning...")
                    } else {
                        Button("Assign Exercise") {
                            Task { await viewModel.assignExercise() }
                        }
                        .disabled(!viewModel.canAssign) // Use computed property
                    }
                }

                // --- Error Message ---
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Assign Exercise")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                // Load clients and exercises when the view appears
                Task { await viewModel.loadInitialData() }
            }
            .onChange(of: viewModel.didAssignSuccessfully) { success in
                if success {
                    print("Assign view: Assignment successful, dismissing.")
                    dismiss() // Dismiss on successful assignment
                }
            }
        } // End NavigationView
    }
}

// Preview Provider
struct AssignExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuth = AuthService()
        // mockAuth.authToken = "fake"
        // mockAuth.loggedInUser = UserResponse(...) // Setup trainer
        let mockAPI = APIService(authService: mockAuth)
        
        // You'd ideally mock the API service to return dummy clients/exercises
        // for a better preview, or see the loading/empty states.

        AssignExerciseView(apiService: mockAPI, authService: mockAuth)
    }
}
