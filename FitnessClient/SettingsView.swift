// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    // Access AuthService to call the logout function
    // and to display user information if desired.
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appModeManager: AppModeManager
    @EnvironmentObject var apiService: APIService
    @EnvironmentObject var toastManager: ToastManager
    
    // State for showing a confirmation alert before logging out (optional but good UX)
    @State private var showingLogoutAlert = false
    @State private var isActivatingTrainerRole = false

    var body: some View {
        NavigationView {
            if let user = authService.loggedInUser {
                List {
                    Section(header: Text("Account")) {
                        HStack {
                            Text("Logged in as:")
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            // Display all roles
                            Text("Role(s):")
                            Spacer()
                            Text(user.roles.map { $0.capitalized }.joined(separator: ", "))
                                .foregroundColor(.secondary)
                        }
                    }

                    // --- MODE SWITCHER (if user is both client and trainer) ---
                    if user.hasRole(.client) && user.hasRole(.trainer) {
                        Section("View Mode") {
                            Picker("Current Mode", selection: $appModeManager.currentMode) {
                                Text("Client View").tag(AppModeManager.AppMode.client)
                                Text("Trainer View").tag(AppModeManager.AppMode.trainer)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    
                    // --- ACTIVATE TRAINER ROLE (if user is only a client) ---
                    if user.hasRole(.client) && !user.hasRole(.trainer) {
                        Section("Become a Trainer") {
                            if isActivatingTrainerRole {
                                ProgressView("Activating...")
                            } else {
                                Button("Activate Trainer Profile") {
                                    Task {
                                        await activateTrainerRole()
                                    }
                                }
                            }
                            Text("Activate the trainer dashboard to start managing your own clients.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // --- LOGOUT SECTION ---
                    Section {
                        Button("Logout") {
                            showingLogoutAlert = true
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .navigationTitle("Settings")
                .alert("Confirm Logout", isPresented: $showingLogoutAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Logout", role: .destructive) { Task { await authService.logout() } }
                } message: { Text("Are you sure you want to log out?") }
            } else {
                Text("Loading user details...") // Fallback if user object isn't loaded
                    .navigationTitle("Settings")
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func activateTrainerRole() async {
        print("SettingsView: Attempting to activate trainer role...")
        isActivatingTrainerRole = true
        
        do {
            // APIService needs a POST method that doesn't expect a decodable response, or returns UserResponse
            // Let's add one that returns UserResponse
            let loginResponse: LoginResponse = try await apiService.POST(endpoint: "/users/me/activate-trainer-role", body: EmptyEncodable())
            
            // Refresh the local user object in AuthService
            //authService.loggedInUser = updatedUser
            
            // Tell AuthService to update everything with the new token and user data
            authService.processSuccessfulLogin(token: loginResponse.token, user: loginResponse.user)
            
            toastManager.showToast(style: .success, message: "Trainer mode activated!")
            
            // Automatically switch to trainer mode
            appModeManager.switchTo(mode: .trainer)

        } catch let error as APINetworkError {
            toastManager.showToast(style: .error, message: error.localizedDescription)
        } catch {
            toastManager.showToast(style: .error, message: "An unexpected error occurred: \(error.localizedDescription)")
        }
        isActivatingTrainerRole = false
    }
}

// A helper struct for sending empty POST request bodies
struct EmptyEncodable: Encodable {}

// ... Preview Provider (needs to provide AppModeManager)
struct SettingsView_Previews: PreviewProvider {
    static func createPreview(roles: [String]) -> some View {
        let mockAuth = AuthService()
        mockAuth.authToken = "fake_token"
        mockAuth.loggedInUser = UserResponse(id: "user123", name: "Preview User", email: "preview@example.com", roles: roles, createdAt: Date(), clientIds: nil, trainerId: nil)
        let mockAPI = APIService(authService: mockAuth)
        let mockModeManager = AppModeManager()

        return SettingsView()
            .environmentObject(mockAuth)
            .environmentObject(mockAPI)
            .environmentObject(mockModeManager)
    }

    static var previews: some View {
        Group {
            createPreview(roles: ["client"]).previewDisplayName("As Client Only")
            createPreview(roles: ["client", "trainer"]).previewDisplayName("As Dual Role")
        }
    }
}
