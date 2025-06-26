// AddExerciseToWorkoutView.swift
import SwiftUI

struct AddExerciseToWorkoutView: View {
    // ViewModel is created and owned by this view instance.
    @StateObject var viewModel: AddExerciseToWorkoutViewModel
    @Environment(\.dismiss) var dismiss // To close the sheet

    // For handling keyboard focus and "next" field behavior
    enum Field: Hashable {
        case sets, reps, rest, tempo, weight, duration, notes, sequence
    }
    @FocusState private var focusedField: Field?

    // Initializer that receives necessary dependencies for its ViewModel
    init(workout: Workout, currentAssignmentCount: Int, apiService: APIService) {
        _viewModel = StateObject(wrappedValue: AddExerciseToWorkoutViewModel(workout: workout, currentAssignmentCount: currentAssignmentCount, apiService: apiService))
        print("AddExerciseToWorkoutView: Initialized. For Workout: \(workout.name)")
    }

    var body: some View {
        // Debug print to trace body re-evaluation and key ViewModel states
        let _ = print("AddExerciseToWorkoutView BODY re-evaluating: isLoadingExercises: \(viewModel.isLoadingExercises), availableExercises.count: \(viewModel.availableExercises.count), selectedExerciseId: \(viewModel.selectedExerciseId ?? "nil"), generalIsLoading: \(viewModel.isLoading), errorMessage: \(viewModel.errorMessage ?? "None")")

        NavigationView { // Often useful for sheets to have their own Nav Bar for title/buttons
            Form {
                // --- Section for Selecting an Exercise ---
                Section("Select Exercise") {
                    if viewModel.isLoadingExercises {
                        // State 1: Exercises are currently being loaded
                        let _ = print("AddExerciseToWorkoutView: UI State - Displaying ProgressView for exercises")
                        HStack { // Center the ProgressView
                            Spacer()
                            ProgressView("Loading exercises...")
                            Spacer()
                        }
                    } else if !viewModel.availableExercises.isEmpty {
                        // State 2: Exercises are loaded and available
                        let _ = print("AddExerciseToWorkoutView: UI State - Displaying Picker with \(viewModel.availableExercises.count) exercises. Selected ID: \(viewModel.selectedExerciseId ?? "nil")")
                        Picker("Exercise", selection: $viewModel.selectedExerciseId) {
                            Text("Choose an exercise").tag(String?.none) // Placeholder for optional selection
                            ForEach(viewModel.availableExercises) { exercise in
                                Text(exercise.name)
                                    .tag(Optional(exercise.id)) // Tag must match optional selection type
                            }
                        }
                        // Picker is automatically disabled by Form if no items or based on .disabled modifier
                    } else {
                        // State 3: Not loading, AND no exercises available.
                        // This could be because the library is empty or an error occurred.
                        if let errorMsg = viewModel.errorMessage, errorMsg.contains("Could not load your exercises") {
                            let _ = print("AddExerciseToWorkoutView: UI State - Displaying exercise loading error: \(errorMsg)")
                            Text("Error loading exercises: \(errorMsg)")
                                .foregroundColor(.red)
                        } else {
                            let _ = print("AddExerciseToWorkoutView: UI State - Displaying 'No exercises in library'")
                            Text("No exercises found in your library. Please create some exercises first.")
                                .foregroundColor(.secondary)
                        }
                    }
                } // End Section "Select Exercise"

                // --- Section for Assignment Parameters ---
                // Only show these if an exercise has been selected and exercises are loaded
                if viewModel.selectedExerciseId != nil && !viewModel.availableExercises.isEmpty && !viewModel.isLoadingExercises {
                    Section("Parameters") {
                        HStack {
                            Text("Sequence")
                            Spacer()
                            TextField("Order", value: $viewModel.sequence, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .sequence)
                        }
                        HStack {
                            Text("Sets")
                            Spacer()
                            TextField("e.g., 3", text: $viewModel.sets)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .sets)
                        }
                        TextField("Reps (e.g., 8-12, AMRAP)", text: $viewModel.reps)
                            .focused($focusedField, equals: .reps)
                        TextField("Rest (e.g., 60s, 2m)", text: $viewModel.rest)
                            .focused($focusedField, equals: .rest)
                        TextField("Tempo (e.g., 2010)", text: $viewModel.tempo)
                            .focused($focusedField, equals: .tempo)
                        TextField("Weight/Intensity (e.g., 10kg, RPE 8)", text: $viewModel.weight)
                            .focused($focusedField, equals: .weight)
                        TextField("Duration (e.g., 30min, 5km)", text: $viewModel.duration)
                            .focused($focusedField, equals: .duration)
                    } // End Section "Parameters"

                    Section("Notes for Client (Optional)") {
                        TextEditor(text: $viewModel.trainerNotes)
                            .frame(minHeight: 80) // Ensure TextEditor has some default height
                            .focused($focusedField, equals: .notes)
                    } // End Section "Notes"
                } // End Conditional Parameter Sections
                
                // --- Section for the Action Button ---
                Section {
                    if viewModel.isLoading { // This is the general isLoading for the "assign" action
                        let _ = print("AddExerciseToWorkoutView: UI State - Displaying ProgressView for 'Assigning Exercise'")
                        ProgressView("Assigning Exercise...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        let _ = print("AddExerciseToWorkoutView: UI State - Displaying 'Assign Exercise' button. Can assign: \(viewModel.canAssign)")
                        Button("Assign Exercise to Workout") {
                            focusedField = nil // Dismiss keyboard before async operation
                            Task { await viewModel.assignExerciseToWorkout() }
                        }
                        .disabled(!viewModel.canAssign) // Use computed property from ViewModel
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                // Display general error messages (not related to exercise list loading)
                if let errorMessage = viewModel.errorMessage, !errorMessage.contains("Could not load your exercises") {
                    Section {
                        let _ = print("AddExerciseToWorkoutView: UI State - Displaying general form error: \(errorMessage)")
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            } // End Form
            .navigationTitle("Add Exercise to Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss() // Use environment dismiss action
                    }
                }
                // Optional: Add a "Done" or "Save" button here if preferred
                // ToolbarItem(placement: .navigationBarTrailing) {
                //     Button("Assign") { Task { await viewModel.assignExerciseToWorkout() } }
                //         .disabled(!viewModel.canAssign)
                // }
            }
            .onAppear {
                // Trigger loading of available exercises when the view appears
                print("AddExerciseToWorkoutView: .onAppear triggered. Calling loadTrainerExercises.")
                Task { await viewModel.loadTrainerExercises() }
            }
            .onChange(of: viewModel.didAssignSuccessfully) { newValue in // Updated for newer Swift/iOS
                if newValue { // Check the new value of the boolean
                    print("AddExerciseToWorkoutView: didAssignSuccessfully is true, dismissing.")
                    dismiss() // Dismiss the sheet
                }
            }
            // Handle keyboard submit/next if desired for better form flow
            .onSubmit {
                switch focusedField {
                case .sequence: focusedField = .sets
                case .sets: focusedField = .reps
                case .reps: focusedField = .rest
                case .rest: focusedField = .tempo
                case .tempo: focusedField = .weight
                case .weight: focusedField = .duration
                case .duration: focusedField = .notes
                case .notes: focusedField = nil // Dismiss keyboard
                default: focusedField = nil
                }
            }
        } // End NavigationView
    } // End body
} // End struct AddExerciseToWorkoutView

// Preview Provider
struct AddExerciseToWorkoutView_Previews: PreviewProvider {

    // Helper function to create a fully configured view for previewing
    static func createPreviewInstance() -> some View {
        // 1. Setup mock services
        let mockAuthService = AuthService()
        // Assign properties to the mockAuthService instance
        mockAuthService.authToken = "fake_preview_token"
        mockAuthService.loggedInUser = UserResponse(
            id: "trainerPreview123",
            name: "Preview Trainer",
            email: "trainer@preview.com",
            roles: ["trainer"],
            createdAt: Date(), // Ensure Date() is accessible
            clientIds: nil,
            trainerId: nil
        )
        
        let mockAPIService = APIService(authService: mockAuthService)

        // 2. Create mock Workout data
        let previewWorkout = Workout(
            id: "wPreview1",
            trainingPlanId: "tpPreview1",
            trainerId: "trainerPreview123",
            clientId: "clientPreview789",
            name: "Full Body Strength (Preview)",
            dayOfWeek: 1,
            notes: "Focus on major compound lifts.",
            sequence: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // 3. Define a mock current assignment count
        let mockCurrentAssignmentCount = 0

        // 4. Return the configured view, wrapped in NavigationView
        return NavigationView {
            AddExerciseToWorkoutView(
                workout: previewWorkout,
                currentAssignmentCount: mockCurrentAssignmentCount,
                apiService: mockAPIService
            )
        }
        // Provide environment objects that AddExerciseToWorkoutView or views it presents might need.
        .environmentObject(mockAPIService)
        .environmentObject(mockAuthService)
    }

    static var previews: some View {
        // Call the helper function to get the configured view
        createPreviewInstance()
        // If you wanted multiple previews with different states, you'd call this multiple times
        // with different configurations, perhaps by passing parameters to createPreviewInstance.
        // For now, let's just get one working.
    }
}
