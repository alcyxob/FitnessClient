// AppModeManager.swift
import Foundation
import SwiftUI

enum AppMode {
    case client
    case trainer
}

@MainActor
class AppModeManager: ObservableObject {
    // Use an enum for the current mode for type safety
    
    // The currently selected viewing mode, defaults to client
    @Published var currentMode: AppMode = .client

    func switchTo(mode: AppMode) {
        print("AppModeManager: Switching mode to \(mode)")
        self.currentMode = mode
    }
}
