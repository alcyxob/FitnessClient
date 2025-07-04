// TrainerClientsViewModel.swift
import Foundation
import SwiftUI

@MainActor
class TrainerClientsViewModel: ListViewModel<UserResponse> {
    @Published var greeting: String = ""
    
    let apiService: APIService // Made public for access
    
    init(apiService: APIService) {
        self.apiService = apiService
        super.init()
    }
    
    func fetchManagedClients() async {
        await safeExecute(
            operationId: "fetch_clients",
            loadingMessage: "Loading clients...",
            context: "Fetching managed clients"
        ) { [weak self] in
            guard let self = self else { return }
            let fetchedClients: [UserResponse] = try await self.apiService.GET(endpoint: "/trainer/clients")
            self.updateItems(fetchedClients)
            
            print("ViewModel: Successfully fetched \(fetchedClients.count) clients.")
        }
    }
    
    func refreshClients() async {
        await fetchManagedClients()
    }
    
    override func retry() {
        Task {
            await fetchManagedClients()
        }
    }
}
