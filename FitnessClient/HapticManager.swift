// HapticManager.swift
import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type)
    }
    
    func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}
