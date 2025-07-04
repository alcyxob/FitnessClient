// EnhancedTabBarView.swift
import SwiftUI

struct EnhancedTabBarView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var appModeManager: AppModeManager
    @Environment(\.appTheme) var theme
    
    @State private var tabBarOffset: CGFloat = 0
    @State private var previousSelectedTab: Int = 0
    @State private var animationProgress: CGFloat = 0
    
    let tabs: [TabItem]
    
    var body: some View {
        ZStack {
            // Tab bar background with blur effect
            tabBarBackground
            
            // Tab items
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    TabBarButton(
                        tab: tab,
                        isSelected: selectedTab == index,
                        animationProgress: selectedTab == index ? 1.0 : 0.0
                    ) {
                        selectTab(index)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            
            // Animated selection indicator
            selectionIndicator
        }
        .frame(height: 88)
        .onChange(of: selectedTab) { newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                previousSelectedTab = newValue
            }
        }
    }
    
    // MARK: - Tab Bar Background
    
    private var tabBarBackground: some View {
        ZStack {
            // Blur background
            Rectangle()
                .fill(.ultraThinMaterial)
                .background(theme.surface.opacity(0.95))
            
            // Top border with gradient
            LinearGradient(
                colors: [theme.primary.opacity(0.3), theme.secondary.opacity(0.2)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)
            .frame(maxHeight: .infinity, alignment: .top)
            
            // Subtle shadow
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.1), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 20)
                .frame(maxHeight: .infinity, alignment: .top)
                .offset(y: -20)
        }
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }
    
    // MARK: - Selection Indicator
    
    private var selectionIndicator: some View {
        GeometryReader { geometry in
            let tabWidth = geometry.size.width / CGFloat(tabs.count)
            let indicatorOffset = tabWidth * CGFloat(selectedTab)
            
            ZStack {
                // Floating indicator background
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [theme.primary, theme.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: tabWidth - 40, height: 4)
                    .offset(x: indicatorOffset + 20, y: -35)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedTab)
                
                // Glow effect
                RoundedRectangle(cornerRadius: 20)
                    .fill(theme.primary.opacity(0.3))
                    .frame(width: tabWidth - 20, height: 8)
                    .blur(radius: 4)
                    .offset(x: indicatorOffset + 10, y: -35)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedTab)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Methods
    
    private func selectTab(_ index: Int) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Selection animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedTab = index
        }
    }
}

// MARK: - Tab Bar Button

struct TabBarButton: View {
    @Environment(\.appTheme) var theme
    
    let tab: TabItem
    let isSelected: Bool
    let animationProgress: CGFloat
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var bounceScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Icon with animation
                ZStack {
                    // Background circle for selected state
                    Circle()
                        .fill(theme.primary.opacity(0.15))
                        .frame(width: 40, height: 40)
                        .scaleEffect(isSelected ? 1.0 : 0.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
                    
                    // Icon
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? theme.primary : theme.secondaryText)
                        .scaleEffect(bounceScale)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                    
                    // Badge (if any)
                    if let badgeCount = tab.badgeCount, badgeCount > 0 {
                        BadgeView(count: badgeCount)
                            .offset(x: 12, y: -12)
                    }
                }
                
                // Label
                Text(tab.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? theme.primary : theme.secondaryText)
                    .scaleEffect(isSelected ? 1.0 : 0.9)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {
            // Long press action
            longPressAction()
        }
        .onChange(of: isSelected) { selected in
            if selected {
                // Bounce animation when selected
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    bounceScale = 1.2
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        bounceScale = 1.0
                    }
                }
            }
        }
    }
    
    private func longPressAction() {
        // Enhanced haptic feedback for long press
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Could show contextual menu or quick actions
        print("Long pressed on \(tab.title)")
    }
}

// MARK: - Badge View

struct BadgeView: View {
    @Environment(\.appTheme) var theme
    let count: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red)
                .frame(width: 18, height: 18)
            
            Text("\(min(count, 99))")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(count > 0 ? 1.0 : 0.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: count)
    }
}

// MARK: - Tab Item Model

struct TabItem {
    let title: String
    let icon: String
    let selectedIcon: String
    let badgeCount: Int?
    
    init(title: String, icon: String, selectedIcon: String? = nil, badgeCount: Int? = nil) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon ?? icon
        self.badgeCount = badgeCount
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    VStack {
        Spacer()
        
        EnhancedTabBarView(
            selectedTab: .constant(0),
            tabs: [
                TabItem(title: "Today", icon: "figure.mixed.cardio", selectedIcon: "figure.mixed.cardio", badgeCount: 2),
                TabItem(title: "Plans", icon: "list.star", selectedIcon: "list.star"),
                TabItem(title: "Progress", icon: "chart.bar.xaxis", selectedIcon: "chart.bar.xaxis"),
                TabItem(title: "Settings", icon: "gearshape", selectedIcon: "gearshape.fill")
            ]
        )
    }
    .background(Color.gray.opacity(0.1))
    .environmentObject(AppModeManager())
    .environment(\.appTheme, AppTheme.client)
}
