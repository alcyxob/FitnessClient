// ToastView.swift
import SwiftUI

enum ToastStyle {
    case success
    case error
    case warning
    case info

    var themeColor: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }

    var iconSystemName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct Toast: Equatable { // Equatable for .onChange
    var style: ToastStyle
    var message: String
    var duration: Double = 2.0 // Default duration in seconds
    var id = UUID() // For making it identifiable in .modifier
}

struct ToastView: View {
    let style: ToastStyle
    let message: String
    let onCancel: (() -> Void)? // Optional closure for when toast is tapped

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: style.iconSystemName)
                .foregroundColor(style.themeColor)
            Text(message)
                .font(.caption)
                .foregroundColor(Color(.label)) // Adapts to light/dark mode
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground)) // Adapts
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
        .onTapGesture {
            onCancel?()
        }
    }
}

// View Modifier to present the toast
struct ToastModifier: ViewModifier {
    @Binding var toast: Toast? // Binding to an optional Toast struct
    @State private var workItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it can overlay
            .overlay(
                ZStack { // Use ZStack for alignment
                    if let currentToast = toast {
                        ToastView(style: currentToast.style, message: currentToast.message) {
                            dismissToast() // Allow tapping toast to dismiss
                        }
                        .offset(y: 30) // Position from top, adjust as needed
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity))
                        )
                        .onAppear {
                            scheduleToastDismissal(duration: currentToast.duration)
                        }
                        .onDisappear { // When toast changes (e.g. to nil)
                            workItem?.cancel()
                        }
                    }
                }
                .animation(.spring(), value: toast) // Animate presence of toast
                , alignment: .top // Align toast at the top
            )
            .onChange(of: toast) { newToast in // For iOS 17+: { oldToast, newToast in
                if newToast != nil {
                    scheduleToastDismissal(duration: newToast!.duration)
                }
            }
    }

    private func scheduleToastDismissal(duration: Double) {
        workItem?.cancel() // Cancel any existing dismissal task

        let task = DispatchWorkItem {
            dismissToast()
        }
        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }

    private func dismissToast() {
        withAnimation {
            toast = nil
        }
        workItem?.cancel()
        workItem = nil
    }
}

// View extension for easier usage
extension View {
    func toastView(toast: Binding<Toast?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}

// Preview for ToastView itself
struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ToastView(style: .success, message: "Profile saved successfully!", onCancel: {})
            ToastView(style: .error, message: "Could not connect to server.", onCancel: {})
            ToastView(style: .warning, message: "Low battery warning.", onCancel: {})
            ToastView(style: .info, message: "New update available.", onCancel: {})
        }
        .padding()
    }
}
