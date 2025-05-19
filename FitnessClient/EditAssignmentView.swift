// EditAssignmentView.swift
import SwiftUI

struct EditAssignmentView: View {
    @StateObject var viewModel: EditAssignmentViewModel
    @Environment(\.dismiss) var dismiss

    // Focus state can be reused from AddExerciseToWorkoutView if similar fields
    enum Field: Hashable {
        case sets, reps, rest, tempo, weight, duration, notes, sequence
    }
    @FocusState private var focusedField: Field?

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
                            Text("Select an Exercise").tag(String.self) // Placeholder if nothing selected
                            ForEach(viewModel.availableExercises) { exercise in
                                Text(exercise.name).tag(exercise.id)
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
                    HStack {
                        Text("Sequence")
                        Spacer()
                        TextField("Order", value: $viewModel.assignment.sequence, format: .number)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing).focused($focusedField, equals: .sequence)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Sets")
                        Spacer()
                        // Bind to Int? for sets
                        TextField("e.g., 3", text: Binding(
                            get: { viewModel.assignment.sets.map { String($0) } ?? "" },
                            set: { viewModel.assignment.sets = Int($0) }
                        ))
                        .keyboardType(.numberPad).multilineTextAlignment(.trailing).focused($focusedField, equals: .sets)
                        .frame(width: 80)
                    }
                    TextField("Reps (e.g., 8-12)", text: Binding(
                        get: { viewModel.assignment.reps ?? "" },
                        set: { viewModel.assignment.reps = $0.isEmpty ? nil : $0 }
                    )).focused($focusedField, equals: .reps)
                    
                    TextField("Rest (e.g., 60s)", text: Binding(
                        get: { viewModel.assignment.rest ?? "" },
                        set: { viewModel.assignment.rest = $0.isEmpty ? nil : $0 }
                    )).focused($focusedField, equals: .rest)

                    TextField("Tempo (e.g., 2010)", text: Binding(
                        get: { viewModel.assignment.tempo ?? "" },
                        set: { viewModel.assignment.tempo = $0.isEmpty ? nil : $0 }
                    )).focused($focusedField, equals: .tempo)

                    TextField("Weight/Intensity", text: Binding(
                        get: { viewModel.assignment.weight ?? "" },
                        set: { viewModel.assignment.weight = $0.isEmpty ? nil : $0 }
                    )).focused($focusedField, equals: .weight)

                    TextField("Duration (e.g., 30min)", text: Binding(
                        get: { viewModel.assignment.duration ?? "" },
                        set: { viewModel.assignment.duration = $0.isEmpty ? nil : $0 }
                    )).focused($focusedField, equals: .duration)
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
                    } else {
                        Button("Save Changes") {
                            focusedField = nil
                            Task { await viewModel.saveChanges() }
                        }
                        .disabled(!viewModel.canSaveChanges)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
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
