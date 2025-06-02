// ClientDetailViewModel.swift
import Foundation
import SwiftUI

@MainActor
class ClientDetailViewModel: ObservableObject {
    // Client whose details we are viewing
    @Published var client: UserResponse? = nil
    @Published var isLoadingClientDetails = false

    // Data fetched for this client
    @Published var trainingPlans: [TrainingPlan] = []
    @Published var isLoadingPlans = false
    @Published var errorMessage: String? = nil

    private let apiService: APIService
    private let authService: AuthService // Needed? Only if trainerID isn't reliably in APIService/client
    private let initialClientID: String?

    var trainerId: String? {
        // Get trainer ID reliably (e.g., from logged-in user)
        authService.loggedInUser?.id
    }

    // Initializer for when full client object is already available
    init(client: UserResponse, apiService: APIService, authService: AuthService) {
        self.client = client
        self.initialClientID = nil // Not needed if client object is passed
        self.apiService = apiService
        self.authService = authService
        print("ClientDetailVM: Initialized with full client object: \(client.email)")
    }

    // --- Initializer for when only clientID is available ---
    init(clientId: String, apiService: APIService, authService: AuthService) {
        self.initialClientID = clientId
        self.client = nil // Will be fetched
        self.apiService = apiService
        self.authService = authService
        self.isLoadingClientDetails = true // Start loading client details
        print("ClientDetailVM: Initialized with clientID: \(clientId). Will fetch details.")
    }
    
    func fetchClientDetailsIfNeeded() async {
        // Only fetch if initialized with an ID AND client details haven't been loaded yet
        guard let clientIdToFetch = initialClientID, self.client == nil else {
            if let currentClient = self.client { // Safely unwrap
                print("ClientDetailVM: Client details already present for \(currentClient.email).")
            } else if initialClientID == nil {
                print("ClientDetailVM: Initialized with full client object, no fetch needed.")
            }
            return
        }
        
        print("ClientDetailVM: Fetching details for client ID: \(clientIdToFetch)...")
        self.isLoadingClientDetails = true
        self.errorMessage = nil

        do {
            // WORKAROUND: Fetch all managed clients and find the one.
            // Ideally, replace with a direct GET /trainer/clients/{oneClientId} or GET /users/{id}
            let allManagedClients: [UserResponse] = try await apiService.GET(endpoint: "/trainer/clients")
            if let foundClient = allManagedClients.first(where: { $0.id == clientIdToFetch }) {
                self.client = foundClient // Assign to Optional UserResponse?
                print("ClientDetailVM: Successfully fetched details for client: \(foundClient.email)")
            } else {
                throw APINetworkError.serverError(statusCode: 404, message: "Client \(clientIdToFetch) not found in your managed list.")
            }
        } catch let error as APINetworkError {
            self.errorMessage = "Failed to load client details: \(error.localizedDescription)"
            print("ClientDetailVM: Error fetching client details (APINetworkError): \(error.localizedDescription)")
            self.client = nil // Ensure client is nil on error
        } catch {
            self.errorMessage = "An unexpected error occurred loading client details."
            print("ClientDetailVM: Unexpected error fetching client details: \(error.localizedDescription)")
            self.client = nil // Ensure client is nil on error
        }
        self.isLoadingClientDetails = false
    }



    func fetchTrainingPlans() async {
        
        guard let currentClient = self.client else {
            errorMessage = "Client details not available to fetch plans."
            print("ClientDetailVM: Client object is nil, cannot fetch plans.")
            // If initialized with ID, try fetching client details first
            if let clientIdToFetch = initialClientID, !isLoadingClientDetails {
                print("ClientDetailVM: Triggering client detail fetch before fetching plans.")
                await fetchClientDetailsIfNeeded()
                if self.client != nil { // If successful, retry fetching plans
                    await fetchTrainingPlans()
                }
            }
            return
        }
        
        guard let currentClient = self.client else { return }
        
        print("ClientDetailVM: Fetching training plans for client \(currentClient.id)...")
        isLoadingPlans = true
        //errorMessage = nil
        let endpoint = "/trainer/clients/\(currentClient.id)/plans"

        do {
            let fetchedPlans: [TrainingPlan] = try await apiService.GET(endpoint: endpoint)
            self.trainingPlans = fetchedPlans
            print("ClientDetailVM: Successfully fetched \(fetchedPlans.count) plans.")
            if fetchedPlans.isEmpty {
                 // self.errorMessage = "No training plans found for this client." // Optional message
            }
            self.errorMessage = nil // Clear error if plan fetch was successful
        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("ClientDetailVM: Error fetching plans (APINetworkError): \(error.localizedDescription)")
            self.trainingPlans = [] // Clear on error
        } catch {
            self.errorMessage = "An unexpected error occurred while fetching plans."
            print("ClientDetailVM: Unexpected error fetching plans: \(error.localizedDescription)")
            self.trainingPlans = [] // Clear on error
        }
        isLoadingPlans = false
    }
    
    // --- Delete Training Plan ---
    func deleteTrainingPlan(planId: String) async -> Bool { // Return Bool for success/failure
        guard let currentClient = self.client, let currentTrainerId = trainerId else {
            errorMessage = "Cannot verify client/trainer for delete operation."
            return false
        }
        print("ClientDetailVM: Attempting to delete plan \(planId) for client \(currentClient.id) by trainer \(currentTrainerId)")

        // Endpoint: /trainer/clients/{clientId}/plans/{planId}
        let endpoint = "/trainer/clients/\(currentClient.id)/plans/\(planId)"

        do {
            // APIService.DELETE typically doesn't return a decodable body, just checks status
            try await apiService.DELETE(endpoint: endpoint)
            print("ClientDetailVM: Successfully deleted plan \(planId) from backend.")
            
            // Remove from local list optimistically
            self.trainingPlans.removeAll { $0.id == planId }
            
            // If the deleted plan was active, you might need logic to select a new active one,
            // or just let the list refresh.
            if trainingPlans.isEmpty {
                self.errorMessage = "No training plans assigned yet." // Update empty message
            }
            
            return true // Success
        } catch let error as APINetworkError {
            self.errorMessage = "Delete failed: \(error.localizedDescription)"
            print("ClientDetailVM: Error deleting plan (APINetworkError): \(error.localizedDescription)")
        } catch {
            self.errorMessage = "An unexpected error occurred while deleting the plan."
            print("ClientDetailVM: Unexpected error deleting plan: \(error.localizedDescription)")
        }
        
        return false // Failure
    }
}
