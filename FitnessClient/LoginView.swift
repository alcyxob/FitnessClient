// LoginView.swift
import SwiftUI

struct LoginView: View {
    // Use @StateObject to create and manage the lifecycle of AuthService
    @EnvironmentObject var authService: AuthService

    // State variables to hold user input
    @State private var email = ""
    @State private var password = ""

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
                if authService.isLoading {
                    ProgressView() // Show loading spinner
                        .padding(.top)
                } else {
                    Button("Login") {
                        // Call the login function when button tapped
                        Task { // Use Task to run async code from sync context
                           await authService.login(email: email, password: password)
                        }
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

            // --- Post-Login Check (Example) ---
            // In a real app, you'd navigate away or change the view
            .onChange(of: authService.authToken) { newToken in
                if newToken != nil {
                    print("Auth Token is now set: \(newToken ?? "N/A")")
                    print("Logged in User: \(authService.loggedInUser?.email ?? "N/A")")
                    // Here you would typically transition to the main part of the app
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
