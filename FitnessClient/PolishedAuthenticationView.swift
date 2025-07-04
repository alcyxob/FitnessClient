// PolishedAuthenticationView.swift
import SwiftUI

struct PolishedAuthenticationView: View {
    @StateObject private var viewModel: AuthenticationViewModel
    @EnvironmentObject var appModeManager: AppModeManager
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    
    @State private var currentStep: AuthStep = .welcome
    @State private var showingRoleSelection = false
    @State private var animationProgress: CGFloat = 0
    
    enum AuthStep {
        case welcome, login, register, roleSelection, onboarding
    }
    
    init(authService: AuthService) {
        self._viewModel = StateObject(wrappedValue: AuthenticationViewModel(authService: authService))
    }
    
    var body: some View {
        ZStack {
            // Dynamic background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            // Main content with transitions
            Group {
                switch currentStep {
                case .welcome:
                    WelcomeView(onGetStarted: {
                        transitionTo(.login)
                    })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                case .login:
                    PolishedLoginView(
                        viewModel: viewModel,
                        onLoginSuccess: {
                            // Skip role selection - users default to client
                            transitionTo(.onboarding)
                        },
                        onSwitchToRegister: {
                            transitionTo(.register)
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                case .register:
                    PolishedRegisterView(
                        viewModel: viewModel,
                        onRegisterSuccess: {
                            // Skip role selection - new users default to client
                            transitionTo(.onboarding)
                        },
                        onSwitchToLogin: {
                            transitionTo(.login)
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                case .roleSelection:
                    PolishedRoleSelectionView(
                        onRoleSelected: { role in
                            appModeManager.switchTo(mode: role)
                            transitionTo(.onboarding)
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    
                case .onboarding:
                    PolishedOnboardingView(
                        selectedRole: .client, // Default to client role
                        onComplete: {
                            completeAuthentication()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            .animation(.easeInOut(duration: 0.5), value: currentStep)
        }
    }
    
    // MARK: - Background Gradient
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.easeInOut(duration: 0.8), value: currentStep)
    }
    
    private var backgroundColors: [Color] {
        switch currentStep {
        case .welcome:
            return [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]
        case .login, .register:
            return [theme.gradientStart, theme.gradientEnd]
        case .roleSelection:
            return [Color.green.opacity(0.7), Color.blue.opacity(0.8)]
        case .onboarding:
            return [theme.primary.opacity(0.8), theme.secondary.opacity(0.6)]
        }
    }
    
    // MARK: - Helper Methods
    
    private func transitionTo(_ step: AuthStep) {
        HapticManager.shared.impact(.light)
        
        withAnimation(.easeInOut(duration: 0.5)) {
            currentStep = step
        }
    }
    
    private func completeAuthentication() {
        HapticManager.shared.notification(.success)
        
        // Set default mode to client for new users
        appModeManager.switchTo(mode: .client)
        
        // Authentication complete - handled by parent view
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    let onGetStarted: () -> Void
    
    @State private var logoScale: CGFloat = 0.8
    @State private var titleOffset: CGFloat = 50
    @State private var buttonOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Logo and branding
            VStack(spacing: 24) {
                // App logo with animation
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(logoScale)
                    
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.white)
                        .scaleEffect(logoScale)
                }
                
                // App title
                VStack(spacing: 8) {
                    Text("FitnessPro")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .offset(y: titleOffset)
                    
                    Text("Your Personal Fitness Journey")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                        .offset(y: titleOffset)
                }
            }
            
            // Feature highlights
            VStack(spacing: 16) {
                FeatureHighlight(
                    icon: "person.2.fill",
                    title: "Connect with Trainers",
                    subtitle: "Get personalized workout plans"
                )
                
                FeatureHighlight(
                    icon: "chart.bar.fill",
                    title: "Track Progress",
                    subtitle: "Monitor your fitness journey"
                )
                
                FeatureHighlight(
                    icon: "heart.fill",
                    title: "Stay Motivated",
                    subtitle: "Achieve your fitness goals"
                )
            }
            .opacity(buttonOpacity)
            
            Spacer()
            
            // Get started button
            Button(action: onGetStarted) {
                Text("Get Started")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(EnhancedButtonStyle(style: .ghost))
            .padding(.horizontal, 40)
            .opacity(buttonOpacity)
            
            Spacer()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Logo animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
            logoScale = 1.0
        }
        
        // Title animation
        withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
            titleOffset = 0
        }
        
        // Button animation
        withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
            buttonOpacity = 1.0
        }
    }
}

struct FeatureHighlight: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Polished Login View

struct PolishedLoginView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    let onLoginSuccess: () -> Void
    let onSwitchToRegister: () -> Void
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @FocusState private var focusedField: LoginField?
    
    enum LoginField {
        case email, password
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Text("Welcome Back")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Sign in to continue your fitness journey")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                // Login form
                VStack(spacing: 20) {
                    // Email field
                    EnhancedTextField(
                        title: "Email",
                        text: $email,
                        placeholder: "Enter your email",
                        keyboardType: .emailAddress,
                        isFocused: focusedField == .email
                    )
                    .focused($focusedField, equals: .email)
                    .onSubmit {
                        focusedField = .password
                    }
                    
                    // Password field
                    EnhancedSecureField(
                        title: "Password",
                        text: $password,
                        placeholder: "Enter your password",
                        showPassword: $showPassword,
                        isFocused: focusedField == .password
                    )
                    .focused($focusedField, equals: .password)
                    .onSubmit {
                        login()
                    }
                    
                    // Forgot password
                    HStack {
                        Spacer()
                        
                        Button("Forgot Password?") {
                            // Handle forgot password
                            Task {
                                await viewModel.requestPasswordReset(email: email)
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 40)
                
                // Error message display
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 40)
                        .multilineTextAlignment(.center)
                }
                
                // Login button
                Button(action: login) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(viewModel.isLoading ? "Signing In..." : "Sign In")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.2))
                    )
                }
                .buttonStyle(EnhancedButtonStyle(style: .ghost))
                .disabled(viewModel.isLoading || !isFormValid)
                .padding(.horizontal, 40)
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                    
                    Text("or")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 8)
                
