//// RoleSelectionView.swift
//import SwiftUI
//import AuthenticationServices // For ASAuthorizationAppleIDCredential
//
//struct RoleSelectionView: View {
//    @Environment(\.dismiss) var dismiss
//    @EnvironmentObject var authService: AuthService // To call the final backend registration
//
//    // Data passed from LoginView
//    let appleAuthCredential: ASAuthorizationAppleIDCredential?
//    let appleAuthFullName: PersonNameComponents?
//
//    
//    @State private var selectedRole: domain.Role = .client // Default to client
//    @State private var isProcessing = false // To show a loading indicator
//
//    // Assuming domain.Role is defined in Models.swift as an enum
//    // enum domain {
//    //     enum Role: String, CaseIterable, Identifiable {
//    //         case client = "client"
//    //         case trainer = "trainer"
//    //         var id: String { self.rawValue }
//    //     }
//    // }
//
//    var body: some View {
//        NavigationView { // Good for sheets to have their own Nav Bar
//            VStack(spacing: 30) {
//                Spacer()
//                Text("Welcome!")
//                    .font(.largeTitle).fontWeight(.bold)
//                
//                Text("Please select your role in the app:")
//                    .font(.headline)
//                    .multilineTextAlignment(.center)
//
//                Picker("Select Role", selection: $selectedRole) {
//                    ForEach(domain.Role.allCases) { role in // Assuming Role is CaseIterable
//                        Text(role.rawValue.capitalized).tag(role)
//                    }
//                }
//                .pickerStyle(.segmented)
//                .padding(.horizontal)
//
//                if isProcessing {
//                    ProgressView("Finalizing Registration...")
//                } else {
//                    Button("Confirm Role & Continue") {
//                        Task {
//                            await finalizeRegistration()
//                        }
//                    }
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//                    .disabled(isProcessing)
//                }
//                
//                if let errorMessage = authService.errorMessage {
//                    Text(errorMessage)
//                        .foregroundColor(.red)
//                        .font(.caption)
//                        .multilineTextAlignment(.center)
//                        .padding(.top)
//                }
//
//                Spacer()
//                Spacer()
//            }
//            .padding()
//            .navigationTitle("Select Your Role")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        authService.errorMessage = nil // Clear any error message from login attempts
//                        dismiss()
//                    }
//                }
//            }
//        }
//    }
//
//    private func finalizeRegistration() async {
//        guard let credential = appleAuthCredential else {
//            authService.errorMessage = "Apple authentication details are missing."
//            return
//        }
//        guard let identityTokenData = credential.identityToken,
//              let identityTokenString = String(data: identityTokenData, encoding: .utf8) else {
//            authService.errorMessage = "Could not retrieve Apple identity token."
//            return
//        }
//
//        isProcessing = true
//        authService.errorMessage = nil // Clear previous errors
//
//        // Call the AuthService method that handles backend communication for Apple Sign-In
//        await authService.handleAppleSignIn(
//            identityToken: identityTokenString,
//            firstName: appleAuthFullName?.givenName,
//            lastName: appleAuthFullName?.familyName,
//            selectedRole: selectedRole // Pass the role chosen by the user
//        )
//        
//        isProcessing = false
//        // If authService.authToken is now set, LoginView's .onChange will trigger navigation,
//        // and this sheet will be dismissed as part of that view switch.
//        // If there was an error, authService.errorMessage will be set and displayed.
//        // If successful, we might want to dismiss explicitly if RootView doesn't immediately switch.
//        if authService.authToken != nil {
//            dismiss()
//        }
//    }
//}
//
//// Preview Provider for RoleSelectionView
//struct RoleSelectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        // To preview this, you'd need to create a mock ASAuthorizationAppleIDCredential,
//        // which is tricky. For now, a basic preview:
//        let authService = AuthService() // Needs a mock repo for its init
//        // authService.loggedInUser = UserResponse(...) // Not logged in yet for role selection
//
//        // This preview won't have real Apple data, so it's mostly for layout.
//        RoleSelectionView(
//            appleAuthCredential: nil, // Can't easily mock ASAuthorizationAppleIDCredential
//            appleAuthFullName: nil,
//            authService: authService // Pass the authService directly for preview
//        )
//        .environmentObject(authService) // Or ensure it's in environment
//    }
//}
