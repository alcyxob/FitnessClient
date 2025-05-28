// LoginView.swift
import SwiftUI
import AuthenticationServices

struct LoginView: View {
    // Use @StateObject to create and manage the lifecycle of AuthService
    @EnvironmentObject var authService: AuthService

    // State variables to hold user input
    @State private var email = ""
    @State private var password = ""
    
    @State private var showingRoleSelection = false
    @State private var appleAuthResult: ASAuthorizationAppleIDCredential? = nil // Store Apple's credential temporarily
    @State private var appleAuthFullName: PersonNameComponents? = nil // Store full name if provided

    var body: some View {
        NavigationView { // Often useful for titles, navigation later
            VStack(spacing: 20) {
                Spacer()

                Text("Fitness App Login")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress) // Helps with autofill
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground)) // Subtle background
                    .cornerRadius(8)

                SecureField("Password", text: $password)
                    .textContentType(.password) // Helps with autofill
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                // --- Login Button & Loading Indicator ---
                if authService.isLoading && appleAuthResult == nil {
                    ProgressView() // Show loading spinner
                        .padding(.top)
                } else if appleAuthResult == nil { // Only show email/pass login button if not in Apple Sign-In flow
                    Button("Login") {
                        Task { await authService.login(email: email, password: password) }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.top)
                    // Disable button if fields are empty or loading
                    .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
                }
                
                HStack {
                    VStack { Divider() }
                    Text("OR").foregroundColor(.gray)
                    VStack { Divider() }
                }
                .padding(.vertical)

                // --- SIGN IN WITH APPLE BUTTON ---
                SignInWithAppleButton(
                    .signIn, // Or .signUp, or .continue
                    onRequest: configureAppleSignInRequest,
                    onCompletion: handleAppleSignInCompletion
                )
                .signInWithAppleButtonStyle(.black) // Or .white, .whiteOutline
                .frame(height: 50)
                .cornerRadius(8)
                // --- END SIGN IN WITH APPLE BUTTON ---
                
                // --- General Loading Indicator (for Apple Sign-In backend call) ---
                if authService.isLoading && appleAuthResult != nil {
                    ProgressView("Finalizing Sign-In...")
                        .padding(.top)
                }


                // --- Error Message Display ---
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.top)
                        .multilineTextAlignment(.center)
                }

                Spacer()
                Spacer() // Pushes content towards the center/top

            } // End VStack
            .padding() // Add padding around the VStack content
            .navigationTitle("Welcome") // Set a title if using NavigationView
            .navigationBarHidden(true) // Hide the default bar if needed
            // --- Sheet for Role Selection (for NEW Apple Sign-In users) ---
            .sheet(isPresented: $showingRoleSelection, onDismiss: {
                // If sheet is dismissed without selecting a role, clear appleAuthResult
                // to allow trying Apple Sign-In again or email/pass login.
                if !authService.isLoading { // Don't clear if backend call is in progress
                    appleAuthResult = nil
                    appleAuthFullName = nil
                }
            }) {
                // Pass the necessary data to RoleSelectionView
                RoleSelectionView(
                    appleAuthCredential: appleAuthResult, // Pass the credential
                    appleAuthFullName: appleAuthFullName,
                    authService: authService // To call the final backend registration
                )
            }

            // --- Post-Login Check (Example) ---
            // In a real app, you'd navigate away or change the view
            .onChange(of: authService.authToken) { newToken in
                if newToken != nil {
                    print("LoginView: Auth Token set via authService. App should navigate via RootView.")
                    // RootView handles the navigation based on authToken.
                    // Clear local states if needed, though RootView switch should suffice.
                    self.email = ""
                    self.password = ""
                    self.appleAuthResult = nil
                    self.appleAuthFullName = nil
                }
            }

        } // End NavigationView
    }
    
    // --- Apple Sign-In Request Configuration ---
    func configureAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        print("Configuring Apple Sign-In Request...")
        authService.errorMessage = nil // Clear previous errors
        // appleAuthResult = nil // Clear previous result
        request.requestedScopes = [.fullName, .email]
        // Optional: If you have state for a nonce (for replay protection, more advanced)
        // request.nonce = ...
    }
    
    // --- Apple Sign-In Completion Handler ---
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            print("Apple Sign-In Success!")
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                self.appleAuthResult = appleIDCredential // Store the credential
                self.appleAuthFullName = appleIDCredential.fullName // Store name parts if given

                // --- Log Apple Credential Details (FOR DEBUGGING ONLY) ---
                print("   Apple User ID (for your team): \(appleIDCredential.user)")
                if let email = appleIDCredential.email { print("   Email (first time only): \(email)") }
                if let givenName = appleIDCredential.fullName?.givenName { print("   Given Name (first time only): \(givenName)") }
                if let familyName = appleIDCredential.fullName?.familyName { print("   Family Name (first time only): \(familyName)") }
                if let identityTokenData = appleIDCredential.identityToken,
                   let identityTokenString = String(data: identityTokenData, encoding: .utf8) {
                    print("   Identity Token Length: \(identityTokenString.count)")
                    // DO NOT print the full token in production logs
                }
                // --- END DEBUG LOGS ---


                // **NEXT STEP:** Call your backend.
                // Before calling backend: If it's a *new* user (which your backend will determine),
                // you might need to ask for their role (Trainer/Client) first.
                // For now, let's assume we'll ask for role *if* backend says it's a new user
                // OR we can try to send role directly if we can determine it here.
                //
                // The backend's SignInWithApple now takes a `roleIfNewUser`.
                // How do we get this role? We need to show RoleSelectionView.
                
                // Let's set a flag to show the role selection sheet.
                // The actual call to your backend will happen *from* the RoleSelectionView
                // after a role is chosen, or directly if we can assume a role or backend handles it.
                //
                // For now, let's assume if email from Apple is nil or if user ID is new (can't check that here easily),
                // we show role selection. A simpler way is to *always* call the backend and if it says
                // "role required for new user", then show the role selection.
                //
                // Let's make RoleSelectionView responsible for calling the backend.
                // So, here we just set the state to show it.
                
                self.showingRoleSelection = true


            } else if let passwordCredential = authorization.credential as? ASPasswordCredential {
                // User signed in using a saved password from iCloud Keychain.
                // You can get the username and password here.
                // Not typically part of "Sign in with Apple" button flow directly, but part of ASAuthorization.
                print("Apple Sign-In: User selected a password credential: \(passwordCredential.user)")
                // You would use these credentials with your standard email/password login.
                self.email = passwordCredential.user
                self.password = passwordCredential.password
                Task { await authService.login(email: self.email, password: self.password) }
            }

        case .failure(let error):
            print("Apple Sign-In Failed: \(error.localizedDescription)")
            if (error as? ASAuthorizationError)?.code == .canceled {
                authService.errorMessage = "Sign in with Apple was canceled."
            } else {
                authService.errorMessage = "Apple Sign-In Error: \(error.localizedDescription)"
            }
            self.appleAuthResult = nil // Clear on failure
            self.appleAuthFullName = nil
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthService())
    }
}
