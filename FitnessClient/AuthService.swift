// AuthService.swift
import Foundation
import KeychainAccess
import LocalAuthentication // For biometric authentication
import UIKit // For UIDevice access

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

    // --- Enhanced Keychain Configuration ---
    private let keychainService = Bundle.main.bundleIdentifier ?? "com.example.fitnessclient.keychain"
    private let keychainAuthTokenKey = "authToken"
    private let keychainUserKey = "loggedInUser"
    
    // Biometric authentication settings
    @Published var biometricAuthEnabled = false
    @Published var biometricType: LABiometryType = .none
    
    private var keychain: Keychain {
        let keychain = Keychain(service: keychainService)
        // Use basic accessibility for now to avoid crashes
        return keychain.accessibility(.whenUnlockedThisDeviceOnly)
    }
    
    // Separate keychain for sensitive data
    private var secureKeychain: Keychain {
        let keychain = Keychain(service: keychainService + ".secure")
        
        // Only add biometric protection if it's available and enabled
        if biometricAuthEnabled && biometricType != .none {
            return keychain
                .accessibility(.whenPasscodeSetThisDeviceOnly)
                .authenticationPrompt("Authenticate to access your account")
        } else {
            return keychain.accessibility(.whenUnlockedThisDeviceOnly)
        }
    }

    // --- Initializer ---
    init() {
        // Check biometric availability safely
        do {
            checkBiometricAvailability()
        } catch {
            print("AuthService: Error checking biometric availability: \(error)")
            biometricType = .none
        }
        
        // Load biometric preference from UserDefaults safely
        biometricAuthEnabled = UserDefaults.standard.bool(forKey: "biometricAuthEnabled")
        
        // Attempt to load token and user from Keychain when the service is created
        do {
            loadTokenAndUserFromKeychain()
            if authToken != nil {
                print("AuthService: Session loaded from Keychain. User: \(loggedInUser?.email ?? "N/A")")
            } else {
                print("AuthService: No active session found in Keychain.")
            }
        } catch {
            print("AuthService: Error loading from keychain: \(error)")
            // Clear any partial state
            self.authToken = nil
            self.loggedInUser = nil
        }
        
        // Listen for authentication required notifications
        NotificationCenter.default.addObserver(
            forName: .authenticationRequired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAuthenticationRequired()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // --- Enhanced Error Handling ---
    private func handleAuthError(_ error: Error, context: String = "") {
        let appError: AppError
        
        if let apiError = error as? APINetworkError {
            switch apiError {
            case .unauthorized:
                appError = .unauthorized
            case .requestFailed(let underlyingError):
                appError = convertNetworkError(underlyingError)
            case .decodingError:
                appError = .decodingFailed
            case .serverError(let statusCode, let message):
                appError = .serverError(statusCode: statusCode, message: message)
            default:
                appError = .authenticationFailed
            }
        } else {
            appError = .authenticationFailed
        }
        
        // Set local error state
        errorMessage = appError.localizedDescription
        
        // Report to global error manager
        ErrorManager.shared.handle(appError, context: "AuthService: \(context)")
        
        print("🚨 AuthService Error (\(context)): \(appError.localizedDescription ?? "Unknown error")")
    }
    
    private func convertNetworkError(_ error: Error) -> AppError {
        let nsError = error as NSError
        
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return .networkUnavailable
        case NSURLErrorTimedOut:
            return .requestTimeout
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
            return .serverUnavailable
        default:
            return .unknown(error.localizedDescription)
        }
    }
    
    private func clearError() {
        errorMessage = nil
        ErrorManager.shared.clearError()
    }
    
    private func handleAuthenticationRequired() {
        // Force logout when authentication is required
        Task {
            await logout()
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
        clearError()
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
                throw APINetworkError.requestFailed(URLError(.cannotParseResponse))
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

            } else {
                // Handle HTTP error responses
                let errorMessage: String
                do {
                    let errorResponse = try decoder.decode(APIErrorResponse.self, from: data)
                    errorMessage = errorResponse.error
                } catch {
                    errorMessage = "Login failed with status: \(httpResponse.statusCode)"
                }
                
                if httpResponse.statusCode == 401 {
                    throw APINetworkError.unauthorized
                } else {
                    throw APINetworkError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
                }
            }
        } catch {
            handleAuthError(error, context: "Login")
            await clearSession() // Clear session on error during login
        }
        isLoading = false
    }

    // MARK: - Email Authentication
    
    func registerWithEmail(name: String, email: String, password: String) async {
        print("AuthService: Starting email registration for \(email)")
        isLoading = true
        errorMessage = nil
        
        do {
            let request = EmailRegistrationRequest(
                name: name,
                email: email,
                password: password,
                role: "client" // Default to client role
            )
            
            print("AuthService: Sending registration request to backend")
            
            // Registration endpoint returns UserResponse (no token), so we expect just user data
            let userResponse: UserResponse = try await makeAuthenticatedRequest(
                endpoint: "/auth/register",
                method: "POST",
                body: request
            )
            
            print("AuthService: Email registration successful, user created: \(userResponse.email)")
            print("AuthService: Now logging in automatically...")
            
            // Registration successful, now automatically log in to get the token
            await loginWithEmail(email: email, password: password)
            
        } catch {
            print("AuthService: Email registration failed - \(error)")
            handleAuthError(error, context: "Email Registration")
        }
        
        isLoading = false
    }
    
    func loginWithEmail(email: String, password: String) async {
        print("AuthService: Starting email login for \(email)")
        isLoading = true
        errorMessage = nil
        
        do {
            let request = EmailLoginRequest(email: email, password: password)
            
            print("AuthService: Sending login request to backend")
            let response: LoginResponse = try await makeAuthenticatedRequest(
                endpoint: "/auth/login",
                method: "POST",
                body: request
            )
            
            print("AuthService: Email login successful")
            await processSuccessfulLogin(token: response.token, user: response.user)
            
        } catch {
            print("AuthService: Email login failed - \(error)")
            handleAuthError(error, context: "Email Login")
        }
        
        isLoading = false
    }
    
    func requestPasswordReset(email: String) async {
        print("AuthService: Requesting password reset for \(email)")
        isLoading = true
        errorMessage = nil
        
        do {
            let request = PasswordResetRequest(email: email)
            
            let _: EmptyResponse = try await makeAuthenticatedRequest(
                endpoint: "/auth/forgot-password",
                method: "POST",
                body: request
            )
            
            print("AuthService: Password reset request sent successfully")
            // Success handled by UI showing confirmation message
            
        } catch {
            print("AuthService: Password reset request failed - \(error)")
            handleAuthError(error, context: "Password Reset Request")
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods for Email Auth
    
    private func makeAuthenticatedRequest<T: Codable, U: Codable>(
        endpoint: String,
        method: String,
        body: T
    ) async throws -> U {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode request body
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            print("AuthService: JSON encoding failed - \(error)")
            throw AppError.encodingFailed
        }
        
        // Make request
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            // Handle network connectivity errors
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    throw AppError.networkUnavailable
                case .timedOut:
                    throw AppError.requestTimeout
                default:
                    throw AppError.unknown("Network error: \(urlError.localizedDescription)")
                }
            } else {
                throw AppError.unknown("Request failed: \(error.localizedDescription)")
            }
        }
        
        // Debug: Print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("AuthService: Raw API response: \(responseString)")
        }
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidData
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            // Try to decode error response
            if let errorData = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw AppError.serverError(statusCode: httpResponse.statusCode, message: errorData.error)
            } else {
                switch httpResponse.statusCode {
                case 401:
                    throw AppError.unauthorized
                case 403:
                    throw AppError.forbidden
                case 404:
                    throw AppError.notFound
                case 429:
                    throw AppError.rateLimited
                case 500...599:
                    throw AppError.serverError(statusCode: httpResponse.statusCode, message: nil)
                default:
                    throw AppError.serverError(statusCode: httpResponse.statusCode, message: "HTTP \(httpResponse.statusCode)")
                }
            }
        }
        
        // Decode successful response
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Create formatters for different date formats that the backend might send
            let nanosecondFormatter = DateFormatter()
            nanosecondFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSS'Z'"
            nanosecondFormatter.timeZone = TimeZone(abbreviation: "UTC")
            
            let millisecondFormatter = DateFormatter()
            millisecondFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            millisecondFormatter.timeZone = TimeZone(abbreviation: "UTC")
            
            let secondFormatter = DateFormatter()
            secondFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            secondFormatter.timeZone = TimeZone(abbreviation: "UTC")
            
            // Try different date formats
            if let date = nanosecondFormatter.date(from: dateString) {
                return date
            } else if let date = millisecondFormatter.date(from: dateString) {
                return date
            } else if let date = secondFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Cannot decode date string: \(dateString)"
                )
            )
        }
        
        do {
            return try decoder.decode(U.self, from: data)
        } catch {
            print("AuthService: JSON decoding failed - \(error)")
            throw AppError.decodingFailed
        }
    }

    // --- Logout Function ---
    func logout() async { // Mark as async if clearSession becomes async
        await clearSession()
        print("User logged out. Session cleared from Keychain.")
    }

    // --- Biometric Authentication Methods ---
    
    private func checkBiometricAvailability() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.checkBiometricAvailability()
            }
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        // Use .deviceOwnerAuthenticationWithBiometrics for iOS compatibility
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if canEvaluate {
            biometricType = context.biometryType
            print("AuthService: Biometric authentication available: \(biometricType.rawValue)")
        } else {
            biometricType = .none
            if let error = error {
                print("AuthService: Biometric authentication not available: \(error.localizedDescription)")
            }
        }
    }
    
    func enableBiometricAuth() async -> Bool {
        guard biometricType != .none else {
            print("AuthService: Biometric authentication not available on this device")
            return false
        }
        
        let context = LAContext()
        let reason = "Enable biometric authentication to secure your fitness app"
        
        do {
            // Use .deviceOwnerAuthenticationWithBiometrics for iOS compatibility
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            if success {
                biometricAuthEnabled = true
                UserDefaults.standard.set(true, forKey: "biometricAuthEnabled")
                print("AuthService: Biometric authentication enabled")
                
                // Re-save current session with biometric protection
                if let token = authToken, let user = loggedInUser {
                    saveTokenAndUserToKeychain(token: token, user: user)
                }
                return true
            }
        } catch {
            print("AuthService: Failed to enable biometric authentication: \(error.localizedDescription)")
        }
        return false
    }
    
    func disableBiometricAuth() {
        biometricAuthEnabled = false
        UserDefaults.standard.set(false, forKey: "biometricAuthEnabled")
        print("AuthService: Biometric authentication disabled")
        
        // Re-save current session without biometric protection
        if let token = authToken, let user = loggedInUser {
            saveTokenAndUserToKeychain(token: token, user: user)
        }
    }
    
    func authenticateWithBiometrics() async -> Bool {
        guard biometricAuthEnabled && biometricType != .none else {
            return true // Skip if not enabled
        }
        
        let context = LAContext()
        let reason = "Authenticate to access your fitness data"
        
        do {
            // Use .deviceOwnerAuthenticationWithBiometrics for iOS compatibility
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            print("AuthService: Biometric authentication \(success ? "successful" : "failed")")
            return success
        } catch {
            print("AuthService: Biometric authentication error: \(error.localizedDescription)")
            return false
        }
    }
    // --- Enhanced Keychain Helper Methods ---
    
    private func saveTokenAndUserToKeychain(token: String, user: UserResponse) {
        do {
            print("AuthService: Saving to Keychain with enhanced security. Token length: \(token.count), User roles: \(user.roles)")
            
            // Use secure keychain for sensitive auth token
            try secureKeychain.set(token, key: keychainAuthTokenKey)

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
            
            // Use regular keychain for user data (less sensitive)
            try keychain.set(userData, key: keychainUserKey)

            print("AuthService: Token and user data saved to Keychain with enhanced security.")
        } catch {
            print("AuthService: Error saving to Keychain: \(error.localizedDescription)")
            // If keychain save fails, clear the session to prevent inconsistent state
            Task {
                await clearSession()
            }
        }
    }
    
    private func loadTokenAndUserFromKeychain() {
        do {
            // Load auth token from secure keychain
            if let token = try secureKeychain.get(keychainAuthTokenKey), !token.isEmpty {
                self.authToken = token

                // Load user data from regular keychain
                if let userData = try keychain.getData(keychainUserKey), !userData.isEmpty {
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

                    self.loggedInUser = try decoder.decode(UserResponse.self, from: userData)
                    print("AuthService: Successfully loaded session from secure keychain")
                } else {
                    // Token found but no user data, something is inconsistent
                    print("AuthService: Token found, but user data missing. Clearing session for security.")
                    try? secureKeychain.remove(keychainAuthTokenKey)
                    self.authToken = nil
                    self.loggedInUser = nil
                }
            } else {
                self.authToken = nil
                self.loggedInUser = nil
            }
        } catch {
            print("AuthService: Error loading from Keychain: \(error.localizedDescription)")
            // If there's an error (like biometric auth failed), treat as no session
            self.authToken = nil
            self.loggedInUser = nil
        }
    }

    private func clearSession() async {
        do {
            // Clear from both keychains
            try secureKeychain.remove(keychainAuthTokenKey)
            try keychain.remove(keychainUserKey)
            print("AuthService: Keychain data cleared from both secure and regular keychains.")
        } catch {
            print("AuthService: Error clearing Keychain: \(error.localizedDescription)")
        }
        
        // Clear published properties
        self.authToken = nil
        self.loggedInUser = nil
        self.errorMessage = nil
    }
    
    func updateStoredUser(user: UserResponse) {
        // This method updates the user object in Keychain without touching the token.
        guard self.authToken != nil else {
            print("AuthService: Attempted to update user but no auth token exists. Aborting.")
            return
        }
        
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
            self.loggedInUser = user
            print("AuthService: Updated user data in Keychain securely.")
        } catch {
            print("AuthService: Error updating user data in Keychain: \(error.localizedDescription)")
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
    
    // --- NEW: Method to update user state after an action ---
    func updateLoggedInUser(with updatedUser: UserResponse) {
        // This method updates the global state and re-saves to Keychain
        // so the new role persists across app launches.
        guard self.authToken != nil else {
            print("AuthService: Attempted to update user but no auth token exists. Aborting.")
            return
        }
        self.loggedInUser = updatedUser
        // Re-save the updated user object to the Keychain
        saveTokenAndUserToKeychain(token: self.authToken!, user: updatedUser)
        print("AuthService: Global user state and Keychain updated with new roles.")
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
