// AppModeManager.swift
import Foundation
import SwiftUI

enum AppMode: String, CaseIterable {
    case client = "client"
    case trainer = "trainer"
    
    var displayName: String {
        switch self {
        case .client:
            return "Client"
        case .trainer:
            return "Trainer"
        }
    }
    
    var description: String {
        switch self {
        case .client:
            return "Access your workouts, plans, and progress"
        case .trainer:
            return "Manage clients, create exercises, and assign workouts"
        }
    }
    
    var icon: String {
        switch self {
        case .client:
            return "figure.walk"
        case .trainer:
            return "person.badge.key"
        }
    }
}

@MainActor
class AppModeManager: ObservableObject {
    // UserDefaults key for persisting the selected mode
    private let selectedModeKey = "selectedAppMode"
    
    // The currently selected mode - using private setter to control when saving occurs
    @Published private(set) var currentMode: AppMode
    
    init() {
        // Load the saved mode from UserDefaults directly, default to client if not found
        let savedModeString = UserDefaults.standard.string(forKey: "selectedAppMode")
        
        if let savedModeString = savedModeString,
           let savedMode = AppMode(rawValue: savedModeString) {
            self.currentMode = savedMode
            print("AppModeManager: Initialized with saved mode: \(savedMode.displayName)")
        } else {
            self.currentMode = .client
            print("AppModeManager: No saved mode found, initialized with Client mode")
        }
    }
    
    func switchTo(mode: AppMode) {
        print("AppModeManager: Switching mode from \(currentMode.displayName) to \(mode.displayName)")
        self.currentMode = mode
        saveCurrentMode()
        
        // Notify theme manager about mode change
        NotificationCenter.default.post(
            name: .appModeChanged,
            object: mode
        )
    }
    
    // MARK: - Persistence Methods
    
    private func loadSavedMode() -> AppMode {
        let savedModeString = UserDefaults.standard.string(forKey: selectedModeKey)
        
        if let savedModeString = savedModeString,
           let savedMode = AppMode(rawValue: savedModeString) {
            print("AppModeManager: Loaded saved mode: \(savedMode.displayName)")
            return savedMode
        } else {
            print("AppModeManager: No saved mode found, defaulting to Client")
            return .client
        }
    }
    
    private func saveCurrentMode() {
        UserDefaults.standard.set(currentMode.rawValue, forKey: selectedModeKey)
        print("AppModeManager: Saved mode: \(currentMode.displayName)")
    }
    
    // MARK: - Convenience Methods
    
    var isClientMode: Bool {
        return currentMode == .client
    }
    
    var isTrainerMode: Bool {
        return currentMode == .trainer
    }
    
    func toggleMode() {
        switch currentMode {
        case .client:
            switchTo(mode: .trainer)
        case .trainer:
            switchTo(mode: .client)
        }
    }
    
    // MARK: - Debug Methods
    
    func getCurrentModeInfo() -> String {
        return "Current mode: \(currentMode.displayName), Saved in UserDefaults: \(UserDefaults.standard.string(forKey: selectedModeKey) ?? "none")"
    }
    
    func resetToDefault() {
        UserDefaults.standard.removeObject(forKey: selectedModeKey)
        currentMode = .client
        print("AppModeManager: Reset to default client mode")
    }
}
