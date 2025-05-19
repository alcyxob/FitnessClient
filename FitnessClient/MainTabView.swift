// MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var apiService: APIService

    var body: some View {
        TabView {
            // --- Tab 1: Home/Dashboard ---
            VStack { /* ... home tab content ... */ }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            // --- Tab 2: Role-Specific Primary View ---
            if authService.loggedInUser?.role == "trainer" {
                TrainerExerciseListView(viewModel: TrainerExerciseListViewModel(apiService: apiService, authService: authService))
                    .tabItem { Label("My Exercises", systemImage: "figure.run.circle.fill") }
                    .tag(1)
            } else if authService.loggedInUser?.role == "client" {
                // ---> Show ClientPlansView for CLIENTS <---
                ClientPlansView(apiService: apiService) // Pass apiService
                    .tabItem { Label("My Plans", systemImage: "list.star") } // Icon for plans
                    .tag(1) // Can reuse tag if it's an either/or scenario
            }

            // --- Tab 3: Clients (Trainers) OR Other Client Tab ---
            if authService.loggedInUser?.role == "trainer" {
                 TrainerClientsView(viewModel: TrainerClientsViewModel(apiService: apiService))
                 .tabItem { Label("My Clients", systemImage: "person.2.fill") }
                 .tag(2)
             } else if authService.loggedInUser?.role == "client" {
                 // Placeholder for another client tab, e.g., "Progress" or "Profile"
                 Text("Client Progress (Placeholder)")
                     .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
                     .tag(2)
             }

             // No specific 4th tab for client yet, or can be combined

            SettingsView() // <<< REPLACE Placeholder Text HERE
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(3) 
        }
    }
}

// Preview Provider for MainTabView
struct MainTabView_Previews: PreviewProvider {

    // Helper Wrapper View for MainTabView Previews (remains the same)
    struct PreviewWrapper: View {
        let authService: AuthService
        let apiService: APIService

        var body: some View {
            MainTabView()
                .environmentObject(authService)
                .environmentObject(apiService)
        }
    }

    // Helper function to create a configured "Trainer" preview instance
    static func trainerPreview() -> some View {
        let mockAuthTrainer = AuthService()
        mockAuthTrainer.authToken = "trainer_token_preview"
        mockAuthTrainer.loggedInUser = UserResponse(
            id: "t_prev_main",
            name: "Trainer Preview Main",
            email: "t_main@p.com",
            role: "trainer",
            createdAt: Date(),
            clientIds: nil,
            trainerId: nil
        )
        let mockApiTrainer = APIService(authService: mockAuthTrainer)
        
        return PreviewWrapper(authService: mockAuthTrainer, apiService: mockApiTrainer)
    }

    // Helper function to create a configured "Client" preview instance
    static func clientPreview() -> some View {
        let mockAuthClient = AuthService()
        mockAuthClient.authToken = "client_token_preview"
        mockAuthClient.loggedInUser = UserResponse(
            id: "c_prev_main",
            name: "Client Preview Main",
            email: "c_main@p.com",
            role: "client",
            createdAt: Date(),
            clientIds: nil,
            trainerId: "t_prev_main"
        )
        let mockApiClient = APIService(authService: mockAuthClient)

        return PreviewWrapper(authService: mockAuthClient, apiService: mockApiClient)
    }

    static var previews: some View {
        Group {
            trainerPreview() // Call the helper function
                .previewDisplayName("As Trainer")

            clientPreview() // Call the helper function
                .previewDisplayName("As Client")
        }
        // No .environmentObject needed on the Group here,
        // as PreviewWrapper handles it internally for each case.
    }
}
