// EnhancedUIComponents.swift
import SwiftUI

// MARK: - Enhanced Loading States

struct PulsingLoadingView: View {
    @Environment(\.appTheme) var theme
    @State private var isPulsing = false
    
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .opacity(isPulsing ? 0.3 : 1.0)
                
                Circle()
                    .fill(theme.primary.opacity(0.4))
                    .frame(width: 60, height: 60)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(theme.primary)
            }
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
            
            Text(message)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }
}

struct SkeletonLoadingView: View {
    @Environment(\.appTheme) var theme
    
    let itemCount: Int
    
    init(itemCount: Int = 3) {
        self.itemCount = itemCount
    }
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(0..<itemCount, id: \.self) { _ in
                SkeletonListItem()
            }
        }
        .padding(.horizontal, 20)
        .shimmer()
    }
}

// MARK: - Shimmer Effect

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
                    .clipped()
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

struct SkeletonListItem: View {
    @Environment(\.appTheme) var theme
    
    var body: some View {
        ThemedCard {
            HStack(spacing: 16) {
                // Avatar skeleton
                Circle()
                    .fill(theme.cardBorder)
                    .frame(width: 50, height: 50)
                
                // Content skeleton
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.cardBorder)
                        .frame(height: 16)
                        .frame(maxWidth: .infinity)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.cardBorder)
                        .frame(width: 120, height: 12)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.cardBorder)
                        .frame(width: 80, height: 12)
                }
                
                Spacer()
                
                // Action skeleton
                Circle()
                    .fill(theme.cardBorder)
                    .frame(width: 28, height: 28)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Enhanced Error States

struct EnhancedErrorView: View {
    @Environment(\.appTheme) var theme
    
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Error icon with animation
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.red)
                    .rotationEffect(.degrees(isAnimating ? 5 : -5))
            }
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
            
            // Error text
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Action button
            ThemedButton(actionTitle, style: .primary) {
                action()
            }
            .frame(maxWidth: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .padding(40)
    }
}

struct NetworkErrorView: View {
    @Environment(\.appTheme) var theme
    
    let onRetry: () -> Void
    
    var body: some View {
        EnhancedErrorView(
            title: "Connection Problem",
            message: "We're having trouble connecting to our servers. Please check your internet connection and try again.",
            actionTitle: "Try Again"
        ) {
            onRetry()
        }
    }
}

struct ServerErrorView: View {
    @Environment(\.appTheme) var theme
    
    let onRetry: () -> Void
    
    var body: some View {
        EnhancedErrorView(
            title: "Something Went Wrong",
            message: "We encountered an unexpected error. Our team has been notified and we're working to fix it.",
            actionTitle: "Retry"
        ) {
            onRetry()
        }
    }
}

// MARK: - Enhanced Success States

struct SuccessAnimationView: View {
    @Environment(\.appTheme) var theme
    @State private var showCheckmark = false
    @State private var scale: CGFloat = 0.5
    
    let message: String
    let onDismiss: (() -> Void)?
    
    init(message: String, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(theme.success.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                if showCheckmark {
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(theme.success)
                        .scaleEffect(scale)
                }
            }
            
            Text(message)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surface)
                .shadow(color: theme.primary.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showCheckmark = true
                scale = 1.0
            }
            
            // Auto dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onDismiss?()
            }
        }
    }
}

// MARK: - Enhanced Pull to Refresh

struct CustomRefreshView: View {
    @Environment(\.appTheme) var theme
    @State private var rotation: Double = 0
    
    let isRefreshing: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.primary)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    if isRefreshing {
                        withAnimation(
                            Animation.linear(duration: 1.0)
                                .repeatForever(autoreverses: false)
                        ) {
                            rotation = 360
                        }
                    }
                }
            
            Text(isRefreshing ? "Refreshing..." : "Pull to refresh")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.secondaryText)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Enhanced Buttons

struct FloatingActionButton: View {
    @Environment(\.appTheme) var theme
    
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
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
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {
            action()
        }
    }
}

struct PulseButton: View {
    @Environment(\.appTheme) var theme
    
    let title: String
    let action: () -> Void
    
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.primary, lineWidth: 2)
                                .scaleEffect(isPulsing ? 1.1 : 1.0)
                                .opacity(isPulsing ? 0 : 1)
                        )
                )
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Enhanced Progress Indicators

struct CircularProgressView: View {
    @Environment(\.appTheme) var theme
    
    let progress: Double // 0.0 to 1.0
    let size: CGFloat
    
    init(progress: Double, size: CGFloat = 60) {
        self.progress = progress
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.cardBorder, lineWidth: 4)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [theme.primary, theme.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.2, weight: .bold))
                .foregroundColor(theme.primaryText)
        }
    }
}

struct LinearProgressView: View {
    @Environment(\.appTheme) var theme
    
    let progress: Double // 0.0 to 1.0
    let height: CGFloat
    
    init(progress: Double, height: CGFloat = 8) {
        self.progress = progress
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(theme.cardBorder)
                    .frame(height: height)
                
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [theme.primary, theme.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: height)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: 30) {
        PulsingLoadingView(message: "Loading your workouts...")
        
        CircularProgressView(progress: 0.75)
        
        LinearProgressView(progress: 0.6)
            .frame(height: 8)
        
        FloatingActionButton(icon: "plus") {
            print("FAB tapped")
        }
    }
    .padding()
    .environment(\.appTheme, AppTheme.client)
}
