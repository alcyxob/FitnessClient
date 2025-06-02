// TrainerClientsViewModel.swift
import Foundation
import SwiftUI

@MainActor // Ensure UI updates happen on the main thread
class TrainerClientsViewModel: ObservableObject {
    @Published var clients: [UserResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var greeting: String = ""

    private let apiService: APIService
    // No need for AuthService directly if APIService handles token correctly

    init(apiService: APIService) {
        self.apiService = apiService
    }

    func fetchManagedClients() async {
        print("ViewModel: Fetching managed clients...")
        isLoading = true
        errorMessage = nil
        // Don't clear clients immediately, maybe show stale data while loading
        // clients = []

        do {
            let fetchedClients: [UserResponse] = try await apiService.GET(endpoint: "/trainer/clients")
            self.clients = fetchedClients
            print("ViewModel: Successfully fetched \(fetchedClients.count) clients.")
            if fetchedClients.isEmpty {
                // Could set a specific message if needed
                // self.errorMessage = "You haven't added any clients yet."
            }
        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("ViewModel Error fetching clients (APINetworkError): \(error.localizedDescription)")
            // Keep existing client list on error? Or clear it? Depends on desired UX
             self.clients = [] // Clear list on error for simplicity now
        } catch {
            self.errorMessage = "An unexpected error occurred while fetching clients."
            print("ViewModel Unexpected error fetching clients: \(error.localizedDescription)")
             self.clients = [] // Clear list on error
        }
        isLoading = false
    }
}
