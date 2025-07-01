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
    
    // ViewModel for this view's logic
    @ObservedObject var viewModel: SettingsViewModel

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
//                    if user.hasRole(.client) && user.hasRole(.trainer) {
//                        Section("View Mode") {
//                            Picker("Current Mode", selection: $appModeManager.currentMode) {
//                                Text("Client View").tag(AppMode.client)
//                                Text("Trainer View").tag(AppMode.trainer)
//                            }
//                            .pickerStyle(.segmented)
//                        }
//                    }
                    Section("Profile Role") {
                        if let user = authService.loggedInUser, user.roles.contains("trainer") && user.roles.contains("client") {
                            ModeSwitcherView() // New helper view for the switcher
                        } else if let user = authService.loggedInUser, !user.roles.contains("trainer") {
                            if viewModel.isLoading {
                                ProgressView("Activating Trainer Profile...")
                            } else {
                                Button("Become a Trainer") {
                                    Task {
                                        await viewModel.activateTrainerRole()
                                        // If successful, authService.loggedInUser will update,
                                        // and this button will disappear. Show a toast.
                                        if viewModel.errorMessage == nil {
                                            toastManager.showToast(style: .success, message: "Trainer profile activated!")
                                        } else {
                                            toastManager.showToast(style: .error, message: viewModel.errorMessage!)
                                        }
                                    }
                                }
                            }
                        } else if let user = authService.loggedInUser, user.roles.contains("trainer") {
                            Text("Trainer Profile is Active")
                                .foregroundColor(.secondary)
                        }

                        // TODO: UI for switching between modes if user has both roles
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

// New helper view for the mode switcher
struct ModeSwitcherView: View {
    @EnvironmentObject var appModeManager: AppModeManager
    
    var body: some View {
        Picker("Current Mode", selection: $appModeManager.currentMode) {
            Text("Client View").tag(AppMode.client)
            Text("Trainer View").tag(AppMode.trainer)
        }
        .pickerStyle(.segmented)
    }
}

// Preview Provider for SettingsView
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuth = AuthService() // Simplified for preview
        let mockAPI = APIService(authService: mockAuth)
        let mockAppMode = AppModeManager()
        let mockToast = ToastManager()
        
        let vm = SettingsViewModel(apiService: mockAPI, authService: mockAuth, appModeManager: mockAppMode)
        
        SettingsView(viewModel: vm)
            .environmentObject(mockAuth)
            .environmentObject(mockAPI)
            .environmentObject(mockAppMode)
            .environmentObject(mockToast)
    }
}
