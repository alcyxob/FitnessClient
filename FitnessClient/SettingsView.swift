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
                    
                    // --- SECURITY SETTINGS ---
                    Section(header: Text("Security")) {
                        NavigationLink(destination: BiometricSettingsView()) {
                            HStack {
                                Image(systemName: "shield.lefthalf.filled")
                                    .foregroundColor(.blue)
                                Text("Biometric Authentication")
                                Spacer()
                                if authService.biometricAuthEnabled {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
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
                    Section("App Role") {
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
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    
    var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "person.2.badge.gearshape")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.primary)
                    
                    Text("App Role")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                    
                    Spacer()
                    
                    // Subtle theme color indicator
                    HStack(spacing: 3) {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(theme.secondary)
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 8, height: 8)
                    }
                }
                
                // Role switcher buttons
                HStack(spacing: 8) {
                    ForEach(AppMode.allCases, id: \.self) { mode in
                        Button(action: {
                            if appModeManager.currentMode != mode {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    appModeManager.switchTo(mode: mode)
                                }
                                
                                // Show confirmation toast
                                let message = "Switched to \(mode.displayName) role"
                                toastManager.showToast(style: .success, message: message)
                                
                                // Add haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mode.displayName)
                                        .font(.system(size: 15, weight: .semibold))
                                    
                                    Text(mode.description)
                                        .font(.system(size: 11, weight: .medium))
                                        .opacity(0.8)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .foregroundColor(
                                appModeManager.currentMode == mode ? 
                                theme.onPrimary : theme.primaryText
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(
                                appModeManager.currentMode == mode ? 
                                theme.primary : theme.surface
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        appModeManager.currentMode == mode ? 
                                        Color.clear : theme.primary.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                            .cornerRadius(10)
                        }
                        .disabled(appModeManager.currentMode == mode)
                    }
                }
                
                // Simple persistence note
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(theme.success)
                    
                    Text("Your selection is automatically saved")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
            }
        }
        .padding(.horizontal, 16)
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
