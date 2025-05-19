// EditExerciseView.swift
import SwiftUI

struct EditExerciseView: View {
    // ViewModel is created by this view, initialized with the exercise to edit
    @StateObject var viewModel: EditExerciseViewModel
    @Environment(\.dismiss) var dismiss

    enum Field: Hashable { // For focus state
        case name, description, muscleGroup, executionTechnic, videoUrl
    }
    @FocusState private var focusedField: Field?

    // Initializer takes the exercise to edit and the APIService
    init(exerciseToEdit: Exercise, apiService: APIService) {
        _viewModel = StateObject(wrappedValue: EditExerciseViewModel(exerciseToEdit: exerciseToEdit, apiService: apiService))
    }

    var body: some View {
        NavigationView { // Good for sheets to have their own navigation context
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Name (Required)", text: $viewModel.exercise.name)
                        .focused($focusedField, equals: .name)
                    
                    TextField("Description", text: Binding( // Binding for optional String
                        get: { viewModel.exercise.description ?? "" },
                        set: { viewModel.exercise.description = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...)
                    .focused($focusedField, equals: .description)
                    
                    TextField("Muscle Group", text: Binding(
                        get: { viewModel.exercise.muscleGroup ?? "" },
                        set: { viewModel.exercise.muscleGroup = $0.isEmpty ? nil : $0 }
                    ))
                    .focused($focusedField, equals: .muscleGroup)
                }

                Section(header: Text("Execution & Properties")) {
                    TextField("Execution Technic", text: Binding(
                        get: { viewModel.exercise.executionTechnic ?? "" },
                        set: { viewModel.exercise.executionTechnic = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(5...)
                    .focused($focusedField, equals: .executionTechnic)
                    
                    Picker("Applicability", selection: Binding(
                        get: { viewModel.exercise.applicability ?? viewModel.applicabilityOptions.first! },
                        set: { viewModel.exercise.applicability = $0 }
                    )) {
                        ForEach(viewModel.applicabilityOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    
                    Picker("Difficulty", selection: Binding(
                        get: { viewModel.exercise.difficulty ?? viewModel.difficultyOptions.first! },
                        set: { viewModel.exercise.difficulty = $0 }
                    )) {
                        ForEach(viewModel.difficultyOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }
                
                Section(header: Text("Media (Optional)")) {
                    TextField("Video URL", text: Binding(
                        get: { viewModel.exercise.videoUrl ?? "" },
                        set: { viewModel.exercise.videoUrl = $0.isEmpty ? nil : $0 }
                    ))
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .videoUrl)
                }

                Section {
                    if viewModel.isLoading {
                        ProgressView("Saving Changes...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Button("Save Changes") {
                            focusedField = nil // Dismiss keyboard
                            Task { await viewModel.saveChanges() }
                        }
                        .disabled(!viewModel.canSaveChanges)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            } // End Form
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        focusedField = nil
                        Task { await viewModel.saveChanges() }
                    }
                    .disabled(!viewModel.canSaveChanges)
                }
            }
            .onChange(of: viewModel.didUpdateSuccessfully) { success in
                if success { dismiss() }
            }
            // .onSubmit { ... handle keyboard next/done ... }
        } // End NavigationView
    }
}

// Preview Provider
struct EditExerciseView_Previews: PreviewProvider {
    static func createPreviewInstance() -> some View {
        let mockAuth = AuthService()
        mockAuth.authToken = "fake_token"
        // ... setup mockAuth.loggedInUser if needed by APIService globally
        let mockAPI = APIService(authService: mockAuth)
        
        let previewExercise = Exercise(
            id: "exEditPreview1", trainerId: "trainer123", name: "Sample Push-ups",
            description: "A classic exercise.", muscleGroup: "Chest",
            executionTechnic: "Keep core engaged.", applicability: "Any", difficulty: "Medium",
            videoUrl: nil, createdAt: Date(), updatedAt: Date()
        )

        return EditExerciseView(exerciseToEdit: previewExercise, apiService: mockAPI)
            .environmentObject(mockAPI) // If any sub-views of EditExerciseView need it
            .environmentObject(mockAuth)
    }
    static var previews: some View {
        createPreviewInstance()
    }
}
