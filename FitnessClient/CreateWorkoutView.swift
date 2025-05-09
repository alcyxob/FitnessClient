// CreateWorkoutView.swift
import SwiftUI

struct CreateWorkoutView: View {
    @StateObject var viewModel: CreateWorkoutViewModel
    @Environment(\.dismiss) var dismiss

    // Focus state if needed
    enum Field: Hashable { case name, notes, sequence }
    @FocusState private var focusedField: Field?


    init(trainingPlan: TrainingPlan, currentWorkoutCount: Int, apiService: APIService) {
        _viewModel = StateObject(wrappedValue: CreateWorkoutViewModel(trainingPlan: trainingPlan, currentWorkoutCount: currentWorkoutCount, apiService: apiService))
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Workout Details") {
                    TextField("Workout Name (e.g., Day 1: Chest)", text: $viewModel.workoutName)
                        .focused($focusedField, equals: .name)
                    
                    Picker("Day of Week (Optional)", selection: $viewModel.selectedDayDisplay) {
                        ForEach(viewModel.daysOfWeek, id: \.self) { day in
                            Text(day)
                        }
                    }
                    
                    TextField("Sequence Order", value: $viewModel.sequence, format: .number)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .sequence)

                    TextField("Notes for Client (Optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(4...)
                        .focused($focusedField, equals: .notes)
                }

                Section {
                    if viewModel.isLoading {
                        ProgressView("Creating Workout...")
                    } else {
                        Button("Create Workout") {
                            focusedField = nil // Dismiss keyboard
                            Task { await viewModel.createWorkout() }
                        }
                        .disabled(!viewModel.canCreateWorkout)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: viewModel.didCreateSuccessfully) { success in
                if success { dismiss() }
            }
            // Handle keyboard submit/next if desired
            // .onSubmit { ... }
        }
    }
}


// Preview Provider
struct CreateWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuth = AuthService()
        // mockAuth.authToken = "fake"
        let mockAPI = APIService(authService: mockAuth)
        let previewPlan = TrainingPlan(id: "plan1", trainerId: "t1", clientId: "c1", name: "Preview Plan", description: nil, startDate: nil, endDate: nil, isActive: true, createdAt: Date(), updatedAt: Date())

        CreateWorkoutView(trainingPlan: previewPlan, currentWorkoutCount: 0, apiService: mockAPI)
    }
}
