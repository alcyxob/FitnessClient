// MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var appModeManager: AppModeManager

    var body: some View {
        // Use a Group to avoid re-initializing TabView when mode changes, which can reset tab selection
        Group {
            if let user = authService.loggedInUser {
                if user.hasRole(.trainer) && appModeManager.currentMode == .trainer {
                    // --- TRAINER VIEW ---
                    TabView {
                        TrainerDashboardView(apiService: apiService, authService: authService)
                            .tabItem { Label("Dashboard", systemImage: "list.clipboard.fill") }
                            .tag(0)

                        TrainerExerciseListView(viewModel: TrainerExerciseListViewModel(apiService: apiService, authService: authService))
                            .tabItem { Label("My Exercises", systemImage: "figure.run.circle.fill") }
                            .tag(1)

                        TrainerClientsView(viewModel: TrainerClientsViewModel(apiService: apiService))
                            .tabItem { Label("My Clients", systemImage: "person.2.fill") }
                            .tag(2)
                        
                        SettingsView()
                            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                            .tag(3)
                    }
                } else {
                    // --- CLIENT VIEW ---
                    // This is shown if user is only a client,
                    // OR if they have both roles but currentMode is .client
                    TabView {
                        ClientDashboardView(apiService: apiService, authService: authService)
                            .tabItem { Label("Today", systemImage: "figure.mixed.cardio") }
                            .tag(0)
                        
                        ClientPlansView(apiService: apiService)
                            .tabItem { Label("My Plans", systemImage: "list.star") }
                            .tag(1)
                        
                        Text("Client Progress (Placeholder)")
                            .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
                            .tag(2)
                        
                        SettingsView()
                            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                            .tag(3)
                    }
                }
            } else {
                // Fallback if user is somehow nil (RootView should prevent this)
                ProgressView()
            }
        } // End Group
        // Optional: Animate the switch between TabViews
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
        .animation(.easeInOut, value: appModeManager.currentMode)
    }
}

// Preview Provider for MainTabView
struct MainTabView_Previews: PreviewProvider {

    // Helper Wrapper View for setting up each preview's environment
    struct PreviewWrapper: View {
        // We create the services outside and pass them in to configure them
        // for different states (e.g., trainer vs. client)
        @StateObject var authService: AuthService
        @StateObject var apiService: APIService
        @StateObject var appModeManager: AppModeManager
        @StateObject var toastManager: ToastManager

        init(authService: AuthService, appModeManager: AppModeManager) {
            let auth = authService
            _authService = StateObject(wrappedValue: auth)
            _apiService = StateObject(wrappedValue: APIService(authService: auth)) // Depends on auth
            _appModeManager = StateObject(wrappedValue: appModeManager)
            _toastManager = StateObject(wrappedValue: ToastManager())
        }

        var body: some View {
            MainTabView()
                .environmentObject(authService)
                .environmentObject(apiService)
                .environmentObject(appModeManager)
                .environmentObject(toastManager)
                // Add the toastView modifier here so previews can see toasts
                .toastView(toast: .constant(nil)) // Provide a dummy binding for preview
        }
    }

    static var previews: some View {
        // --- Setup for "As Trainer" Preview ---
        let trainerAuthService: AuthService = {
            let auth = AuthService() // Assuming a simplified/mock init is possible for previews
            auth.authToken = "trainer_token_preview"
            auth.loggedInUser = UserResponse(
                id: "t_main_prev",
                name: "Trainer Preview",
                email: "trainer@main.com",
                roles: ["trainer", "client"], // <<< Trainer with both roles
                createdAt: Date(),
                clientIds: nil,
                trainerId: nil
            )
            return auth
        }()
        
        let trainerModeManager: AppModeManager = {
            let mode = AppModeManager()
            mode.currentMode = .trainer // Start in trainer mode
            return mode
        }()


        // --- Setup for "As Client" Preview ---
        let clientAuthService: AuthService = {
            let auth = AuthService()
            auth.authToken = "client_token_preview"
            auth.loggedInUser = UserResponse(
                id: "c_main_prev",
                name: "Client Preview",
                email: "client@main.com",
                roles: ["client"], // <<< Client with only client role
                createdAt: Date(),
                clientIds: nil,
                trainerId: "t_main_prev"
            )
            return auth
        }()
        
        let clientModeManager = AppModeManager() // Defaults to .client mode

        // --- Use Group to show multiple previews ---
        Group {
            // Preview for a user with both roles, currently in Trainer Mode
            PreviewWrapper(authService: trainerAuthService, appModeManager: trainerModeManager)
                .previewDisplayName("As Trainer (Dual Role)")

            // Preview for a user with only the client role
            PreviewWrapper(authService: clientAuthService, appModeManager: clientModeManager)
                .previewDisplayName("As Client Only")
        }
    }
}
