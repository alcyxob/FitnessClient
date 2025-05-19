// EditWorkoutView.swift
import SwiftUI

struct EditWorkoutView: View {
    @StateObject var viewModel: EditWorkoutViewModel
    @Environment(\.dismiss) var dismiss

    enum Field: Hashable { case name, notes, sequence }
    @FocusState private var focusedField: Field?

    init(workoutToEdit: Workout, apiService: APIService) {
        _viewModel = StateObject(wrappedValue: EditWorkoutViewModel(workoutToEdit: workoutToEdit, apiService: apiService))
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Workout Details") {
                    TextField("Workout Name (e.g., Day 1: Chest)", text: $viewModel.workout.name)
                        .focused($focusedField, equals: .name)
                    
                    Picker("Day of Week (Optional)", selection: $viewModel.selectedDayDisplay) {
                        ForEach(viewModel.daysOfWeek, id: \.self) { day in
                            Text(day).tag(day) // Tag with the display string
                        }
                    }
                    
                    HStack { // Ensure TextField for number takes available space
                        Text("Sequence Order")
                        Spacer()
                        TextField("", value: $viewModel.workout.sequence, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .sequence)
                            .frame(width: 80) // Give it some width
                    }

                    TextField("Notes for Client (Optional)", text: Binding(
                        get: { viewModel.workout.notes ?? "" },
                        set: { viewModel.workout.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(4...)
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
            .navigationTitle("Edit Workout")
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
            // .onSubmit { ... handle keyboard next ... }
        }
    }
}

// Preview Provider
struct EditWorkoutView_Previews: PreviewProvider {
    static func createPreviewInstance() -> some View {
        let mockAuth = AuthService()
        let mockAPI = APIService(authService: mockAuth)
        
        let previewWorkout = Workout(
            id: "wEditPreview1", trainingPlanId: "tp1", trainerId: "t1", clientId: "c1",
            name: "Leg Day Strength", dayOfWeek: 2, notes: "Focus on quads and hams.",
            sequence: 1, createdAt: Date(), updatedAt: Date()
        )
        return EditWorkoutView(workoutToEdit: previewWorkout, apiService: mockAPI)
            .environmentObject(mockAPI) // If sub-views need it
            .environmentObject(mockAuth)
    }
    static var previews: some View {
        createPreviewInstance()
    }
}
