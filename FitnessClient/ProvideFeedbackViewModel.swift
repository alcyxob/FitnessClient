// ProvideFeedbackViewModel.swift
import Foundation
import SwiftUI

@MainActor
class ProvideFeedbackViewModel: ObservableObject {
    // Input properties from the view
    @Published var feedbackText: String = ""
    @Published var selectedStatus: String // Initialized with current assignment status or "reviewed"

    // Available statuses a trainer can set
    let availableStatuses: [String] = [
        domain.AssignmentStatus.reviewed.rawValue, // Assuming AssignmentStatus is an enum with rawValue String
        domain.AssignmentStatus.assigned.rawValue  // To re-assign if client needs to re-do
        // Add more like "needs_revision" if your backend/domain supports it
    ]

    // State Management
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var didSubmitSuccessfully = false

    // Dependencies
    let assignment: Assignment // The assignment feedback is for
    private let apiService: APIService
    // No need for authService directly if APIService handles token

    var canSubmitFeedback: Bool {
        // Feedback can be empty if only changing status, but status must be selected.
        !selectedStatus.isEmpty && !isLoading
    }

    init(assignment: Assignment, apiService: APIService) {
        self.assignment = assignment
        self.apiService = apiService
        // Default to "reviewed" if current status is "submitted", otherwise keep current or offer options
        if assignment.status.lowercased() == domain.AssignmentStatus.submitted.rawValue {
            self.selectedStatus = domain.AssignmentStatus.reviewed.rawValue
        } else {
            self.selectedStatus = assignment.status // Or default to "reviewed"
        }
        self.feedbackText = assignment.feedback ?? "" // Pre-fill with existing feedback if any
        print("ProvideFeedbackVM: Initialized for assignment: \(assignment.id), current status: \(assignment.status)")
    }

    func submitFeedback() async {
        guard canSubmitFeedback else {
            if selectedStatus.isEmpty { errorMessage = "Please select a new status." }
            return
        }

        isLoading = true
        errorMessage = nil
        didSubmitSuccessfully = false
        print("ProvideFeedbackVM: Submitting feedback for assignment \(assignment.id) with status '\(selectedStatus)'")

        let payload = SubmitFeedbackPayload(
            feedback: feedbackText.isEmpty ? nil : feedbackText, // Send nil if feedback is empty
            status: selectedStatus
        )

        let endpoint = "/trainer/assignments/\(assignment.id)/feedback"

        do {
            // Use PATCH method from APIService
            let updatedAssignment: Assignment = try await apiService.PATCH(endpoint: endpoint, body: payload)
            
            print("ProvideFeedbackVM: Successfully submitted feedback. New status: \(updatedAssignment.status)")
            isLoading = false
            didSubmitSuccessfully = true

        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("ProvideFeedbackVM: Error submitting feedback (APINetworkError): \(error.localizedDescription)")
            isLoading = false
        } catch {
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            print("ProvideFeedbackVM: Unexpected error submitting feedback: \(error.localizedDescription)")
            isLoading = false
        }
    }
}

// Helper: Assuming you have a domain.AssignmentStatus enum in Swift matching Go
// If not, you'll use raw strings like "reviewed", "assigned".
// This could be in Models.swift
//enum domain { // Mocking the namespace for clarity
//
//}
