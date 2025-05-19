// AssignExerciseView.swift
import SwiftUI
import PhotosUI // Not strictly needed by THIS view, but good to keep imports tidy if related files use it.

struct AssignExerciseView: View {
    // This view creates and owns its ViewModel instance.
    // The ViewModel used here is AddExerciseToWorkoutViewModel.
    @StateObject var viewModel: AddExerciseToWorkoutViewModel
    @Environment(\.dismiss) var dismiss

    // For handling keyboard focus and "next" field behavior
    enum Field: Hashable {
        case sets, reps, rest, tempo, weight, duration, notes, sequence
    }
    @FocusState private var focusedField: Field?

    // This is the primary initializer for live app usage.
    // It receives the workout to assign to, current assignment count for sequence, and APIService.
    init(workout: Workout, currentAssignmentCount: Int, apiService: APIService) {
        // Internally, it creates an instance of AddExerciseToWorkoutViewModel.
        // The name of THIS view file is AssignExerciseView.swift, but the VM it uses is AddExerciseToWorkoutViewModel.
        // This is okay, but ensure consistency if it's confusing.
        _viewModel = StateObject(wrappedValue: AddExerciseToWorkoutViewModel(workout: workout, currentAssignmentCount: currentAssignmentCount, apiService: apiService))
        print("AssignExerciseView: Initialized for workout: \(workout.name)")
    }

