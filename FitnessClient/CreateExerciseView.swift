// CreateExerciseView.swift
import SwiftUI

struct CreateExerciseView: View {
    @StateObject var viewModel: CreateExerciseViewModel
    @Environment(\.dismiss) var dismiss // To dismiss the view after creation

    // For handling focus state and moving between fields
    enum Field: Hashable {
        case name, description, muscleGroup, executionTechnic, videoUrl
    }
    @FocusState private var focusedField: Field?

    init(apiService: APIService) {
        // The view creates its own ViewModel instance
        _viewModel = StateObject(wrappedValue: CreateExerciseViewModel(apiService: apiService))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Name (Required)", text: $viewModel.name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                    
                    TextField("Description (Optional)", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...)
                        .focused($focusedField, equals: .description)
                        .submitLabel(.next)
                    
                    TextField("Muscle Group (e.g., Chest, Legs)", text: $viewModel.muscleGroup)
                        .focused($focusedField, equals: .muscleGroup)
                        .submitLabel(.next)
                }

                Section(header: Text("Execution & Properties")) {
                    TextField("Execution Technic", text: $viewModel.executionTechnic, axis: .vertical)
                        .lineLimit(5...)
                        .focused($focusedField, equals: .executionTechnic)
                        // For the last text field, you might want .done or let the button handle submission
                        // .submitLabel(.done)
                    
                    Picker("Applicability", selection: $viewModel.applicability) {
                        ForEach(viewModel.applicabilityOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                    
                    Picker("Difficulty", selection: $viewModel.difficulty) {
                        ForEach(viewModel.difficultyOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                }
                
                Section(header: Text("Media (Optional)")) {
                    TextField("Video URL (e.g., YouTube, Vimeo)", text: $viewModel.videoUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .videoUrl)
                        .submitLabel(.done)
                }

                Section {
                    if viewModel.isLoading {
                        ProgressView("Creating exercise...")
                    } else {
                        Button("Create Exercise") {
                            focusedField = nil // Dismiss keyboard
                            Task {
                                await viewModel.createExercise()
                            }
                        }
                        .disabled(viewModel.name.isEmpty || viewModel.isLoading)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Exercise")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                // Optional: Add a "Save" button here too if preferred over one in the form
            }
            .onSubmit { // Handle "Next" / "Done" from keyboard
                switch focusedField {
                case .name:
                    focusedField = .description
                case .description:
                    focusedField = .muscleGroup
                case .muscleGroup:
                    focusedField = .executionTechnic
                case .executionTechnic: // After execution technic, no automatic next focus
                    focusedField = .videoUrl // or nil to dismiss keyboard
                case .videoUrl:
                    focusedField = nil // Dismiss keyboard
                default:
                    focusedField = nil
                }
            }
            .onChange(of: viewModel.didCreateExercise) { success in
                if success {
                    dismiss() // Dismiss the view on successful creation
                }
            }
        }
    }
}

struct CreateExerciseView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuth = AuthService() // Need for APIService
        // mockAuth.authToken = "fake" // Simulate login for APIService
        CreateExerciseView(apiService: APIService(authService: mockAuth))
    }
}
