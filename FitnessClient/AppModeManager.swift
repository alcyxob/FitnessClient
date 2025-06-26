// AppModeManager.swift
import Foundation
import SwiftUI

@MainActor
class AppModeManager: ObservableObject {
    // Use an enum for the current mode for type safety
    enum AppMode {
        case client
        case trainer
    }
    
    // The currently selected viewing mode, defaults to client
    @Published var currentMode: AppMode = .client

    func switchTo(mode: AppMode) {
        print("AppModeManager: Switching mode to \(mode)")
        self.currentMode = mode
    }
}
