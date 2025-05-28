// RoleSelectionView.swift
import SwiftUI
import AuthenticationServices // For ASAuthorizationAppleIDCredential

struct RoleSelectionView: View {
    // Data received from Apple Sign-In
    let appleAuthCredential: ASAuthorizationAppleIDCredential?
    let appleAuthFullName: PersonNameComponents?
    
    // Shared AuthService to call the backend
    @ObservedObject var authService: AuthService // Use @ObservedObject if passed, or @EnvironmentObject

    @State private var selectedRole: domain.Role = .client // Default to client
    @Environment(\.dismiss) var dismiss

    // Assuming domain.Role is defined in Models.swift or globally
    // enum domain { enum Role: String, CaseIterable, Identifiable { case trainer, client; var id: String { rawValue } }}

    var body: some View {
        NavigationView { // For title and cancel button
            VStack(spacing: 30) {
                Text("One Last Step!")
                    .font(.largeTitle).fontWeight(.bold)
                
                if let name = appleAuthFullName, let givenName = name.givenName, !givenName.isEmpty {
                    Text("Welcome, \(givenName)!")
                        .font(.title2)
                } else if let email = appleAuthCredential?.email {
                     Text("Welcome, \(email)!")
                        .font(.title2)
                }

                Text("Please select your role in the app:")
                    .font(.headline)

                Picker("Select Role", selection: $selectedRole) {
                    ForEach(domain.Role.allCases, id: \.self) { role in
                        Text(role.rawValue.capitalized).tag(role)
                    }
                }
                .pickerStyle(.segmented) // Or .wheel, or custom buttons
                .padding(.horizontal)

                if authService.isLoading {
                    ProgressView("Finalizing Sign Up...")
                } else {
                    Button("Continue as \(selectedRole.rawValue.capitalized)") {
                        Task {
                            await completeAppleSignUp()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                if let errorMessage = authService.errorMessage {
                     Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Select Your Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // When cancelling role selection, we effectively cancel the Apple Sign-In flow
                        // AuthService state should be reset by LoginView's onDismiss of this sheet.
                        dismiss()
                    }
                }
            }
        }
    }

    func completeAppleSignUp() async {
        guard let credential = appleAuthCredential else {
            authService.errorMessage = "Apple authentication data missing."
            return
        }
        guard let identityTokenData = credential.identityToken,
              let identityTokenString = String(data: identityTokenData, encoding: .utf8) else {
            authService.errorMessage = "Could not get identity token from Apple."
            return
        }

        let firstName = appleAuthFullName?.givenName ?? ""
        let lastName = appleAuthFullName?.familyName ?? ""

        print("RoleSelectionView: Calling backend to finalize Apple Sign-In. Role: \(selectedRole.rawValue)")
        // Call the specific method in AuthService that communicates with your backend
        // This method should now use the new signature taking first/last name and role.
        // AuthService will handle setting its own @Published properties (authToken, loggedInUser).
        
        // This assumes authService has a method that takes these and calls the backend
        // and then internally calls the Go backend's /auth/apple/callback
        await authService.finalizeAppleSignIn(
            identityToken: identityTokenString,
            firstName: firstName,
            lastName: lastName,
            selectedRole: selectedRole
        )

        // If authService.authToken is set, LoginView's .onChange will trigger RootView change.
        // If there was an error, authService.errorMessage will be set and displayed.
        if authService.authToken == nil && authService.errorMessage == nil {
            // This case means backend call completed but didn't result in login or an error message we caught.
            // This shouldn't happen if finalizeAppleSignIn properly sets errorMessage on failure.
            authService.errorMessage = "An unknown issue occurred during sign-up."
        }
        
        // If login successful (authToken is set), dismiss this sheet.
        // LoginView's .onChange(of: authService.authToken) will handle overall app state.
        if authService.authToken != nil {
            dismiss()
        }
    }
}

// Preview Provider for RoleSelectionView
struct RoleSelectionView_Previews: PreviewProvider {

    // Helper static function to create a configured preview instance
    static func createPreviewInstance() -> some View {
        // 1. Create mock AuthService
        let mockAuthService = AuthService()
        // Optionally, set states on mockAuthService if RoleSelectionView's UI reacts to them
        // e.g., mockAuthService.isLoading = true or mockAuthService.errorMessage = "Preview Error"

        // 2. Create dummy PersonNameComponents for display
        var previewNameComponents = PersonNameComponents()
        previewNameComponents.givenName = "Jane"
        previewNameComponents.familyName = "Doe"
        
        // 3. ASAuthorizationAppleIDCredential is very hard to mock directly for previews
        // because it's a protocol and its concrete types are internal.
        // For previewing RoleSelectionView, passing `nil` for appleAuthCredential
        // is often sufficient, as the view should gracefully handle it (e.g., by not
        // trying to access its properties if it's nil, or by using the email from it
        // only if present). The core UI (Picker, Continue button) can still be tested.
        // If you absolutely needed to simulate a non-nil credential, you'd have to
        // create a mock class that conforms to ASAuthorizationAppleIDCredential.

        // 4. Return the configured RoleSelectionView
        return RoleSelectionView(
            appleAuthCredential: nil, // Pass nil for preview simplicity
            appleAuthFullName: previewNameComponents,
            authService: mockAuthService // Pass the mock service
        )
        // Provide environment objects if RoleSelectionView or any view it might
        // present directly uses @EnvironmentObject for these (though it takes authService via init).
        // .environmentObject(APIService(authService: mockAuthService)) // If needed by a sub-view
        .environmentObject(mockAuthService) // Already passed via init, but good for sub-views
    }

    static var previews: some View {
        // Call the helper function
        createPreviewInstance()
            .previewDisplayName("Default State")

        // Example of another state using a modified ViewModel for preview:
        // static func createLoadingPreviewInstance() -> some View {
        //     let mockAuth = AuthService()
        //     mockAuth.isLoading = true // Simulate loading state
        //     var name = PersonNameComponents(); name.givenName = "Loading"
        //     return RoleSelectionView(appleAuthCredential: nil, appleAuthFullName: name, authService: mockAuth)
        //         .environmentObject(mockAuth)
        // }
        //
        // Group {
        //     createPreviewInstance().previewDisplayName("Default")
        //     createLoadingPreviewInstance().previewDisplayName("Loading")
        // }
    }
}
