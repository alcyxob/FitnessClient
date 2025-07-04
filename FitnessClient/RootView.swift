// RootView.swift
import SwiftUI

struct RootView: View {
    // Access the AuthService instance passed from the App struct
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var appModeManager: AppModeManager

    var body: some View {
        let _ = print("RootView body re-evaluated: authToken is \(authService.authToken == nil ? "nil" : "SET"), loggedInUser is \(authService.loggedInUser == nil ? "nil" : "SET (\(authService.loggedInUser?.email ?? "unknown"))")")
        
        // Conditional view rendering based on authentication state
        if authService.authToken != nil && authService.loggedInUser != nil {
            let _ = print("RootView: Showing MainTabView")
            // User is authenticated, show the main app content
            MainTabView()
        } else {
            let _ = print("RootView: Showing PolishedAuthenticationView")
            // User is not authenticated, show the polished authentication screen
            PolishedAuthenticationView(authService: authService)
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        // For previewing, create mock services
        let authService = AuthService()
        let apiService = APIService(authService: authService)
        let appModeManager = AppModeManager()
        
        RootView()
            .environmentObject(authService)
            .environmentObject(apiService)
            .environmentObject(appModeManager)
            .environmentObject(ToastManager())
            .environmentObject(AppThemeManager(appModeManager: appModeManager))
            .environment(\.appTheme, AppTheme.client)
    }
}
