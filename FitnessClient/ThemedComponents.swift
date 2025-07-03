// ThemedComponents.swift
import SwiftUI

// MARK: - Role Header Component
struct RoleHeaderView: View {
    @EnvironmentObject var appModeManager: AppModeManager
    @Environment(\.appTheme) var theme
    
    let title: String
    let subtitle: String?
    
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(theme.primaryText)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)
                    }
                }
                
                Spacer()
                
                // Role indicator badge
                RoleBadgeView()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [theme.gradientStart, theme.gradientEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            // Subtle shadow/separator
            Rectangle()
                .fill(theme.cardBorder)
                .frame(height: 1)
        }
    }
}

// MARK: - Role Badge Component
struct RoleBadgeView: View {
    @EnvironmentObject var appModeManager: AppModeManager
    @Environment(\.appTheme) var theme
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: appModeManager.currentMode.icon)
                .font(.system(size: 12, weight: .semibold))
            
            Text(appModeManager.currentMode.displayName)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(theme.onPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.2))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Themed Card Component
struct ThemedCard<Content: View>: View {
    @Environment(\.appTheme) var theme
    
    let content: Content
    let padding: EdgeInsets
    
    init(padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16), @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(theme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.cardBorder, lineWidth: 1)
            )
            .cornerRadius(12)
            .shadow(color: theme.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Themed Button Component
struct ThemedButton: View {
    @Environment(\.appTheme) var theme
    
    let title: String
    let style: ThemedButtonStyle
    let action: () -> Void
    
    init(_ title: String, style: ThemedButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
        }
        .themedButton(style: style)
    }
}

// MARK: - Themed Section Header
struct ThemedSectionHeader: View {
    @Environment(\.appTheme) var theme
    
    let title: String
    let subtitle: String?
    let icon: String?
    
    init(_ title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.primary)
                    .frame(width: 24, height: 24)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Themed List Row
struct ThemedListRow<Content: View>: View {
    @Environment(\.appTheme) var theme
    
    let content: Content
    let showChevron: Bool
    
    init(showChevron: Bool = true, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.showChevron = showChevron
    }
    
    var body: some View {
        HStack {
            content
            
            if showChevron {
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.tertiaryText)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(theme.surface)
        .contentShape(Rectangle())
    }
}

// MARK: - Themed Progress View
struct ThemedProgressView: View {
    @Environment(\.appTheme) var theme
    
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                .scaleEffect(1.2)
            
            Text(message)
                .font(.body)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }
}

// MARK: - Themed Empty State
struct ThemedEmptyState: View {
    @Environment(\.appTheme) var theme
    
    let title: String
    let message: String
    let icon: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        message: String,
        icon: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(theme.primary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                ThemedButton(actionTitle, style: .primary, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }
}

// MARK: - View Extensions
extension View {
    func themedNavigationTitle(_ title: String) -> some View {
        self.navigationTitle(title)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    func themedBackground() -> some View {
        self.background(Color.appBackground)
    }
}
