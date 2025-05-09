// RootView.swift
import SwiftUI

struct RootView: View {
    // Access the AuthService instance passed from the App struct
    @EnvironmentObject var authService: AuthService

    var body: some View {
        let _ = print("RootView body re-evaluated: authToken is \(authService.authToken == nil ? "nil" : "SET"), loggedInUser is \(authService.loggedInUser == nil ? "nil" : "SET (\(authService.loggedInUser!.email))")")
        // Conditional view rendering based on authentication state
        if authService.authToken != nil && authService.loggedInUser != nil {
            let _ = print("RootView: Showing MainTabView")
            // User is authenticated, show the main app content
            MainTabView() // We'll create this placeholder next
        } else {
            let _ = print("RootView: Showing LoginView")
            // User is not authenticated, show the login screen
            LoginView()
        }
        // The .environmentObject(authService) is already applied by the App struct,
        // so MainTabView and LoginView will automatically have access if they declare @EnvironmentObject.
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        // For previewing, you can create a mock AuthService or provide a simple one
        RootView()
            .environmentObject(AuthService()) // Provide a dummy for preview
    }
}
