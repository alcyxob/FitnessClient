// MicroInteractionEnhancements.swift
import SwiftUI

// MARK: - Enhanced Button Styles

struct EnhancedButtonStyle: ButtonStyle {
    let style: ButtonStyleType
    
    enum ButtonStyleType {
        case primary, secondary, destructive, ghost
    }
    
    @Environment(\.appTheme) var theme
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .shadow(
                        color: shadowColor,
                        radius: configuration.isPressed ? 2 : 4,
                        x: 0,
                        y: configuration.isPressed ? 1 : 2
                    )
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        HapticManager.shared.impact(.light)
                    }
            )
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isEnabled ? theme.primary : theme.primary.opacity(0.5)
        case .secondary:
            return isEnabled ? theme.secondary : theme.secondary.opacity(0.5)
        case .destructive:
            return isEnabled ? .red : .red.opacity(0.5)
        case .ghost:
            return Color.clear
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary:
            return theme.primary.opacity(0.3)
        case .secondary:
            return theme.secondary.opacity(0.3)
        case .destructive:
            return Color.red.opacity(0.3)
        case .ghost:
            return Color.clear
        }
    }
}

// MARK: - Enhanced Card Interactions

struct InteractiveCard<Content: View>: View {
    let content: Content
    let onTap: (() -> Void)?
    let onLongPress: (() -> Void)?
    
    @State private var isPressed = false
    @State private var dragOffset: CGSize = .zero
    @Environment(\.appTheme) var theme
    
    init(
        onTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.onTap = onTap
        self.onLongPress = onLongPress
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(
                        color: theme.primary.opacity(0.1),
                        radius: isPressed ? 2 : 8,
                        x: 0,
                        y: isPressed ? 1 : 4
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .offset(dragOffset)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dragOffset)
            .onTapGesture {
                onTap?()
                HapticManager.shared.impact(.light)
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                onLongPress?()
                HapticManager.shared.impact(.medium)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isPressed = true
                        
                        // Subtle drag effect
                        dragOffset = CGSize(
                            width: value.translation.width * 0.1,
                            height: value.translation.height * 0.1
                        )
                    }
                    .onEnded { _ in
                        isPressed = false
                        dragOffset = .zero
                    }
            )
    }
}

// MARK: - Floating Action Button with Enhanced Interactions

struct EnhancedFloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @Environment(\.appTheme) var theme
    
    var body: some View {
        Button(action: {
            action()
            triggerAnimation()
        }) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.primary, theme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(
                    color: theme.primary.opacity(0.4),
                    radius: isPressed ? 8 : 12,
                    x: 0,
                    y: isPressed ? 4 : 8
                )
                .scaleEffect(isPressed ? 0.95 : pulseScale)
                .rotationEffect(.degrees(rotationAngle))
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {
            // Long press completed
        }
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private func triggerAnimation() {
        HapticManager.shared.impact(.medium)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            rotationAngle += 180
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            rotationAngle = 0
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }
    }
}

// MARK: - Enhanced List Row with Interactions

struct EnhancedListRow<Content: View>: View {
    let content: Content
    let leadingActions: [SwipeAction]
    let trailingActions: [SwipeAction]
    let onTap: (() -> Void)?
    
    @State private var isHighlighted = false
    @Environment(\.appTheme) var theme
    
    init(
        leadingActions: [SwipeAction] = [],
        trailingActions: [SwipeAction] = [],
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.leadingActions = leadingActions
        self.trailingActions = trailingActions
        self.onTap = onTap
    }
    
    var body: some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHighlighted ? theme.primary.opacity(0.05) : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: isHighlighted)
            )
            .swipeActions(leading: leadingActions, trailing: trailingActions)
            .onTapGesture {
                onTap?()
                HapticManager.shared.selection()
            }
            .onLongPressGesture(minimumDuration: 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isHighlighted = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHighlighted = false
                    }
                }
            }
    }
}

// MARK: - Enhanced Toggle with Animations

struct EnhancedToggle: View {
    @Binding var isOn: Bool
    let title: String
    let subtitle: String?
    
    @State private var bounceScale: CGFloat = 1.0
    @Environment(\.appTheme) var theme
    
    init(_ title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
            }
            
            Spacer()
            
            Button(action: {
                toggleWithAnimation()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isOn ? theme.primary : theme.cardBorder)
                        .frame(width: 50, height: 30)
                        .animation(.easeInOut(duration: 0.2), value: isOn)
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                        .offset(x: isOn ? 10 : -10)
                        .scaleEffect(bounceScale)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
                        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: bounceScale)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func toggleWithAnimation() {
        HapticManager.shared.impact(.light)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isOn.toggle()
        }
        
        // Bounce animation
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            bounceScale = 1.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                bounceScale = 1.0
            }
        }
    }
}

// MARK: - Enhanced Progress Ring with Animations

struct AnimatedProgressRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    
    @State private var animatedProgress: Double = 0
    @Environment(\.appTheme) var theme
    
    init(progress: Double, size: CGFloat = 60, lineWidth: CGFloat = 6) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(theme.cardBorder, lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [theme.primary, theme.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            
            // Progress text
            Text("\(Int(animatedProgress * 100))%")
                .font(.system(size: size * 0.2, weight: .bold))
                .foregroundColor(theme.primaryText)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Enhanced Search Bar

struct EnhancedSearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSearchButtonClicked: (() -> Void)?
    
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    @Environment(\.appTheme) var theme
    
    init(
        text: Binding<String>,
        placeholder: String = "Search...",
        onSearchButtonClicked: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSearchButtonClicked = onSearchButtonClicked
    }
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.secondaryText)
                    .scaleEffect(isFocused ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                TextField(placeholder, text: $text)
                    .font(.body)
                    .foregroundColor(theme.primaryText)
                    .focused($isFocused)
                    .onSubmit {
                        onSearchButtonClicked?()
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            text = ""
                        }
                        HapticManager.shared.impact(.light)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(theme.secondaryText)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused ? theme.primary : theme.cardBorder,
                        lineWidth: isFocused ? 2 : 1
                    )
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
            .cornerRadius(12)
            
            if isFocused {
                Button("Cancel") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        text = ""
                        isFocused = false
                    }
                    HapticManager.shared.selection()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.primary)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    VStack(spacing: 30) {
        Text("Enhanced Micro-Interactions")
            .font(.title)
            .fontWeight(.bold)
        
        // Enhanced button
        Button("Primary Button") {
            print("Button tapped")
        }
        .buttonStyle(EnhancedButtonStyle(style: .primary))
        .padding(.horizontal, 20)
        
        // Enhanced toggle
        EnhancedToggle(
            "Enable Notifications",
            subtitle: "Get notified about new workouts",
            isOn: .constant(true)
        )
        .padding(.horizontal, 20)
        
        // Enhanced progress ring
        AnimatedProgressRing(progress: 0.75, size: 80)
        
        // Enhanced search bar
        EnhancedSearchBar(
            text: .constant(""),
            placeholder: "Search workouts..."
        )
        .padding(.horizontal, 20)
        
        // Enhanced FAB
        EnhancedFloatingActionButton(icon: "plus") {
            print("FAB tapped")
        }
        
        Spacer()
    }
    .padding()
    .environment(\.appTheme, AppTheme.client)
}
