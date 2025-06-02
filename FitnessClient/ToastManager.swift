// ToastManager.swift
import SwiftUI

@MainActor
class ToastManager: ObservableObject {
    @Published var currentToast: Toast? = nil

    func showToast(style: ToastStyle, message: String, duration: Double = 2.5) {
        // Ensure new toast replaces old one and animation triggers
        currentToast = nil // Set to nil first to help with re-triggering animation if message is same
        DispatchQueue.main.async { // Ensure it's on main thread for next run loop
            self.currentToast = Toast(style: style, message: message, duration: duration)
        }
    }
}
