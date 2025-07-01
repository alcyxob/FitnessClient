// MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var appModeManager: AppModeManager // Get from environment

    var body: some View {
        TabView {
            // Determine which set of tabs to show
            if let user = authService.loggedInUser {
                // Show client tabs if user only has client role OR is in client mode
                if !user.roles.contains("trainer") || appModeManager.currentMode == .client {
                    clientTabs
                }
                // Show trainer tabs if user has trainer role AND is in trainer mode
                else if user.roles.contains("trainer") && appModeManager.currentMode == .trainer {
                    trainerTabs
                }
            } else {
                // Fallback for when loggedInUser is briefly nil (shouldn't happen often)
                Text("Loading...")
            }
        }
    }

    // Helper for Client-specific tabs
    @ViewBuilder
    private var clientTabs: some View {
        ClientDashboardView(apiService: apiService, authService: authService)
            .tabItem { Label("Today", systemImage: "figure.mixed.cardio") }
            .tag(0)

        ClientPlansView(apiService: apiService)
            .tabItem { Label("My Plans", systemImage: "list.star") }
            .tag(1)
        
        Text("Client Progress (Placeholder)")
            .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
            .tag(2)

        SettingsView(viewModel: SettingsViewModel(apiService: apiService, authService: authService, appModeManager: appModeManager)) // Pass appModeManager
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(3)
    }

    // Helper for Trainer-specific tabs
    @ViewBuilder
    private var trainerTabs: some View {
        TrainerDashboardView(apiService: apiService, authService: authService)
            .tabItem { Label("Dashboard", systemImage: "list.clipboard.fill") }
            .tag(0)

        TrainerExerciseListView(viewModel: TrainerExerciseListViewModel(apiService: apiService, authService: authService))
            .tabItem { Label("My Exercises", systemImage: "figure.run.circle.fill") }
            .tag(1)

        TrainerClientsView(viewModel: TrainerClientsViewModel(apiService: apiService))
            .tabItem { Label("My Clients", systemImage: "person.2.fill") }
            .tag(2)
        
        SettingsView(viewModel: SettingsViewModel(apiService: apiService, authService: authService, appModeManager: appModeManager)) // Pass appModeManager
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(3)
    }
}
