//
//  FitnessClientApp.swift
//  FitnessClient
//
//  Created by Oleksandr Vorobiov on 06.05.2025.
//

import SwiftUI

@main
struct FitnessClientApp: App {
    
    // Create an instance of AuthService that will persist
    @StateObject private var authService = AuthService()
    // Create APIService, injecting AuthService
    @StateObject private var apiService: APIService
    @StateObject private var toastManager = ToastManager()
    @StateObject private var appModeManager = AppModeManager()
    @StateObject private var themeManager: AppThemeManager
    
    // Offline capabilities
    @StateObject private var coreDataManager = CoreDataManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var syncManager = SyncManager.shared

    init() {
        // Initialize authService first as apiService depends on it
        let auth = AuthService()
        _authService = StateObject(wrappedValue: auth) // Assign to the @StateObject property wrapper
        _apiService = StateObject(wrappedValue: APIService(authService: auth))
        
        // Initialize theme manager with app mode manager
        let modeManager = AppModeManager()
        _appModeManager = StateObject(wrappedValue: modeManager)
        _themeManager = StateObject(wrappedValue: AppThemeManager(appModeManager: modeManager))
    }
    
    var body: some Scene {
        WindowGroup {
            // Content decision logic will go here
            RootView() // We will create RootView next
                .environmentObject(authService) // Make authService available to RootView and its children
                .environmentObject(apiService) // Make apiService available
                .environmentObject(toastManager)
                .environmentObject(appModeManager)
                .environmentObject(themeManager)
                .environmentObject(coreDataManager)
                .environmentObject(networkMonitor)
                .environmentObject(syncManager)
                .environment(\.appTheme, themeManager.currentTheme)
                .environment(\.managedObjectContext, coreDataManager.context)
                .toastView(toast: $toastManager.currentToast) // <<< APPLY MODIFIER
                .onAppear {
                    // Start initial sync if connected
                    if networkMonitor.isConnected {
                        Task {
                            await syncManager.syncAll()
                        }
                    }
                }
        }
    }
}
