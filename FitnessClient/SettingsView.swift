// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    // Access AuthService to call the logout function
    // and to display user information if desired.
    @EnvironmentObject var authService: AuthService
    
    // State for showing a confirmation alert before logging out (optional but good UX)
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationView { // Each tab content should generally have its own NavigationView
            List {
                Section(header: Text("Account")) {
                    if let user = authService.loggedInUser {
                        HStack {
                            Text("Logged in as:")
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Role:")
                            Spacer()
                            Text(user.role.capitalized)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button("Logout") {
                        // Show confirmation alert before logging out
                        showingLogoutAlert = true
                    }
                    .foregroundColor(.red) // Make the logout button stand out
                }

                // TODO: Add other settings sections later
                // Section(header: Text("App Settings")) {
                //     Text("Notifications (Placeholder)")
                //     Text("Appearance (Placeholder)")
                // }
                //
                // Section(header: Text("About")) {
                //     Text("App Version: 1.0.0")
                //     Text("Privacy Policy")
                //     Text("Terms of Service")
                // }
            }
            .navigationTitle("Settings")
            // Confirmation alert for logout
            .alert("Confirm Logout", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    Task {
                        await authService.logout()
                        // After logout, RootView will automatically switch to LoginView
                    }
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
        .navigationViewStyle(.stack) // Consistent navigation style
    }
}

struct SettingsView_Previews: PreviewProvider {
    static func createPreviewInstance(isLoggedIn: Bool) -> some View {
        let mockAuth = AuthService()
        if isLoggedIn {
            mockAuth.authToken = "fake_token_for_preview"
            mockAuth.loggedInUser = UserResponse(id: "user123", name: "Preview User", email: "preview@example.com", role: "client", createdAt: Date(), clientIds: nil, trainerId: nil)
        }
        return SettingsView().environmentObject(mockAuth)
    }

    static var previews: some View {
        Group {
            createPreviewInstance(isLoggedIn: true)
                .previewDisplayName("Logged In")
            createPreviewInstance(isLoggedIn: false)
                .previewDisplayName("Logged Out (should not show user info)")
        }
    }
}
