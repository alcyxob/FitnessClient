// AppThemeManager.swift
import Foundation
import SwiftUI

// MARK: - App Theme Definition
struct AppTheme: Equatable {
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color
    let surface: Color
    let onPrimary: Color
    let onSecondary: Color
    let success: Color
    let warning: Color
    let error: Color
    
    // Gradient colors
    let gradientStart: Color
    let gradientEnd: Color
    
    // Tab bar colors
    let tabBarBackground: Color
    let tabBarSelected: Color
    let tabBarUnselected: Color
    
    // Card colors
    let cardBackground: Color
    let cardBorder: Color
    
    // Text colors
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    
    // MARK: - Equatable Conformance
    static func == (lhs: AppTheme, rhs: AppTheme) -> Bool {
        // Compare key colors that would indicate a theme change
        return lhs.primary == rhs.primary &&
               lhs.secondary == rhs.secondary &&
               lhs.accent == rhs.accent &&
               lhs.background == rhs.background
    }
}

// MARK: - Predefined Themes
extension AppTheme {
    // Client Theme - Calming blues and greens (wellness/personal focus)
    static let client = AppTheme(
        primary: Color(red: 0.2, green: 0.6, blue: 0.9),        // Bright blue
        secondary: Color(red: 0.3, green: 0.7, blue: 0.5),      // Teal green
        accent: Color(red: 0.1, green: 0.8, blue: 0.6),         // Mint green
        background: Color(red: 0.97, green: 0.98, blue: 1.0),   // Very light blue
        surface: Color.white,
        onPrimary: Color.white,
        onSecondary: Color.white,
        success: Color(red: 0.2, green: 0.8, blue: 0.4),
        warning: Color(red: 1.0, green: 0.8, blue: 0.2),
        error: Color(red: 0.9, green: 0.3, blue: 0.3),
        
        gradientStart: Color(red: 0.2, green: 0.6, blue: 0.9),
        gradientEnd: Color(red: 0.3, green: 0.7, blue: 0.5),
        
        tabBarBackground: Color(red: 0.97, green: 0.98, blue: 1.0),
        tabBarSelected: Color(red: 0.2, green: 0.6, blue: 0.9),
        tabBarUnselected: Color(red: 0.6, green: 0.6, blue: 0.6),
        
        cardBackground: Color.white,
        cardBorder: Color(red: 0.9, green: 0.95, blue: 1.0),
        
        primaryText: Color(red: 0.1, green: 0.1, blue: 0.1),
        secondaryText: Color(red: 0.4, green: 0.4, blue: 0.4),
        tertiaryText: Color(red: 0.6, green: 0.6, blue: 0.6)
    )
    
    // Trainer Theme - Professional oranges and purples (authority/coaching)
    static let trainer = AppTheme(
        primary: Color(red: 0.9, green: 0.5, blue: 0.2),        // Orange
        secondary: Color(red: 0.6, green: 0.3, blue: 0.8),      // Purple
        accent: Color(red: 0.8, green: 0.4, blue: 0.1),         // Dark orange
        background: Color(red: 1.0, green: 0.98, blue: 0.95),   // Warm white
        surface: Color.white,
        onPrimary: Color.white,
        onSecondary: Color.white,
        success: Color(red: 0.2, green: 0.8, blue: 0.4),
        warning: Color(red: 1.0, green: 0.7, blue: 0.1),
        error: Color(red: 0.9, green: 0.3, blue: 0.3),
        
        gradientStart: Color(red: 0.9, green: 0.5, blue: 0.2),
        gradientEnd: Color(red: 0.6, green: 0.3, blue: 0.8),
        
        tabBarBackground: Color(red: 1.0, green: 0.98, blue: 0.95),
        tabBarSelected: Color(red: 0.9, green: 0.5, blue: 0.2),
        tabBarUnselected: Color(red: 0.6, green: 0.6, blue: 0.6),
        
        cardBackground: Color.white,
        cardBorder: Color(red: 1.0, green: 0.95, blue: 0.9),
        
        primaryText: Color(red: 0.1, green: 0.1, blue: 0.1),
        secondaryText: Color(red: 0.4, green: 0.4, blue: 0.4),
        tertiaryText: Color(red: 0.6, green: 0.6, blue: 0.6)
    )
}

// MARK: - Theme Manager
@MainActor
class AppThemeManager: ObservableObject {
    @Published private(set) var currentTheme: AppTheme
    
    private let appModeManager: AppModeManager
    
    init(appModeManager: AppModeManager) {
        self.appModeManager = appModeManager
        
        // Set initial theme based on current mode
        self.currentTheme = appModeManager.currentMode == .client ? .client : .trainer
        
        // Listen for mode changes
        NotificationCenter.default.addObserver(
            forName: .appModeChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let newMode = notification.object as? AppMode {
                self?.updateTheme(for: newMode)
            }
        }
        
        print("AppThemeManager: Initialized with \(appModeManager.currentMode.displayName) theme")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func updateTheme(for mode: AppMode) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = mode == .client ? .client : .trainer
        }
        print("AppThemeManager: Updated to \(mode.displayName) theme")
    }
    
    // MARK: - Convenience Methods
    
    var isClientTheme: Bool {
        return appModeManager.currentMode == .client
    }
    
    var isTrainerTheme: Bool {
        return appModeManager.currentMode == .trainer
    }
    
    func getThemeForMode(_ mode: AppMode) -> AppTheme {
        return mode == .client ? .client : .trainer
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let appModeChanged = Notification.Name("appModeChanged")
}

// MARK: - SwiftUI Environment Key
struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.client
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

// MARK: - View Extensions for Easy Theming
extension View {
    func themedCard() -> some View {
        self
            .background(Color.appCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appCardBorder, lineWidth: 1)
            )
            .cornerRadius(12)
    }
    
    func themedButton(style: ThemedButtonStyle = .primary) -> some View {
        self.buttonStyle(AppThemedButtonStyle(style: style))
    }
    
    func themedNavigationBar() -> some View {
        self.toolbarBackground(Color.appBackground, for: .navigationBar)
    }
}

// MARK: - Color Extensions
extension Color {
    static var appPrimary: Color {
        Color("AppPrimary") // Will fallback to theme if not in assets
    }
    
    static var appSecondary: Color {
        Color("AppSecondary")
    }
    
    static var appAccent: Color {
        Color("AppAccent")
    }
    
    static var appBackground: Color {
        Color("AppBackground")
    }
    
    static var appSurface: Color {
        Color("AppSurface")
    }
    
    static var appCardBackground: Color {
        Color("AppCardBackground")
    }
    
    static var appCardBorder: Color {
        Color("AppCardBorder")
    }
    
    static var appPrimaryText: Color {
        Color("AppPrimaryText")
    }
    
    static var appSecondaryText: Color {
        Color("AppSecondaryText")
    }
}

// MARK: - Themed Button Styles
enum ThemedButtonStyle {
    case primary
    case secondary
    case accent
    case outline
}

struct AppThemedButtonStyle: ButtonStyle {
    @Environment(\.appTheme) var theme
    let style: ThemedButtonStyle
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return theme.primary
        case .secondary:
            return theme.secondary
        case .accent:
            return theme.accent
        case .outline:
            return Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .secondary, .accent:
            return theme.onPrimary
        case .outline:
            return theme.primary
        }
    }
}
