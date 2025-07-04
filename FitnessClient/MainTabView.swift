// MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var appModeManager: AppModeManager
    @EnvironmentObject var themeManager: AppThemeManager
    @Environment(\.appTheme) var theme

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
        .accentColor(theme.primary)
        .background(theme.background)
        .onAppear {
            // Configure tab bar appearance based on theme
            configureTabBarAppearance()
        }
        .onChange(of: themeManager.currentTheme) { _ in
            // Update tab bar when theme changes
            configureTabBarAppearance()
        }
    }

    // Helper for Client-specific tabs
    @ViewBuilder
    private var clientTabs: some View {
        PolishedClientDashboardView(apiService: apiService, authService: authService)
            .tabItem { 
                Label("Today", systemImage: "figure.mixed.cardio")
            }
            .tag(0)

        PolishedClientPlansView(apiService: apiService)
            .tabItem { 
                Label("My Plans", systemImage: "list.star") 
            }
            .tag(1)
        
        Text("Client Progress (Placeholder)")
            .tabItem { 
                Label("Progress", systemImage: "chart.bar.xaxis") 
            }
            .tag(2)

        PolishedSettingsView(viewModel: SettingsViewModel(apiService: apiService, authService: authService, appModeManager: appModeManager))
            .tabItem { 
                Label("Settings", systemImage: "gearshape.fill") 
            }
            .tag(3)
    }

    // Helper for Trainer-specific tabs
    @ViewBuilder
    private var trainerTabs: some View {
        PolishedTrainerDashboardView(apiService: apiService, authService: authService)
            .tabItem { 
                Label("Dashboard", systemImage: "chart.bar.doc.horizontal") 
            }
            .tag(0)

        PolishedTrainerExerciseListView(viewModel: TrainerExerciseListViewModel(apiService: apiService, authService: authService))
            .tabItem { 
                Label("Exercises", systemImage: "figure.strengthtraining.traditional") 
            }
            .tag(1)

        PolishedTrainerClientsView(viewModel: TrainerClientsViewModel(apiService: apiService))
            .tabItem { 
                Label("Clients", systemImage: "person.2.fill") 
            }
            .tag(2)
        
        PolishedSettingsView(viewModel: SettingsViewModel(apiService: apiService, authService: authService, appModeManager: appModeManager))
            .tabItem { 
                Label("Settings", systemImage: "gearshape.fill") 
            }
            .tag(3)
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Set background color
        appearance.backgroundColor = UIColor(theme.tabBarBackground)
        
        // Set selected item color
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(theme.tabBarSelected)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(theme.tabBarSelected)
        ]
        
        // Set unselected item color
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(theme.tabBarUnselected)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(theme.tabBarUnselected)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
