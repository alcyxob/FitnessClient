import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authService: AuthService // For backend calls & main auth state
    @StateObject private var appleSignInManager = AppleSignInManager() // Handles Apple's native UI

    @State private var email = ""
    @State private var password = ""
    
    // State for Role Selection Sheet
    @State private var showingRoleSelectionSheet = false
    @State private var appleSignInDataForRoleSelection: AppleSignInResult? = nil


    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                Text("Fitness App Login").font(.largeTitle).fontWeight(.bold)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress).textContentType(.emailAddress).autocapitalization(.none)
                    .padding().background(Color(.secondarySystemBackground)).cornerRadius(8)

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding().background(Color(.secondarySystemBackground)).cornerRadius(8)

                // --- Login Button & Loading Indicator ---
                if authService.isLoading {
                    ProgressView("Processing...")
                        .padding(.top)
                } else {
                    Button("Login with Email") {
                        Task { await authService.login(email: email, password: password) }
                    }
                    .padding().frame(maxWidth: .infinity).background(Color.blue).foregroundColor(.white).cornerRadius(8).padding(.top)
                    .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
                }
                
                DividerText()

                // --- Sign in with Apple Button ---
                if authService.isLoading {
                    ProgressView("Processing Apple Sign-In...").padding(.top)
                } else {
                    Button {
                        Task {
                            authService.isLoading = true
                            authService.errorMessage = nil
                            appleSignInManager.appleSignInError = nil
                            do {
                                // 1. Authenticate with Apple locally
                                let appleResult = try await appleSignInManager.startSignInWithAppleFlow()
                                print("LoginView: Native Apple Sign In successful.")
                                
                                // 2. Perform backend pre-check
                                let userExists = try await authService.precheckAppleUser(identityToken: appleResult.identityToken)
                                
                                // 3. Decide flow based on pre-check result
                                if userExists {
                                    // User exists, log them in directly without asking for role.
                                    // Backend will find them by AppleUserID or Email and use their existing role.
                                    print("LoginView: Pre-check shows user exists. Logging in directly.")
                                    await authService.handleAppleSignIn(
                                        identityToken: appleResult.identityToken,
                                        firstName: appleResult.firstName,
                                        lastName: appleResult.lastName,
                                        selectedRole: .client // Role doesn't matter here, but API expects it. Backend will ignore for existing user.
                                    )
                                } else {
                                    // User is new. We MUST ask for their role.
                                    print("LoginView: Pre-check shows new user. Showing role selection sheet.")
                                    // Store data needed by RoleSelectionView and present the sheet
                                    self.appleSignInDataForRoleSelection = appleResult
                                    self.showingRoleSelectionSheet = true
                                    // The loading state should be turned off here because we are waiting for user input.
                                    // RoleSelectionView will set it back on when it calls the backend.
                                    authService.isLoading = false
                                }

                            } catch ASAuthorizationError.canceled {
                                print("LoginView: User canceled Apple Sign In.")
                                authService.errorMessage = nil
                                authService.isLoading = false // Reset loading state
                            } catch {
                                print("LoginView: Apple Sign In or Pre-check failed. Error: \(error.localizedDescription)")
                                authService.errorMessage = "Sign In failed: \(error.localizedDescription)"
                                authService.isLoading = false // Reset loading state
                            }
                        }
                    } label: {
                        // --- CORRECTED APPLE BUTTON APPEARANCE ---
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .font(.title3.weight(.medium))
                            Text("Sign in with Apple")
                                .fontWeight(.medium)
                                .font(.body)
                        }
                        .padding(.horizontal)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .foregroundColor(Color.white)
                        .cornerRadius(8)
                        // --- END CORRECTION ---
                    }
                    .padding(.horizontal)
                }
                // --- END Sign in with Apple Button ---
                
                if authService.isLoading && appleSignInDataForRoleSelection != nil {
                    ProgressView("Finalizing Sign-In with server...")
                        .padding(.top)
                }
                
                // Display general error messages from AuthService
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage).foregroundColor(.red).padding(.top).multilineTextAlignment(.center)
                }
                // Display specific errors from AppleSignInManager if any (e.g., credential fetch error)
                if let appleError = appleSignInManager.appleSignInError {
                     Text("Apple Error: \(appleError.localizedDescription)")
                         .foregroundColor(.red).padding(.top).multilineTextAlignment(.center)
                }

                Spacer(minLength: 50) // More space at bottom
            }
            .padding()
            .navigationBarHidden(true)
            // --- Sheet for Role Selection ---
            .sheet(isPresented: $showingRoleSelectionSheet, onDismiss: {
                // This is called when the RoleSelectionView is dismissed.
                // If login was successful (authToken is set), RootView will handle navigation.
                // If user cancelled role selection, or it failed, clear temp Apple data.
                if authService.authToken == nil { // If backend call from RoleSelectionView didn't result in login
                    print("LoginView: RoleSelectionSheet dismissed, login not completed. Clearing Apple data.")
                    self.appleSignInDataForRoleSelection = nil
                }
            }) {
                // Ensure we have the data before presenting
                if let appleData = appleSignInDataForRoleSelection {
                    RoleSelectionView(
                        //appleAuthCredential: nil, // RoleSelectionView now only needs the token & name, not full credential
                        appleAuthFullName: PersonNameComponents(givenName: appleData.firstName, familyName: appleData.lastName),
                        appleIdentityTokenForBackend: appleData.identityToken, // <<< Pass token
                        appleUserIDFromApple: appleData.appleUserID // Pass Apple's user ID
                        // authService is passed via environment
                    )
                    .environmentObject(authService) // Ensure RoleSelectionView can access it
                } else {
                    // Fallback, should not happen if showingRoleSelectionSheet is true
                    Text("Error: Missing Apple authentication data for role selection.")
                }
            }
            // RootView will handle navigation when authService.authToken changes
            .onChange(of: authService.authToken) { newToken in
                if newToken != nil {
                    print("LoginView: authToken changed. Clearing local login states.")
                    self.email = ""
                    self.password = ""
                    self.appleSignInDataForRoleSelection = nil
                    // showingRoleSelectionSheet should be false if login succeeded
                    if showingRoleSelectionSheet { showingRoleSelectionSheet = false }
                }
            }
        } // End NavigationView
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthService())
    }
}