    var body: some View {
        // Debug print to trace body re-evaluation and key ViewModel states
        let _ = print("AssignExerciseView BODY re-evaluating: isLoadingExercises: \(viewModel.isLoadingExercises), availableExercises.count: \(viewModel.availableExercises.count), selectedExerciseId: \(viewModel.selectedExerciseId ?? "nil"), generalIsLoading: \(viewModel.isLoading), errorMessage: \(viewModel.errorMessage ?? "None")")

        NavigationView { // Provides structure for title and buttons, especially in a sheet
            Form {
                // --- Section for Selecting an Exercise from the trainer's library ---
                Section("Select Exercise") {
                    if viewModel.isLoadingExercises {
                        HStack { Spacer(); ProgressView("Loading your exercises..."); Spacer() }
                    } else if viewModel.availableExercises.isEmpty {
                        if let errorMsg = viewModel.errorMessage, errorMsg.contains("Could not load your exercises") {
                            Text("Error loading exercises: \(errorMsg)")
                                .foregroundColor(.red)
                        } else {
                            Text("No exercises found in your library. Please create some exercises first in the 'My Exercises' tab.")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Picker("Exercise", selection: $viewModel.selectedExerciseId) {
                            Text("Choose an exercise").tag(String?.none) // Placeholder for optional selection
                            ForEach(viewModel.availableExercises) { exercise in
                                Text(exercise.name)
                                    .tag(Optional(exercise.id)) // Tag must match optional selection type
                            }
                        }
                    }
                } // End Section "Select Exercise"

                // --- Section for Assignment Parameters ---
                // Only show these if an exercise has been selected and exercises are loaded
                if viewModel.selectedExerciseId != nil && !viewModel.availableExercises.isEmpty && !viewModel.isLoadingExercises {
                    Section("Parameters") {
                        HStack {
                            Text("Sequence in Workout") // Clarity for user
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
                            .frame(minHeight: 80, maxHeight: 150) // Constrain TextEditor height
                            .focused($focusedField, equals: .notes)
                    } // End Section "Notes"
                } // End Conditional Parameter Sections
                
                // --- Section for the Action Button ---
                Section {
                    if viewModel.isLoading { // General isLoading for the "assign" action
                        ProgressView("Assigning Exercise...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
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
                ToolbarItem(placement: .navigationBarTrailing) { // Optional "Done" for keyboard
                    if focusedField != nil {
                        Button("Done") { focusedField = nil }
                    }
                }
            }
            .onAppear {
                // Trigger loading of available exercises when the view appears
                print("AssignExerciseView: .onAppear. Calling loadTrainerExercises.")
                Task { await viewModel.loadTrainerExercises() }
            }
            .onChange(of: viewModel.didAssignSuccessfully) { newValue in
                if newValue {
                    print("AssignExerciseView: didAssignSuccessfully is true, dismissing.")
                    dismiss()
                }
            }
            // Handle keyboard submit/next for better form flow
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
} // End struct AssignExerciseView


// CORRECTED Preview Provider
struct AssignExerciseView_Previews: PreviewProvider {
    // Helper static function to create a configured preview instance
    static func createPreviewInstance(isLoadingExercises: Bool = false, hasExercises: Bool = true, hasError: String? = nil) -> some View {
        // 1. Setup mock services
        let mockAuthService = AuthService()
        mockAuthService.authToken = "fake_preview_token"
        mockAuthService.loggedInUser = UserResponse(
            id: "trainerPreview123", name: "Preview Trainer", email: "trainer@preview.com", role: "trainer",
            createdAt: Date(), clientIds: nil, trainerId: nil
        )
        let mockAPIService = APIService(authService: mockAuthService)

        // 2. Create mock Workout data
        let previewWorkout = Workout(
            id: "wPreviewAssign1", trainingPlanId: "tpPreviewAssign1", trainerId: "trainerPreview123",
            clientId: "clientPreviewAssign789", name: "Upper Body Focus (Preview)", dayOfWeek: 2,
            notes: "Push and Pull movements.", sequence: 0, createdAt: Date(), updatedAt: Date()
        )
        
        // 3. Define a mock current assignment count
        let mockCurrentAssignmentCount = 0

        // 4. Create the ViewModel that AssignExerciseView's init will create
        // We do this here to pre-configure it for different preview states
        let vm = AddExerciseToWorkoutViewModel(
            workout: previewWorkout,
            currentAssignmentCount: mockCurrentAssignmentCount,
            apiService: mockAPIService
        )

        if isLoadingExercises {
            vm.isLoadingExercises = true
        } else if let error = hasError {
            vm.errorMessage = error
            vm.availableExercises = []
        } else if hasExercises {
            vm.availableExercises = [
                Exercise(id: "ex1", trainerId: "trainerPreview123", name: "Barbell Squats", description: "Compound leg exercise.", createdAt: Date(), updatedAt: Date()),
                Exercise(id: "ex2", trainerId: "trainerPreview123", name: "Bench Press", description: "Compound chest exercise.", createdAt: Date(), updatedAt: Date())
            ]
        } else { // No exercises, no error
            vm.availableExercises = []
        }
        
        // 5. Return the view, creating it by passing the pre-configured ViewModel
        // THIS REQUIRES AssignExerciseView to have an init(viewModel: AddExerciseToWorkoutViewModel)
        // If AssignExerciseView only has init(workout:currentAssignmentCount:apiService:),
        // then we cannot easily pre-configure the ViewModel for previews like this.

        // Let's stick to the init that AssignExerciseView currently has:
        return NavigationView {
            AssignExerciseView(
                workout: previewWorkout,
                currentAssignmentCount: mockCurrentAssignmentCount,
                apiService: mockAPIService // The view's onAppear will call loadTrainerExercises
                                           // To truly test different states without API calls,
                                           // you'd need a MockAPIService.
            )
        }
        .environmentObject(mockAPIService)
        .environmentObject(mockAuthService)
    }

    static var previews: some View {
        // Call the helper function to get the configured view
        // This preview will show the loading state, then fetch (mocked or real) data
        createPreviewInstance()
            .previewDisplayName("Default Load")

        // To properly preview different states of AddExerciseToWorkoutViewModel
        // (like pre-loaded exercises, error state for exercise loading)
        // you would ideally modify AddExerciseToWorkoutView to accept an
        // optional, pre-configured viewModel in its initializer for testing/previews.
        // Example:
        // createPreviewInstance(isLoadingExercises: true).previewDisplayName("Loading Exercises")
        // createPreviewInstance(hasExercises: false, hasError: "Network Failed").previewDisplayName("Error Loading")
        // createPreviewInstance(hasExercises: false).previewDisplayName("No Exercises")
    }
}
