// MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var apiService: APIService // Get APIService from environment

    var body: some View {
        TabView {
            // --- Tab 1: Home/Dashboard ---
            VStack {
                Text("Welcome to the App!")
                    .font(.largeTitle)
                    .padding()

                if let user = authService.loggedInUser {
                    Text("Logged in as: \(user.email)")
                    Text("Role: \(user.role)")
                } else {
                    Text("User details not available.")
                }

                Button("Logout") {
                    Task {
                        await authService.logout()
                    }
                }
                .padding()
                .buttonStyle(.borderedProminent)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            // --- Tab 2: Exercises (Visible only to Trainers) ---
            if authService.loggedInUser?.role == "trainer" {
                // Create the ViewModel instance here and pass it to the view
                TrainerExerciseListView(
                    viewModel: TrainerExerciseListViewModel(apiService: apiService, authService: authService)
                )
                .tabItem {
                    Label("My Exercises", systemImage: "figure.run.circle.fill")
                }
                .tag(1)
            } else if authService.loggedInUser?.role == "client" {
                // --- Placeholder for Client's "My Assignments" Tab ---
                Text("Client Assignments Tab (Placeholder)")
                    .tabItem {
                        Label("My Workouts", systemImage: "list.bullet.clipboard.fill")
                    }
                    .tag(1) // Use same tag if it's replacing the trainer tab
            }
            
            //Tab 3: Clients (Visible only to Trainers) ---
            if authService.loggedInUser?.role == "trainer" {
                 TrainerClientsView(
                     viewModel: TrainerClientsViewModel(apiService: apiService)
                 )
                 .tabItem {
                     Label("My Clients", systemImage: "person.2.fill")
                 }
                 .tag(2) // Assign a unique tag
             }

            // Tab 4: Assign (Trainers) ---
            if authService.loggedInUser?.role == "trainer" {
                AssignExerciseView(apiService: apiService, authService: authService)
                 .tabItem {
                     Label("Assign", systemImage: "figure.mixed.cardio") // Or other suitable icon
                 }
                 .tag(3) // Adjust tag number
             }

            // --- Tab 5: Settings ---
            Text("Settings Tab (Placeholder)")
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
    }
}

// Preview provider for MainTabView remains the same, but now needs APIService too
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuthService = AuthService()
        let mockAPIService = APIService(authService: mockAuthService)
        // Simulate logged in user for preview:
        // mockAuthService.authToken = "preview_token"
        // mockAuthService.loggedInUser = UserResponse(id: "previewUser", name: "Preview User", email: "preview@example.com", role: "trainer", createdAt: Date(), clientIds: nil, trainerId: nil)

        MainTabView()
            .environmentObject(mockAuthService)
            .environmentObject(mockAPIService)
    }
}
