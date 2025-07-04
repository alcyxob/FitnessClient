// RoleSelectionAndOnboardingViews.swift
import SwiftUI

// MARK: - Polished Role Selection View

struct PolishedRoleSelectionView: View {
    let onRoleSelected: (AppMode) -> Void
    
    @State private var selectedRole: AppMode?
    @State private var cardScale: [AppMode: CGFloat] = [:]
    @State private var showingConfirmation = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Header
            VStack(spacing: 16) {
                Text("Choose Your Role")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Select how you'd like to use FitnessPro")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            
            // Role cards
            VStack(spacing: 24) {
                RoleCard(
                    role: .client,
                    isSelected: selectedRole == .client,
                    scale: cardScale[.client] ?? 1.0
                ) {
                    selectRole(.client)
                }
                
                RoleCard(
                    role: .trainer,
                    isSelected: selectedRole == .trainer,
                    scale: cardScale[.trainer] ?? 1.0
                ) {
                    selectRole(.trainer)
                }
            }
            .padding(.horizontal, 40)
            
            // Continue button
            if selectedRole != nil {
                Button(action: {
                    showingConfirmation = true
                }) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.2))
                        )
                }
                .buttonStyle(EnhancedButtonStyle(style: .ghost))
                .padding(.horizontal, 40)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            Spacer()
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedRole)
        .alert("Confirm Role Selection", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm") {
                if let role = selectedRole {
                    onRoleSelected(role)
                }
            }
        } message: {
            if let role = selectedRole {
                Text("You've selected \(role.displayName). You can change this later in settings.")
            }
        }
    }
    
    private func selectRole(_ role: AppMode) {
        HapticManager.shared.impact(.medium)
        
        // Scale animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            cardScale[role] = 1.05
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                cardScale[role] = 1.0
                selectedRole = role
            }
        }
    }
}

