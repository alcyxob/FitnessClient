// AdvancedWorkoutBuilderView.swift
import SwiftUI

struct AdvancedWorkoutBuilderView: View {
    let apiService: APIService
    let template: WorkoutTemplate?
    let onWorkoutCreated: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.appTheme) var theme
    
    // Initialize for creating new template
    init(apiService: APIService, onWorkoutCreated: @escaping () -> Void = {}) {
        self.apiService = apiService
        self.template = nil
        self.onWorkoutCreated = onWorkoutCreated
    }
    
    // Initialize for editing existing template
    init(template: WorkoutTemplate, apiService: APIService, onWorkoutCreated: @escaping () -> Void = {}) {
        self.apiService = apiService
        self.template = template
        self.onWorkoutCreated = onWorkoutCreated
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 64))
                        .foregroundColor(theme.primary.opacity(0.6))
                    
                    Text("Advanced Workout Builder")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.primaryText)
                    
                    Text("Coming Soon!")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                    
                    Text("This advanced workout builder will allow you to create and edit workout templates with drag & drop exercise ordering, superset groups, and custom rest periods.")
                        .font(.body)
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Close") {
                        dismiss()
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.primary)
                    )
                }
            }
            .navigationTitle(template != nil ? "Edit Template" : "Create Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
    }
}

#Preview {
    AdvancedWorkoutBuilderView(
        apiService: APIService(authService: AuthService())
    )
    .environment(\.appTheme, AppTheme.trainer)
}
