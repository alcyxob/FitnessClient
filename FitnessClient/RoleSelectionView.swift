// RoleSelectionView.swift
import SwiftUI
import AuthenticationServices

struct RoleSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService

    // Data passed from LoginView
    let appleAuthFullName: PersonNameComponents?
    let appleIdentityTokenForBackend: String
    let appleUserIDFromApple: String

    @State private var selectedRole: domain.Role = .client // Default to client
    @State private var isProcessing = false

    // Initializer to receive data from LoginView
    init(appleAuthFullName: PersonNameComponents?,
         appleIdentityTokenForBackend: String,
         appleUserIDFromApple: String) {
        self.appleAuthFullName = appleAuthFullName
        self.appleIdentityTokenForBackend = appleIdentityTokenForBackend
        self.appleUserIDFromApple = appleUserIDFromApple
        print("RoleSelectionView: Initialized. For Apple User ID: \(appleUserIDFromApple)")
    }

    var body: some View {
        let _ = print("RoleSelectionView BODY re-evaluating. isProcessing: \(isProcessing), selectedRole: \(selectedRole.rawValue)")
        
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 70))
                    .foregroundColor(.accentColor)
                
                Text("One Last Step!")
                    .font(.largeTitle).fontWeight(.bold)
                
                Text("To get you set up correctly, please select your primary role for the app.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // --- THE PICKER ---
                Picker("Select Role", selection: $selectedRole) {
                    // This ForEach depends on domain.Role being CaseIterable
                    ForEach(domain.Role.allCases) { role in
                        Text(role.rawValue.capitalized).tag(role)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // --- THE CONFIRM BUTTON ---
                if isProcessing {
                    ProgressView("Finalizing Registration...")
                } else {
                    Button {
                        Task { await finalizeRegistration() }
                    } label: {
                        Text("Confirm Role & Continue")
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isProcessing)
                }

                // --- ERROR DISPLAY ---
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                }

                Spacer()
                Spacer()
            }
            .padding()
            .navigationTitle("Select Your Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        authService.errorMessage = nil
                        dismiss()
                    }
                }
            }
        }
    }

    private func finalizeRegistration() async {
        isProcessing = true
        authService.errorMessage = nil // Clear previous errors

        // Call the AuthService method that handles the final backend communication
        await authService.handleAppleSignIn(
            identityToken: appleIdentityTokenForBackend,
            firstName: appleAuthFullName?.givenName,
            lastName: appleAuthFullName?.familyName,
            selectedRole: selectedRole // Pass the role chosen by the user
        )
        
        isProcessing = false
        // If authService.authToken is now set, LoginView's .onChange will detect it.
        // We can also explicitly dismiss here on success.
        if authService.authToken != nil {
            dismiss()
        }
    }
}

// Preview Provider for RoleSelectionView
struct RoleSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let authService = AuthService() // This needs a mock repo for its init
        // For preview, authService would need to be initialized correctly.
        // Assuming a simplified init for preview is possible.
        
        let sampleName = PersonNameComponents(givenName: "Jane", familyName: "Doe")
        
        RoleSelectionView(
            appleAuthFullName: sampleName,
            appleIdentityTokenForBackend: "fake_preview_token",
            appleUserIDFromApple: "fake_apple_user_id"
        )
        .environmentObject(authService)
    }
}
