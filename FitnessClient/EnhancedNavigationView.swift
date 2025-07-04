// EnhancedNavigationView.swift
import SwiftUI

struct EnhancedNavigationView<Content: View>: View {
    let content: Content
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @Environment(\.dismiss) var dismiss
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .offset(x: dragOffset.width)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Only allow right swipe (back gesture)
                        if value.translation.width > 0 {
                            isDragging = true
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        
                        if value.translation.width > 100 && value.predictedEndTranslation.width > 200 {
                            // Swipe back gesture completed
                            withAnimation(.easeOut(duration: 0.3)) {
                                dragOffset = CGSize(width: UIScreen.main.bounds.width, height: 0)
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                dismiss()
                            }
                        } else {
                            // Snap back
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
            .background(
                // Dim background during swipe
                Color.black.opacity(isDragging ? 0.1 : 0.0)
                    .animation(.easeInOut(duration: 0.2), value: isDragging)
                    .allowsHitTesting(false)
            )
    }
}

// MARK: - Page Transition Modifier

struct PageTransition: ViewModifier {
    let isActive: Bool
    let direction: TransitionDirection
    
    enum TransitionDirection {
        case leading, trailing, top, bottom
    }
    
    func body(content: Content) -> some View {
        content
            .transition(
                .asymmetric(
                    insertion: insertionTransition,
                    removal: removalTransition
                )
            )
    }
    
    private var insertionTransition: AnyTransition {
        switch direction {
        case .leading:
            return .move(edge: .leading).combined(with: .opacity)
        case .trailing:
            return .move(edge: .trailing).combined(with: .opacity)
        case .top:
            return .move(edge: .top).combined(with: .opacity)
        case .bottom:
            return .move(edge: .bottom).combined(with: .opacity)
        }
    }
    
    private var removalTransition: AnyTransition {
        switch direction {
        case .leading:
            return .move(edge: .trailing).combined(with: .opacity)
        case .trailing:
            return .move(edge: .leading).combined(with: .opacity)
        case .top:
            return .move(edge: .bottom).combined(with: .opacity)
        case .bottom:
            return .move(edge: .top).combined(with: .opacity)
        }
    }
}

extension View {
    func pageTransition(isActive: Bool, direction: PageTransition.TransitionDirection = .trailing) -> some View {
        self.modifier(PageTransition(isActive: isActive, direction: direction))
    }
}

// MARK: - Enhanced Loading States

struct EnhancedLoadingView: View {
    @Environment(\.appTheme) var theme
    let message: String
    
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(theme.primary.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                // Animated ring
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [theme.primary, theme.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: rotationAngle)
                
                // Center dot
                Circle()
                    .fill(theme.primary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseScale)
            }
            .onAppear {
                rotationAngle = 360
                pulseScale = 1.5
            }
            
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }
}

// MARK: - Swipe Action Modifier

struct SwipeActionModifier: ViewModifier {
    let leadingActions: [SwipeAction]
    let trailingActions: [SwipeAction]
    
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var showingActions = false
    
    func body(content: Content) -> some View {
        ZStack {
            // Background actions
            HStack {
                if !leadingActions.isEmpty && offset > 0 {
                    HStack(spacing: 0) {
                        ForEach(leadingActions.indices, id: \.self) { index in
                            SwipeActionButton(action: leadingActions[index])
                                .frame(width: max(0, offset / CGFloat(leadingActions.count)))
                        }
                    }
                }
                
                Spacer()
                
                if !trailingActions.isEmpty && offset < 0 {
                    HStack(spacing: 0) {
                        ForEach(trailingActions.indices, id: \.self) { index in
                            SwipeActionButton(action: trailingActions[index])
                                .frame(width: max(0, -offset / CGFloat(trailingActions.count)))
                        }
                    }
                }
            }
            
            // Main content
            content
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            
                            let translation = value.translation.width
                            let maxOffset: CGFloat = 120
                            
                            if translation > 0 && !leadingActions.isEmpty {
                                offset = min(translation, maxOffset)
                            } else if translation < 0 && !trailingActions.isEmpty {
                                offset = max(translation, -maxOffset)
                            }
                        }
                        .onEnded { value in
                            isDragging = false
                            
                            let velocity = value.predictedEndTranslation.width
                            let threshold: CGFloat = 60
                            
                            if abs(offset) > threshold || abs(velocity) > 200 {
                                // Show actions
                                showingActions = true
                                
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    if offset > 0 {
                                        offset = 80
                                    } else {
                                        offset = -80
                                    }
                                }
                            } else {
                                // Snap back
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    offset = 0
                                }
                                showingActions = false
                            }
                        }
                )
        }
        .clipped()
        .onTapGesture {
            if showingActions {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    offset = 0
                }
                showingActions = false
            }
        }
    }
}

struct SwipeAction {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
}

struct SwipeActionButton: View {
    let action: SwipeAction
    
    var body: some View {
        Button(action: action.action) {
            VStack(spacing: 4) {
                Image(systemName: action.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(action.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(action.color)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension View {
    func swipeActions(
        leading: [SwipeAction] = [],
        trailing: [SwipeAction] = []
    ) -> some View {
        self.modifier(SwipeActionModifier(leadingActions: leading, trailingActions: trailing))
    }
}

// MARK: - Long Press Menu

struct LongPressMenuModifier: ViewModifier {
    let menuItems: [MenuAction]
    @State private var showingMenu = false
    @State private var menuPosition: CGPoint = .zero
    
    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: 0.5) {
                HapticManager.shared.impact(.medium)
                showingMenu = true
            }
            .overlay(
                Group {
                    if showingMenu {
                        LongPressMenu(
                            items: menuItems,
                            position: menuPosition,
                            isShowing: $showingMenu
                        )
                    }
                }
            )
    }
}

struct MenuAction {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
}

struct LongPressMenu: View {
    @Environment(\.appTheme) var theme
    let items: [MenuAction]
    let position: CGPoint
    @Binding var isShowing: Bool
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                Button(action: {
                    items[index].action()
                    dismissMenu()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: items[index].icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(items[index].color)
                            .frame(width: 20)
                        
                        Text(items[index].title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.primaryText)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                
                if index < items.count - 1 {
                    Divider()
                        .background(theme.cardBorder)
                }
            }
        }
        .background(theme.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
        }
        .onTapGesture {
            dismissMenu()
        }
    }
    
    private func dismissMenu() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.8
            opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isShowing = false
        }
    }
}

extension View {
    func longPressMenu(_ items: [MenuAction]) -> some View {
        self.modifier(LongPressMenuModifier(menuItems: items))
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Enhanced Navigation Components")
            .font(.title)
            .padding()
        
        // Example with swipe actions
        Text("Swipe me left or right")
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .swipeActions(
                leading: [
                    SwipeAction(title: "Archive", icon: "archivebox", color: .blue) {
                        print("Archive tapped")
                    }
                ],
                trailing: [
                    SwipeAction(title: "Delete", icon: "trash", color: .red) {
                        print("Delete tapped")
                    }
                ]
            )
        
        // Example with long press menu
        Text("Long press me")
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
            .longPressMenu([
                MenuAction(title: "Edit", icon: "pencil", color: .blue) {
                    print("Edit tapped")
                },
                MenuAction(title: "Share", icon: "square.and.arrow.up", color: .green) {
                    print("Share tapped")
                },
                MenuAction(title: "Delete", icon: "trash", color: .red) {
                    print("Delete tapped")
                }
            ])
        
        Spacer()
    }
    .environment(\.appTheme, AppTheme.client)
}
