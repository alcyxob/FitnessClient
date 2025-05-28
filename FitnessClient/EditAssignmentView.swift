// EditAssignmentView.swift
import SwiftUI

struct EditAssignmentView: View {
    @StateObject var viewModel: EditAssignmentViewModel
    @Environment(\.dismiss) var dismiss

    // Focus state can be reused from AddExerciseToWorkoutView if similar fields
    enum Field: Hashable {
        case name, description, muscleGroup, executionTechnic, videoUrl, sequence, sets, reps, rest, tempo, weight, duration, notes
    }
    @FocusState private var focusedField: Field?
    
    static private var displayIntegerFormatter: NumberFormatter = { // Renamed for clarity
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal // Good for display
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    init(assignmentToEdit: Assignment, apiService: APIService) {
        _viewModel = StateObject(wrappedValue: EditAssignmentViewModel(assignmentToEdit: assignmentToEdit, apiService: apiService))
    }

    var body: some View {
        NavigationView {
            Form {
                // Section for Selecting/Confirming Exercise
                Section("Exercise") {
                    if viewModel.isLoadingExercises {
                        ProgressView("Loading exercise library...")
                    } else if viewModel.availableExercises.isEmpty && viewModel.assignment.exercise == nil {
                        // This case happens if exercise library is empty AND original assignment had no exercise detail
                        Text("No exercises available in library.")
                    } else {
                        // Picker to potentially change the exercise
                        Picker("Exercise", selection: $viewModel.selectedExerciseId) {
                            Text("Select an Exercise")
                                .tag(String?.none) // <<< FIX 1: Use nil for the "no selection" tag

                            ForEach(viewModel.availableExercises) { exercise in
                                Text(exercise.name)
                                    .tag(Optional(exercise.id)) // <<< FIX 2: Tag with Optional(exercise.id)
                            }
                        }
                        // Display current exercise name if not editing via picker, or picker is empty
                        if viewModel.availableExercises.isEmpty, let currentExerciseName = viewModel.assignment.exercise?.name {
                            Text("Current: \(currentExerciseName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Parameters") {
                    sequenceField
                    setsField
                    repsField
                    restField
                    tempoField
                    weightField
                    durationField
                }

                Section("Trainer Notes (Optional)") {
                    TextEditor(text: Binding(
                        get: { viewModel.assignment.trainerNotes ?? "" },
                        set: { viewModel.assignment.trainerNotes = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 80, maxHeight: 150)
                    .focused($focusedField, equals: .notes)
                }
                
                Section {
                    if viewModel.isLoading {
                        ProgressView("Saving Changes...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Button("Save Changes") {
                            focusedField = nil
                            Task { await viewModel.saveChanges() }
                        }
                        .disabled(!viewModel.canSaveChanges)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section { Text("Error: \(errorMessage)").foregroundColor(.red) }
                }
            }
            .navigationTitle("Edit Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        focusedField = nil
                        Task { await viewModel.saveChanges() }
                    }
                    .disabled(!viewModel.canSaveChanges)
                }
            }
            .onAppear {
                // Load trainer's exercises for the picker if allowing exercise change
                Task { await viewModel.loadTrainerExercises() }
            }
            .onChange(of: viewModel.didUpdateSuccessfully) { success in
                if success { dismiss() }
            }
            // .onSubmit { ... handle keyboard next ... }
        } // End NavigationView
    }
    
    // --- HELPER COMPUTED PROPERTIES FOR PARAMETER FIELDS ---
    @ViewBuilder
    private var sequenceField: some View {
        HStack {
            Text("Sequence")
            Spacer()
            TextField("Order", text: Binding(
                get: { String(viewModel.assignment.sequence) },
                set: { viewModel.assignment.sequence = Int($0) ?? 0 }
            ))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .focused($focusedField, equals: .sequence)
            .frame(width: 80)
        }
    }

    @ViewBuilder
    private var setsField: some View {
        HStack {
            Text("Sets")
            Spacer()
            TextField("e.g., 3", text: Binding(
                get: { viewModel.assignment.sets.map { String($0) } ?? "" },
                set: { viewModel.assignment.sets = Int($0) }
            ))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .focused($focusedField, equals: .sets)
            .frame(width: 80)
        }
    }

    @ViewBuilder
    private var repsField: some View {
        TextField("Reps (e.g., 8-12)", text: Binding(
            get: { viewModel.assignment.reps ?? "" },
            set: { viewModel.assignment.reps = $0.isEmpty ? nil : $0 }
        )).focused($focusedField, equals: .reps)
    }

    @ViewBuilder
    private var restField: some View {
        TextField("Rest (e.g., 60s)", text: Binding(
            get: { viewModel.assignment.rest ?? "" },
            set: { viewModel.assignment.rest = $0.isEmpty ? nil : $0 }
        )).focused($focusedField, equals: .rest)
    }

    @ViewBuilder
    private var tempoField: some View {
        TextField("Tempo (e.g., 2010)", text: Binding(
            get: { viewModel.assignment.tempo ?? "" },
            set: { viewModel.assignment.tempo = $0.isEmpty ? nil : $0 }
        )).focused($focusedField, equals: .tempo)
    }

    @ViewBuilder
    private var weightField: some View {
        TextField("Weight/Intensity", text: Binding(
            get: { viewModel.assignment.weight ?? "" },
            set: { viewModel.assignment.weight = $0.isEmpty ? nil : $0 }
        )).focused($focusedField, equals: .weight)
    }

    @ViewBuilder
    private var durationField: some View {
        TextField("Duration (e.g., 30min)", text: Binding(
            get: { viewModel.assignment.duration ?? "" },
            set: { viewModel.assignment.duration = $0.isEmpty ? nil : $0 }
        )).focused($focusedField, equals: .duration)
    }
    // --- END HELPER COMPUTED PROPERTIES ---

}

// Preview Provider
struct EditAssignmentView_Previews: PreviewProvider {
    static func createPreviewInstance() -> some View {
        let mockAuth = AuthService(); /* setup mockAuth */
        let mockAPI = APIService(authService: mockAuth);
        let mockExercise = Exercise(id: "exEdit1", trainerId: "t1", name: "Bench Press", createdAt: Date(), updatedAt: Date())
        let previewAssignment = Assignment(
            id: "assignEdit1", workoutId: "w1", exerciseId: mockExercise.id, assignedAt: Date(), status: "assigned",
            sets: 3, reps: "10", rest: "60s", tempo: "2010", weight: "70kg", duration: nil, sequence: 0,
            trainerNotes: "Focus on chest activation.", clientNotes: nil, uploadId: nil, feedback: nil,
            updatedAt: Date(), exercise: mockExercise // Pre-populate for preview
        )
        return EditAssignmentView(assignmentToEdit: previewAssignment, apiService: mockAPI)
            .environmentObject(mockAPI).environmentObject(mockAuth)
    }
    static var previews: some View { createPreviewInstance() }
}
