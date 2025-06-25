// AppleSignInManager.swift
import SwiftUI
import AuthenticationServices // For ASAuthorizationControllerDelegate etc.

// Define a struct to hold the result of Apple Sign In
struct AppleSignInResult {
    let identityToken: String
    let appleUserID: String // Apple's unique subject ID
    let firstName: String?
    let lastName: String?
    let email: String? // Email provided by Apple (can be private relay)
}

@MainActor
class AppleSignInManager: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    @Published var appleSignInError: Error? = nil

    // This is the only state this manager needs to track for the async/await flow
    private var currentContinuation: CheckedContinuation<AppleSignInResult, Error>?
    private var currentAuthorizationController: ASAuthorizationController?

    // --- REMOVED @Published properties not directly related to this manager's job ---
    // The LoginView's main AuthService should handle isLoading and isSignedIn states
    // @Published var isSignedInWithApple: Bool = false
    // @Published var appleUserResult: AppleSignInResult? = nil
    // @Published var isLoading: Bool = false

    func startSignInWithAppleFlow() async throws -> AppleSignInResult {
        // Clear any previous error state from this manager
        self.appleSignInError = nil
        
        return try await withCheckedThrowingContinuation { continuation in
            // IMPORTANT: If a continuation already exists, it means a previous flow
            // didn't complete. We should fail it to avoid leaks.
            if self.currentContinuation != nil {
                print("AppleSignInManager: A previous sign-in flow was already in progress. Canceling it.")
                let error = NSError(domain: "AppleSignInError", code: 999, userInfo: [NSLocalizedDescriptionKey: "New sign-in request started before previous one completed."])
                self.currentContinuation?.resume(throwing: error)
            }
            
            self.currentContinuation = continuation
            print("AppleSignInManager: Stored new continuation.")

            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            self.currentAuthorizationController = authorizationController // Retain
            
            // Perform requests on the main thread
            DispatchQueue.main.async {
                print("AppleSignInManager: Calling performRequests() on main thread.")
                authorizationController.performRequests()
            }
        }
    }

    // --- ASAuthorizationControllerDelegate Methods ---

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("AppleSignInManager DELEGATE: didCompleteWithAuthorization CALLED!")
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            let error = NSError(domain: "AppleSignInError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to obtain Apple ID Credential."])
            // Resume with error IF continuation exists
            if let continuation = self.currentContinuation {
                print("AppleSignInManager: Resuming continuation with credential cast error.")
                continuation.resume(throwing: error)
                self.currentContinuation = nil // Nil it out
            } else {
                 print("AppleSignInManager: Continuation was nil on credential cast error.")
            }
            self.currentAuthorizationController = nil
            return
        }

        // ... (get identityTokenString, firstName, lastName, email as before) ...
        guard let identityTokenData = appleIDCredential.identityToken,
              let identityTokenString = String(data: identityTokenData, encoding: .utf8) else {
            // ... (handle missing token error, resume with error, nil out continuation) ...
            let error = NSError(domain: "AppleSignInError", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Missing or invalid identity token."])
             if let continuation = self.currentContinuation {
                continuation.resume(throwing: error)
                self.currentContinuation = nil
            }
            self.currentAuthorizationController = nil
            return
        }

        let result = AppleSignInResult(
            identityToken: identityTokenString,
            appleUserID: appleIDCredential.user,
            firstName: appleIDCredential.fullName?.givenName,
            lastName: appleIDCredential.fullName?.familyName,
            email: appleIDCredential.email
        )
        
        if let continuation = self.currentContinuation {
            print("AppleSignInManager: Continuation FOUND. Resuming with successful result.")
            continuation.resume(returning: result)
            self.currentContinuation = nil // Nil it out
        } else {
            print("AppleSignInManager: CRITICAL ERROR - Continuation was NIL on success path. Cannot resume async task.")
        }
        self.currentAuthorizationController = nil // Release controller
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("AppleSignInManager DELEGATE: didCompleteWithError CALLED! Error: \(error.localizedDescription)")
        self.appleSignInError = error // Store the specific error
        
        if let continuation = self.currentContinuation {
            print("AppleSignInManager: Continuation FOUND. Resuming with error.")
            continuation.resume(throwing: error)
            self.currentContinuation = nil // Nil it out
        } else {
            print("AppleSignInManager: CRITICAL ERROR - Continuation was NIL on error path.")
        }
        self.currentAuthorizationController = nil // Release controller
    }

    // --- ASAuthorizationControllerPresentationContextProviding Method ---
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        print("AppleSignInManager DELEGATE: presentationAnchor CALLED!")
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            print("!!! AppleSignInManager: CRITICAL - Could not find key window.")
            return ASPresentationAnchor()
        }
        return window
    }
}