struct RoleCard: View {
    let role: AppMode
    let isSelected: Bool
    let scale: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 20) {
                // Role icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(isSelected ? 0.3 : 0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: role.icon)
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(.white)
                }
                
                // Role info
                VStack(spacing: 8) {
                    Text(role.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(role.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
                // Features list
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(roleFeatures(for: role), id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isSelected ? 0.15 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                Color.white.opacity(isSelected ? 0.6 : 0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(scale)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func roleFeatures(for role: AppMode) -> [String] {
        switch role {
        case .client:
            return [
                "Follow personalized workout plans",
                "Track your progress and achievements",
                "Connect with certified trainers",
                "Access exercise library"
            ]
        case .trainer:
            return [
                "Manage multiple clients",
                "Create custom workout plans",
                "Track client progress",
                "Build exercise library"
            ]
        }
    }
}

// MARK: - Polished Onboarding View

struct PolishedOnboardingView: View {
    let selectedRole: AppMode
    let onComplete: () -> Void
    
    @State private var currentPage = 0
    @State private var pageOffset: CGFloat = 0
    
    private var onboardingPages: [OnboardingPage] {
        switch selectedRole {
        case .client:
            return clientOnboardingPages
        case .trainer:
            return trainerOnboardingPages
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<onboardingPages.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentPage ? Color.white : Color.white.opacity(0.3))
                        .frame(width: index == currentPage ? 24 : 8, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
            .padding(.top, 60)
            .padding(.bottom, 40)
            
            // Pages
            TabView(selection: $currentPage) {
                ForEach(Array(onboardingPages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(maxHeight: .infinity)
            
            // Navigation buttons
            HStack(spacing: 16) {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage -= 1
                        }
                        HapticManager.shared.selection()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                Button(currentPage == onboardingPages.count - 1 ? "Get Started" : "Next") {
                    if currentPage == onboardingPages.count - 1 {
                        onComplete()
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    }
                    HapticManager.shared.impact(.light)
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.2))
                )
                .buttonStyle(EnhancedButtonStyle(style: .ghost))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }
    
    // MARK: - Onboarding Pages Data
    
    private var clientOnboardingPages: [OnboardingPage] {
        [
            OnboardingPage(
                icon: "figure.walk",
                title: "Welcome to Your Fitness Journey",
                subtitle: "Get personalized workout plans designed just for you",
                features: [
                    "Custom workout plans from certified trainers",
                    "Progress tracking and analytics",
                    "Exercise library with video guides"
                ]
            ),
            OnboardingPage(
                icon: "chart.bar.fill",
                title: "Track Your Progress",
                subtitle: "Monitor your achievements and stay motivated",
                features: [
                    "Visual progress charts and statistics",
                    "Achievement badges and milestones",
                    "Weekly and monthly progress reports"
                ]
            ),
            OnboardingPage(
                icon: "person.2.fill",
                title: "Connect with Trainers",
                subtitle: "Get expert guidance from certified professionals",
                features: [
                    "Direct messaging with your trainer",
                    "Real-time feedback on your workouts",
                    "Personalized advice and motivation"
                ]
            )
        ]
    }
    
    private var trainerOnboardingPages: [OnboardingPage] {
        [
            OnboardingPage(
                icon: "person.badge.key.fill",
                title: "Welcome, Trainer!",
                subtitle: "Manage your clients and grow your fitness business",
                features: [
                    "Client management dashboard",
                    "Custom workout plan creation",
                    "Progress tracking for all clients"
                ]
            ),
            OnboardingPage(
                icon: "dumbbell.fill",
                title: "Create Custom Workouts",
                subtitle: "Build personalized plans for each client",
                features: [
                    "Extensive exercise library",
                    "Drag-and-drop workout builder",
                    "Template system for efficiency"
                ]
            ),
            OnboardingPage(
                icon: "chart.line.uptrend.xyaxis",
                title: "Monitor Client Success",
                subtitle: "Track progress and celebrate achievements",
                features: [
                    "Real-time client analytics",
                    "Progress photos and measurements",
                    "Automated progress reports"
                ]
            )
        ]
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let features: [String]
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    @State private var iconScale: CGFloat = 0.8
    @State private var contentOffset: CGFloat = 30
    @State private var featuresOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.white)
            }
            .scaleEffect(iconScale)
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .offset(y: contentOffset)
                
                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .offset(y: contentOffset)
            }
            .padding(.horizontal, 40)
            
            // Features
            VStack(spacing: 12) {
                ForEach(page.features, id: \.self) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                        
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 40)
            .opacity(featuresOpacity)
            
            Spacer()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Icon animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            iconScale = 1.0
        }
        
        // Content animation
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            contentOffset = 0
        }
        
        // Features animation
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            featuresOpacity = 1.0
        }
    }
}

// MARK: - Authentication View Model

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var needsRoleSelection = false
    
    private let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
        
        // Observe AuthService state changes
        authService.$isLoading
            .assign(to: &$isLoading)
        
        authService.$errorMessage
            .assign(to: &$errorMessage)
        
        // Check if user is already authenticated
        if authService.loggedInUser != nil {
            isAuthenticated = true
        }
    }
    
    func loginWithEmail(email: String, password: String) async {
        await authService.loginWithEmail(email: email, password: password)
        
        if authService.loggedInUser != nil {
            isAuthenticated = true
            // Since we default to client role, no role selection needed
            needsRoleSelection = false
        }
    }
    
    func registerWithEmail(name: String, email: String, password: String) async {
        await authService.registerWithEmail(name: name, email: email, password: password)
        
        if authService.loggedInUser != nil {
            isAuthenticated = true
            // New users default to client role, no role selection needed
            needsRoleSelection = false
        }
    }
    
    func requestPasswordReset(email: String) async {
        await authService.requestPasswordReset(email: email)
    }
    
    // Keep existing mock methods for Apple Sign-In compatibility
    func login(email: String, password: String) async {
        await loginWithEmail(email: email, password: password)
    }
    
    func register(name: String, email: String, password: String) async {
        await registerWithEmail(name: name, email: email, password: password)
    }
}

#Preview {
    PolishedRoleSelectionView { role in
        print("Selected role: \(role)")
    }
    .background(
        LinearGradient(
            colors: [Color.green.opacity(0.7), Color.blue.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

#Preview("Onboarding - Client") {
    PolishedOnboardingView(selectedRole: .client) {
        print("Onboarding complete")
    }
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
