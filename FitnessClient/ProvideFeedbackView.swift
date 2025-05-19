// ProvideFeedbackView.swift
import SwiftUI

struct ProvideFeedbackView: View {
    @StateObject var viewModel: ProvideFeedbackViewModel
    @Environment(\.dismiss) var dismiss

    init(assignment: Assignment, apiService: APIService) {
        _viewModel = StateObject(wrappedValue: ProvideFeedbackViewModel(assignment: assignment, apiService: apiService))
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Reviewing Exercise") {
                    Text(viewModel.assignment.exercise?.name ?? "Exercise ID: \(viewModel.assignment.exerciseId)")
                        .font(.headline)
                    if viewModel.assignment.status == "submitted" {
                        Text("Client has submitted a video for this exercise.")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }

                Section("Your Feedback") {
                    TextEditor(text: $viewModel.feedbackText)
                        .frame(minHeight: 150, maxHeight: 300)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                }

                Section("Update Status") {
                    Picker("New Status", selection: $viewModel.selectedStatus) {
                        ForEach(viewModel.availableStatuses, id: \.self) { statusValue in
                            Text(statusValue.capitalized).tag(statusValue)
                        }
                    }
                    // .pickerStyle(.segmented) // Alternative style
                }

                Section {
                    if viewModel.isLoading {
                        ProgressView("Submitting Feedback...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Button("Submit Feedback & Update Status") {
                            Task { await viewModel.submitFeedback() }
                        }
                        .disabled(!viewModel.canSubmitFeedback)
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
            }
            .navigationTitle("Provide Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") { Task { await viewModel.submitFeedback() } }
                        .disabled(!viewModel.canSubmitFeedback)
                }
            }
            .onChange(of: viewModel.didSubmitSuccessfully) { success in
                if success { dismiss() }
            }
        }
    }
}

// Preview Provider
struct ProvideFeedbackView_Previews: PreviewProvider {
    static func createPreviewInstance() -> some View {
        let mockAuth = AuthService()
        mockAuth.authToken = "fake_token"
        mockAuth.loggedInUser = UserResponse(id: "trainer1", name: "Preview Trainer", email: "t@p.com", role: "trainer", createdAt: Date(), clientIds: nil, trainerId: nil)
        let mockAPI = APIService(authService: mockAuth)

        let mockExercise = Exercise(id: "ex1", trainerId: "trainer1", name: "Preview Push Ups", createdAt: Date(), updatedAt: Date())
        let previewAssignment = Assignment(
            id: "assignPrev1", workoutId: "w1", exerciseId: "ex1", assignedAt: Date(), status: domain.AssignmentStatus.submitted.rawValue,
            sets: 3, reps: "10", rest: "60s", tempo: nil, weight: "BW", duration: nil, sequence: 0,
            trainerNotes: "Keep form strict.", clientNotes: "Felt challenging!", uploadId: "fakeUploadId", feedback: nil,
            updatedAt: Date(), exercise: mockExercise
        )

        return ProvideFeedbackView(assignment: previewAssignment, apiService: mockAPI)
            .environmentObject(mockAPI) // In case sub-views need it, though unlikely
            .environmentObject(mockAuth)
    }
    
    static var previews: some View {
        createPreviewInstance()
    }
}
