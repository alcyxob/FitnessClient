// PolishedSettingsView.swift
import SwiftUI

struct PolishedSettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @EnvironmentObject var appModeManager: AppModeManager
    @EnvironmentObject var themeManager: AppThemeManager
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    
    @State private var showingLogoutAlert = false
    @State private var showingThemePreview = false
    @State private var previewMode: AppMode?
    
    init(viewModel: SettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Profile header
                        profileHeaderSection
                        
                        // Settings sections
                        settingsSections
                        
                        // Bottom padding
                        Color.clear.frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await viewModel.logout()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Profile Header Section
    
    private var profileHeaderSection: some View {
        VStack(spacing: 0) {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [theme.gradientStart, theme.gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 20) {
                    // User avatar and info
                    HStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            if let user = viewModel.authService.loggedInUser {
                                Text(user.name.prefix(2).uppercased())
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        // User info
                        VStack(alignment: .leading, spacing: 6) {
                            if let user = viewModel.authService.loggedInUser {
                                Text(user.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                // Role badges
                                HStack(spacing: 8) {
                                    ForEach(user.roles, id: \.self) { role in
                                        RoleBadge(role: role)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Quick stats or actions
                    HStack(spacing: 20) {
                        ProfileStatCard(
                            title: "Active Days",
                            value: "12",
                            icon: "calendar.badge.checkmark"
                        )
                        
                        ProfileStatCard(
                            title: "Workouts",
                            value: "24",
                            icon: "figure.strengthtraining.traditional"
                        )
                        
                        ProfileStatCard(
                            title: "Streak",
                            value: "5",
                            icon: "flame.fill"
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .frame(height: 200)
            
            // Subtle separator
            Rectangle()
                .fill(theme.cardBorder)
                .frame(height: 1)
        }
    }
    
    // MARK: - Settings Sections
    
    private var settingsSections: some View {
        VStack(spacing: 24) {
            // App Role & Theme Section
            appRoleSection
            
            // Offline & Sync Section
            offlineSection
            
            // Preferences Section
            preferencesSection
            
            // Account Section
            accountSection
        }
        .padding(.top, 24)
    }
    
    // MARK: - App Role Section
    
    private var appRoleSection: some View {
        SettingsSection(
            title: "App Experience",
            icon: "paintbrush.pointed.fill",
            iconColor: theme.primary
        ) {
            VStack(spacing: 16) {
                // Current mode display
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Role")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.primaryText)
                        
                        Text(appModeManager.currentMode.displayName)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primary)
                    }
                    
                    Spacer()
                    
                    // Theme color preview
                    HStack(spacing: 4) {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 12, height: 12)
                        Circle()
                            .fill(theme.secondary)
                            .frame(width: 12, height: 12)
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 12, height: 12)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.surface)
                    .cornerRadius(20)
                }
                
                // Role switcher
                HStack(spacing: 12) {
                    ForEach(AppMode.allCases, id: \.self) { mode in
                        RoleSwitchButton(
                            mode: mode,
                            isSelected: appModeManager.currentMode == mode,
                            onTap: {
                                switchToMode(mode)
                            }
                        )
                    }
                }
                
                // Theme preview hint
                if showingThemePreview {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundColor(theme.accent)
                        
                        Text("Theme preview active - tap to confirm")
                            .font(.caption)
                            .foregroundColor(theme.accent)
                            .italic()
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
    }
    
    // MARK: - Offline Section
    
    private var offlineSection: some View {
        SettingsSection(
            title: "Offline & Sync",
            icon: "internaldrive.fill",
            iconColor: theme.secondary
        ) {
            OfflineSettingsSection()
        }
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        SettingsSection(
            title: "Preferences",
            icon: "slider.horizontal.3",
            iconColor: theme.accent
        ) {
            VStack(spacing: 16) {
                // Notifications toggle
                SettingsToggle(
                    title: "Push Notifications",
                    subtitle: "Get notified about new workouts and updates",
                    icon: "bell.fill",
                    isOn: .constant(true)
                ) { _ in
                    // Handle notification toggle
                }
                
                // Haptic feedback toggle
                SettingsToggle(
                    title: "Haptic Feedback",
                    subtitle: "Feel vibrations for button presses and actions",
                    icon: "iphone.radiowaves.left.and.right",
                    isOn: .constant(true)
                ) { _ in
                    // Handle haptic toggle
                }
                
                // Auto-sync toggle
                SettingsToggle(
                    title: "Auto-Sync",
                    subtitle: "Automatically sync data when connected",
                    icon: "arrow.clockwise",
                    isOn: .constant(true)
                ) { _ in
                    // Handle auto-sync toggle
                }
            }
        }
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        SettingsSection(
            title: "Account",
            icon: "person.circle.fill",
            iconColor: .red
        ) {
            VStack(spacing: 12) {
                // Privacy policy
                SettingsActionRow(
                    title: "Privacy Policy",
                    icon: "hand.raised.fill",
                    action: {
                        // Open privacy policy
                    }
                )
                
                // Terms of service
                SettingsActionRow(
                    title: "Terms of Service",
                    icon: "doc.text.fill",
                    action: {
                        // Open terms
                    }
                )
                
                // Sign out
                SettingsActionRow(
                    title: "Sign Out",
                    icon: "rectangle.portrait.and.arrow.right.fill",
                    isDestructive: true,
                    action: {
                        showingLogoutAlert = true
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func switchToMode(_ mode: AppMode) {
        guard appModeManager.currentMode != mode else { return }
        
        // Show preview first
        previewMode = mode
        showingThemePreview = true
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Animate the switch
        withAnimation(.easeInOut(duration: 0.5)) {
            appModeManager.switchTo(mode: mode)
        }
        
        // Show success toast
        let message = "Switched to \(mode.displayName) role"
        toastManager.showToast(style: .success, message: message)
        
        // Hide preview after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showingThemePreview = false
                previewMode = nil
            }
        }
    }
}

// MARK: - Supporting Views

struct RoleBadge: View {
    let role: String
    
    var body: some View {
        Text(role.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SettingsSection<Content: View>: View {
    @Environment(\.appTheme) var theme
    
    let title: String
    let icon: String
    let iconColor: Color
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Section content
            ThemedCard {
                content()
            }
            .padding(.horizontal, 20)
        }
    }
}

struct RoleSwitchButton: View {
    @Environment(\.appTheme) var theme
    
    let mode: AppMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? .white : theme.primary)
                
                Text(mode.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : theme.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.primary : theme.primary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.primary.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsToggle: View {
    @Environment(\.appTheme) var theme
    
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    let onChange: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.primary)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .toggleStyle(CustomToggleStyle())
                .onChange(of: isOn) { newValue in
                    onChange(newValue)
                    
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
        }
        .padding(.vertical, 4)
    }
}

struct CustomToggleStyle: ToggleStyle {
    @Environment(\.appTheme) var theme
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? theme.primary : theme.cardBorder)
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

struct SettingsActionRow: View {
    @Environment(\.appTheme) var theme
    
    let title: String
    let icon: String
    let isDestructive: Bool
    let action: () -> Void
    
    init(title: String, icon: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isDestructive ? .red : theme.primary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isDestructive ? .red : theme.primaryText)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.tertiaryText)
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PolishedSettingsView(
        viewModel: SettingsViewModel(
            apiService: APIService(authService: AuthService()),
            authService: AuthService(),
            appModeManager: AppModeManager()
        )
    )
    .environmentObject(AppModeManager())
    .environmentObject(AppThemeManager(appModeManager: AppModeManager()))
    .environmentObject(ToastManager())
    .environment(\.appTheme, AppTheme.client)
}
