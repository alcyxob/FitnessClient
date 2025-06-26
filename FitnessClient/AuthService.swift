// AuthService.swift
import Foundation
import KeychainAccess // Import the library

// DTO for pre-check request
struct ApplePreCheckRequest: Codable {
    let identityToken: String
}

// DTO for pre-check response
struct ApplePreCheckResponse: Codable {
    let userExists: Bool // Match backend JSON key, e.g., "user_exists"
    
    // Add CodingKeys if backend JSON differs
    enum CodingKeys: String, CodingKey {
        case userExists = "user_exists"
    }
}

@MainActor
class AuthService: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var authToken: String? = nil
    @Published var loggedInUser: UserResponse? = nil

    private let baseURL = URL(string: "https://dev-api.fitnessapp.jutechnik.com/api/v1")!

    // --- Keychain Configuration ---
    // Use a unique service name for your app to avoid conflicts.
    // The bundle identifier is a good choice.
    private let keychainService = Bundle.main.bundleIdentifier ?? "com.example.fitnessclient.keychain"
    private let keychainAuthTokenKey = "authToken" // Key to store the token under
    private let keychainUserKey = "loggedInUser"   // Key to store user data (optional)

    private var keychain: Keychain {
        // By default, KeychainAccess items are shared across apps from the same developer
        // if they share an access group. For a single app, this is fine.
        // For more security or if you need iCloud syncing, explore access groups.
        return Keychain(service: keychainService)
    }

    // --- Initializer ---
    init() {
        // Attempt to load token and user from Keychain when the service is created
        loadTokenAndUserFromKeychain()
        if authToken != nil {
            print("AuthService: Session loaded from Keychain. User: \(loggedInUser?.email ?? "N/A")")
        } else {
            print("AuthService: No active session found in Keychain.")
        }
    }
    
    func processSuccessfulLogin(token: String, user: UserResponse) {
        print("AuthService: Processing successful login/session update for user \(user.email)")
        // 1. Save to Keychain
        saveTokenAndUserToKeychain(token: token, user: user)
        // 2. Update published properties to trigger UI changes
        self.authToken = token
        self.loggedInUser = user
        self.errorMessage = nil
    }

    // --- Login Function ---
    func login(email: String, password: String) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        let loginURL = baseURL.appendingPathComponent("auth/login")

        do {
            var request = URLRequest(url: loginURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let loginData = LoginRequest(email: email, password: password)
            request.httpBody = try JSONEncoder().encode(loginData)

            print("Attempting login to: \(loginURL)")
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.cannotParseResponse)
            }
            print("Received status code: \(httpResponse.statusCode)")

            let decoder = JSONDecoder()
            let iso8601WithMillisecondsFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                formatter.calendar = Calendar(identifier: .iso8601)
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }()
            decoder.dateDecodingStrategy = .formatted(iso8601WithMillisecondsFormatter)

            if (200..<300).contains(httpResponse.statusCode) {
                let loginResponse = try decoder.decode(LoginResponse.self, from: data)
                processSuccessfulLogin(token: loginResponse.token, user: loginResponse.user)
                print("Login successful! Token received.")

                // --- SAVE TO KEYCHAIN ---
                saveTokenAndUserToKeychain(token: loginResponse.token, user: loginResponse.user)

                // Update published properties
                self.authToken = loginResponse.token
                self.loggedInUser = loginResponse.user
                print("AuthService: authToken set to: \(self.authToken ?? "NIL TOKEN")")
                print("AuthService: loggedInUser set to email: \(self.loggedInUser?.email ?? "NIL USER")")
                self.errorMessage = nil

            } else {
                do {
                    let errorResponse = try decoder.decode(APIErrorResponse.self, from: data)
                    throw APIErrorResponse(error: errorResponse.error)
                } catch {
                    let genericError = "Login failed with status: \(httpResponse.statusCode)"
                    print("Failed to decode error response body, using generic error.")
                    throw APIErrorResponse(error: genericError)
                }
            }
        } catch let apiError as APIErrorResponse {
            print("API Error: \(apiError.error)")
            self.errorMessage = apiError.error
            await clearSession() // Clear session on API error during login
        } catch {
            print("Login Error: \(error.localizedDescription)")
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            await clearSession() // Clear session on other errors
        }
        isLoading = false
    }

    // --- Logout Function ---
    func logout() async { // Mark as async if clearSession becomes async
        await clearSession()
        print("User logged out. Session cleared from Keychain.")
    }

    // --- Keychain Helper Methods ---
    private func saveTokenAndUserToKeychain(token: String, user: UserResponse) {
        do {
            print("AuthService: Saving to Keychain. Token length: \(token.count), User roles: \(user.roles)")
            try keychain.set(token, key: keychainAuthTokenKey)

            let encoder = JSONEncoder()
            // --- USE THE CUSTOM FORMATTER FOR ENCODING ---
            let iso8601WithMillisecondsFormatter: DateFormatter = { // You can define this once in the class if preferred
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                formatter.calendar = Calendar(identifier: .iso8601)
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }()
            encoder.dateEncodingStrategy = .formatted(iso8601WithMillisecondsFormatter)
            // --- END CHANGE ---

            let userData = try encoder.encode(user)
            try keychain.set(userData, key: keychainUserKey)

            print("Token and user data saved to Keychain.")
        } catch {
            print("Error saving to Keychain: \(error.localizedDescription)")
        }
    }
    
    // --- NEW: Pre-check method ---
    func precheckAppleUser(identityToken: String) async throws -> Bool {
        print("AuthService: Pre-checking Apple user with backend...")
        isLoading = true // Use general loading state
        defer { isLoading = false }

        let endpoint = "/auth/apple/precheck"
        let payload = ApplePreCheckRequest(identityToken: identityToken)
        
        // This can use your generic APIService if it's set up for non-authenticated POSTs
        // or a direct URLSession call. Let's assume a direct call for clarity.
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // Handle 401, 500 etc.
            throw APIErrorResponse(error: "Pre-check failed with status \( (response as? HTTPURLResponse)?.statusCode ?? 0 )")
        }

        let preCheckResponse = try JSONDecoder().decode(ApplePreCheckResponse.self, from: data)
        print("AuthService: Pre-check response received. User exists: \(preCheckResponse.userExists)")
        return preCheckResponse.userExists
    }

    private func loadTokenAndUserFromKeychain() {
        do {
            // Load auth token
            if let token = try keychain.get(keychainAuthTokenKey) {
                self.authToken = token

                // Load user data
                if let userData = try keychain.getData(keychainUserKey) {
                    let decoder = JSONDecoder()
                    // Make sure date decoding strategy matches how you stored it
                    let iso8601WithMillisecondsFormatter: DateFormatter = {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                        formatter.calendar = Calendar(identifier: .iso8601)
                        formatter.timeZone = TimeZone(secondsFromGMT: 0)
                        formatter.locale = Locale(identifier: "en_US_POSIX")
                        return formatter
                    }()
                    decoder.dateDecodingStrategy = .formatted(iso8601WithMillisecondsFormatter)

                    self.loggedInUser = try decoder.decode(UserResponse.self, from: userData)
                } else {
                    // Token found but no user data, something is inconsistent
                    // Consider this an invalid session and clear the token
                    print("Keychain: Token found, but user data missing. Clearing token.")
                    try keychain.remove(keychainAuthTokenKey)
                    self.authToken = nil
                    self.loggedInUser = nil
                }
            } else {
                self.authToken = nil
                self.loggedInUser = nil
            }
        } catch {
            print("Error loading from Keychain: \(error.localizedDescription)")
            // Assume no valid session if there's an error
            self.authToken = nil
            self.loggedInUser = nil
        }
    }

    // Made this async in case keychain operations become async in future library versions
    // or if you add other async cleanup.
    private func clearSession() async {
        do {
            try keychain.remove(keychainAuthTokenKey)
            try keychain.remove(keychainUserKey) // Remove user data too
            print("Keychain data cleared.")
        } catch {
            print("Error clearing Keychain: \(error.localizedDescription)")
        }
        // Clear published properties
        self.authToken = nil
        self.loggedInUser = nil
        self.errorMessage = nil // Also clear error message on logout
    }

    // --- NEW: Finalize Apple Sign-In by calling your backend ---
     func finalizeAppleSignIn(
         identityToken: String,
         firstName: String,
         lastName: String,
         selectedRole: domain.Role // Assuming domain.Role is your Swift enum
     ) async {
         guard !isLoading else { return }
         print("AuthService: Finalizing Apple Sign-In. Role chosen: \(selectedRole.rawValue)")

         isLoading = true
         errorMessage = nil
         // authToken = nil // Don't clear authToken here yet
         // loggedInUser = nil

         let callbackURL = baseURL.appendingPathComponent("auth/apple/callback")

         // Prepare payload for your backend
         let payload = SignInWithApplePayload( // Define this struct
             identityToken: identityToken,
             firstName: firstName.isEmpty ? nil : firstName, // Send nil if empty
             lastName: lastName.isEmpty ? nil : lastName,
             role: selectedRole.rawValue // Send role as string
         )

         do {
             var request = URLRequest(url: callbackURL)
             request.httpMethod = "POST"
             request.setValue("application/json", forHTTPHeaderField: "Content-Type")
             request.httpBody = try JSONEncoder().encode(payload)

             print("AuthService: Calling backend Apple callback: \(callbackURL)")
             let (data, response) = try await URLSession.shared.data(for: request)

             guard let httpResponse = response as? HTTPURLResponse else {
                 throw URLError(.cannotParseResponse)
             }
             print("AuthService: Backend Apple callback status: \(httpResponse.statusCode)")

             let decoder = JSONDecoder()
             // Make sure your date decoding strategy is consistent if UserResponse is decoded here
             let iso8601WithMillisecondsFormatter: DateFormatter = {
                 let formatter = DateFormatter()
                 formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                 formatter.calendar = Calendar(identifier: .iso8601)
                 formatter.timeZone = TimeZone(secondsFromGMT: 0)
                 formatter.locale = Locale(identifier: "en_US_POSIX")
                 return formatter
             }()
             decoder.dateDecodingStrategy = .formatted(iso8601WithMillisecondsFormatter)


             if (200..<300).contains(httpResponse.statusCode) {
                 // Backend returned your app's JWT and User info
                 let loginResponse = try decoder.decode(LoginResponse.self, from: data) // Expecting your standard LoginResponse
                 
                 print("AuthService: Backend Apple callback successful. Token received.")
                 saveTokenAndUserToKeychain(token: loginResponse.token, user: loginResponse.user) // Save to Keychain
                 
                 self.authToken = loginResponse.token    // Update published properties
                 self.loggedInUser = loginResponse.user
                 self.errorMessage = nil

             } else {
                 // Try to decode backend error
                 do {
                     let errorResponse = try decoder.decode(APIErrorResponse.self, from: data)
                     throw APIErrorResponse(error: "Apple Sign-In failed: \(errorResponse.error)")
                 } catch {
                     throw APIErrorResponse(error: "Apple Sign-In failed with status \(httpResponse.statusCode).")
                 }
             }
         } catch let apiError as APIErrorResponse {
             print("AuthService: API Error during Apple finalize: \(apiError.error)")
             self.errorMessage = apiError.error
             await clearSession() // Clear any partial session
         } catch {
             print("AuthService: Error during Apple finalize: \(error.localizedDescription)")
             self.errorMessage = "An unexpected error occurred during Apple Sign-In: \(error.localizedDescription)"
             await clearSession()
         }
         isLoading = false
     }
    
    func updateStoredUser(user: UserResponse) {
        // This method updates the user object in Keychain without touching the token.
        // It's called after an action like activating a trainer role.
        do {
            let encoder = JSONEncoder()
            let iso8601WithMillisecondsFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                formatter.calendar = Calendar(identifier: .iso8601)
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }()
            encoder.dateEncodingStrategy = .formatted(iso8601WithMillisecondsFormatter)
            
            let userData = try encoder.encode(user)
            try keychain.set(userData, key: keychainUserKey)
            print("AuthService: Updated user data in Keychain.")
        } catch {
            print("AuthService: Error updating user data in Keychain: \(error.localizedDescription)")
        }
    }
    
    // --- NEW: Method to call your backend after Apple Sign In ---
    func handleAppleSignIn(
        identityToken: String,
        firstName: String?,
        lastName: String?,
        selectedRole: domain.Role // Role is now mandatory if it's a new user
    ) async {
        print("AuthService: handleAppleSignIn called. Role: \(selectedRole.rawValue). Preparing to call backend /auth/apple/callback")
        isLoading = true
        errorMessage = nil

        let payload = SignInWithAppleRequest(
            identityToken: identityToken,
            firstName: firstName, // Pass optionals, init handles nil
            lastName: lastName,
            role: selectedRole // Pass the domain.Role enum
        )

        let endpoint = "/auth/apple/callback"

        do {
            var request = URLRequest(url: baseURL.appendingPathComponent(endpoint))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(payload)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.cannotParseResponse)
            }

            print("AuthService: Backend Apple callback response status: \(httpResponse.statusCode)")
            let decoder = JSONDecoder()
            let iso8601WithMillisecondsFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                formatter.calendar = Calendar(identifier: .iso8601)
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }()
            decoder.dateDecodingStrategy = .formatted(iso8601WithMillisecondsFormatter)

            if (200..<300).contains(httpResponse.statusCode) {
                let socialLoginResponse = try decoder.decode(SocialLoginResponse.self, from: data) // <<< DECODE NEW TYPE
                
                saveTokenAndUserToKeychain(token: socialLoginResponse.token, user: socialLoginResponse.user)
                self.authToken = socialLoginResponse.token
                self.loggedInUser = socialLoginResponse.user
                self.errorMessage = nil
                print("AuthService: Successfully signed in/registered via Apple. New User: \(socialLoginResponse.isNewUser)") // <<< USE IT
            } else {
                // Try to decode your backend's APIErrorResponse
                do {
                    let errorResponse = try decoder.decode(APIErrorResponse.self, from: data)
                    throw APIErrorResponse(error: "Backend Apple Sign In: \(errorResponse.error)")
                } catch { // Fallback if error response isn't your standard APIErrorResponse
                    throw APIErrorResponse(error: "Backend Apple Sign In failed with status \(httpResponse.statusCode). Body: \(String(data: data, encoding: .utf8) ?? "No error body")")
                }
            }
        } catch let apiError as APIErrorResponse {
            self.errorMessage = apiError.error
            await clearSession() // Clear any partial session info
        } catch {
            self.errorMessage = "An error occurred during Apple Sign-In: \(error.localizedDescription)"
            await clearSession()
        }
        isLoading = false
    }
}

// --- DTO for sending data to your backend's /auth/apple/callback ---
// Place this in Models.swift or here
struct SignInWithApplePayload: Codable {
    let identityToken: String
    let firstName: String? // Optional
    let lastName: String?  // Optional
    let role: String       // Role as string (e.g., "trainer", "client")
}
