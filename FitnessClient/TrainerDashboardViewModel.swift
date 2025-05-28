// TrainerDashboardViewModel.swift
import Foundation
import SwiftUI

@MainActor
class TrainerDashboardViewModel: ObservableObject {
    @Published var clientsWithPendingReviews: [ClientReviewStatusItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var greeting: String = ""

    private let apiService: APIService
    private let authService: AuthService // To get trainer's name for greeting

    init(apiService: APIService, authService: AuthService) {
        self.apiService = apiService
        self.authService = authService
        print("TrainerDashboardViewModel: Initialized.")
        updateGreeting()
    }
    
    func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        if let trainerName = authService.loggedInUser?.name.components(separatedBy: " ").first {
            switch hour {
            case 0..<5: greeting = "Burning the midnight oil, \(trainerName)?"
            case 5..<12: greeting = "Good Morning, \(trainerName)!"
            case 12..<18: greeting = "Good Afternoon, \(trainerName)!"
            default: greeting = "Good Evening, \(trainerName)!"
            }
        } else {
            greeting = "Welcome, Trainer!"
        }
    }

    func fetchPendingReviews() async {
        print("TrainerDashboardVM: Fetching clients with pending reviews...")
        isLoading = true
        errorMessage = nil
        // clientsWithPendingReviews = [] // Optional: Clear or show stale

        let endpoint = "/trainer/dashboard/pending-reviews"

        do {
            let fetchedItems: [ClientReviewStatusItem] = try await apiService.GET(endpoint: endpoint)
            // Sort by pending count descending, then by name
            self.clientsWithPendingReviews = fetchedItems.sorted {
                if $0.pendingReviewCount != $1.pendingReviewCount {
                    return $0.pendingReviewCount > $1.pendingReviewCount
                }
                return $0.clientName < $1.clientName
            }
            print("TrainerDashboardVM: Successfully fetched \(fetchedItems.count) clients with pending items.")
            if fetchedItems.isEmpty {
                // self.errorMessage = "No clients have submissions awaiting review." // Or handle in view
            }
        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("TrainerDashboardVM: Error fetching pending reviews (APINetworkError): \(error.localizedDescription)")
            self.clientsWithPendingReviews = []
        } catch {
            self.errorMessage = "An unexpected error occurred while fetching pending reviews."
            print("TrainerDashboardVM: Unexpected error: \(error.localizedDescription)")
            self.clientsWithPendingReviews = []
        }
        isLoading = false
        print("TrainerDashboardVM: fetchPendingReviews finished. isLoading: \(isLoading), Count: \(clientsWithPendingReviews.count), Error: \(errorMessage ?? "None")")
    }
}