                // Apple Sign-In button
                AppleSignInButton(onSuccess: {
                    onLoginSuccess()
                })
                .padding(.horizontal, 40)
                
                // Switch to register
                VStack(spacing: 16) {
                    Text("Don't have an account?")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Button("Create Account") {
                        onSwitchToRegister()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                
                Spacer(minLength: 40)
            }
        }
        .onReceive(viewModel.$isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                onLoginSuccess()
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func login() {
        focusedField = nil
        Task {
            await viewModel.loginWithEmail(email: email, password: password)
        }
    }
}

// MARK: - Polished Register View

struct PolishedRegisterView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    let onRegisterSuccess: () -> Void
    let onSwitchToLogin: () -> Void
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @FocusState private var focusedField: RegisterField?
    
    enum RegisterField {
        case name, email, password, confirmPassword
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Text("Create Account")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Join thousands of fitness enthusiasts")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                // Register form
                VStack(spacing: 20) {
                    // Name field
                    EnhancedTextField(
                        title: "Full Name",
                        text: $name,
                        placeholder: "Enter your full name",
                        isFocused: focusedField == .name
                    )
                    .focused($focusedField, equals: .name)
                    .onSubmit {
                        focusedField = .email
                    }
                    
                    // Email field
                    EnhancedTextField(
                        title: "Email",
                        text: $email,
                        placeholder: "Enter your email",
                        keyboardType: .emailAddress,
                        isFocused: focusedField == .email
                    )
                    .focused($focusedField, equals: .email)
                    .onSubmit {
                        focusedField = .password
                    }
                    
                    // Password field
                    EnhancedSecureField(
                        title: "Password",
                        text: $password,
                        placeholder: "Create a password",
                        showPassword: $showPassword,
                        isFocused: focusedField == .password
                    )
                    .focused($focusedField, equals: .password)
                    .onSubmit {
                        focusedField = .confirmPassword
                    }
                    
                    // Confirm password field
                    EnhancedSecureField(
                        title: "Confirm Password",
                        text: $confirmPassword,
                        placeholder: "Confirm your password",
                        showPassword: $showConfirmPassword,
                        isFocused: focusedField == .confirmPassword
                    )
                    .focused($focusedField, equals: .confirmPassword)
                    .onSubmit {
                        register()
                    }
                    
                    // Password validation
                    if !password.isEmpty {
                        PasswordValidationView(password: password)
                    }
                }
                .padding(.horizontal, 40)
                
