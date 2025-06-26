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

    init() {
        // Initialize authService first as apiService depends on it
        let auth = AuthService()
        _authService = StateObject(wrappedValue: auth) // Assign to the @StateObject property wrapper
        _apiService = StateObject(wrappedValue: APIService(authService: auth))
    }
    
    var body: some Scene {
        WindowGroup {
            // Content decision logic will go here
            RootView() // We will create RootView next
                .environmentObject(authService) // Make authService available to RootView and its children
                .environmentObject(apiService) // Make apiService available
                .environmentObject(toastManager)
                .environmentObject(appModeManager)
                .toastView(toast: $toastManager.currentToast) // <<< APPLY MODIFIER
        }
    }
}