                // Error message display
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.horizontal, 40)
                        .multilineTextAlignment(.center)
                }
                
                // Register button
                Button(action: register) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(viewModel.isLoading ? "Creating Account..." : "Create Account")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.2))
                    )
                }
                .buttonStyle(EnhancedButtonStyle(style: .ghost))
                .disabled(viewModel.isLoading || !isFormValid)
                .padding(.horizontal, 40)
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                    
                    Text("or")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 8)
                
                // Apple Sign-In button
                AppleSignInButton(onSuccess: {
                    onRegisterSuccess()
                })
                .padding(.horizontal, 40)
                
                // Switch to login
                VStack(spacing: 16) {
                    Text("Already have an account?")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Button("Sign In") {
                        onSwitchToLogin()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                
                Spacer(minLength: 40)
            }
        }
        .onReceive(viewModel.$isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                onRegisterSuccess()
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && 
        !email.isEmpty && 
        email.contains("@") && 
        password.count >= 6 && 
        password == confirmPassword
    }
    
    private func register() {
        focusedField = nil
        Task {
            await viewModel.registerWithEmail(name: name, email: email, password: password)
        }
    }
}

// MARK: - Enhanced Text Field

struct EnhancedTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let isFocused: Bool
    
    init(
        title: String,
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default,
        isFocused: Bool = false
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.isFocused = isFocused
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
            
            TextField(placeholder, text: $text)
                .font(.body)
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isFocused ? Color.white.opacity(0.6) : Color.white.opacity(0.2),
                                    lineWidth: isFocused ? 2 : 1
                                )
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

// MARK: - Enhanced Secure Field

struct EnhancedSecureField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @Binding var showPassword: Bool
    let isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
            
            HStack {
                Group {
                    if showPassword {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .font(.body)
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                
                Button(action: {
                    showPassword.toggle()
                    HapticManager.shared.impact(.light)
                }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused ? Color.white.opacity(0.6) : Color.white.opacity(0.2),
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

// MARK: - Password Validation View

struct PasswordValidationView: View {
    let password: String
    
    private var validations: [(String, Bool)] {
        [
            ("At least 6 characters", password.count >= 6),
            ("Contains a number", password.rangeOfCharacter(from: .decimalDigits) != nil),
            ("Contains uppercase letter", password.rangeOfCharacter(from: .uppercaseLetters) != nil)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password Requirements")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
            
            ForEach(Array(validations.enumerated()), id: \.offset) { index, validation in
                HStack(spacing: 8) {
                    Image(systemName: validation.1 ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12))
                        .foregroundColor(validation.1 ? .green : .white.opacity(0.5))
                    
                    Text(validation.0)
                        .font(.caption)
                        .foregroundColor(validation.1 ? .white : .white.opacity(0.7))
                }
                .animation(.easeInOut(duration: 0.2), value: validation.1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Apple Sign-In Button Component

struct AppleSignInButton: View {
    let onSuccess: () -> Void
    
    @EnvironmentObject var authService: AuthService
    @StateObject private var appleSignInManager = AppleSignInManager()
    @State private var isLoading = false
    
    var body: some View {
        Button(action: {
            handleAppleSignIn()
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "applelogo")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                }
                
                Text(isLoading ? "Signing in with Apple..." : "Continue with Apple")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
        }
        .buttonStyle(EnhancedButtonStyle(style: .ghost))
        .disabled(isLoading)
    }
    
    private func handleAppleSignIn() {
        isLoading = true
        
        Task {
            do {
                // Use existing Apple Sign-In flow
                let appleResult = try await appleSignInManager.startSignInWithAppleFlow()
                
                // Use existing AuthService Apple Sign-In handler with default client role
                await authService.handleAppleSignIn(
                    identityToken: appleResult.identityToken,
                    firstName: appleResult.firstName,
                    lastName: appleResult.lastName,
                    selectedRole: domain.Role.client // Default to client role
                )
                
                // Check if sign-in was successful
                if authService.loggedInUser != nil {
                    await MainActor.run {
                        onSuccess()
                    }
                }
                
            } catch {
                print("Apple Sign-In failed: \(error)")
                // Error handling is managed by AuthService
            }
            
            isLoading = false
        }
    }
}

#Preview {
    PolishedAuthenticationView(authService: AuthService())
        .environmentObject(AppModeManager())
        .environmentObject(ToastManager())
        .environment(\.appTheme, AppTheme.client)
}
