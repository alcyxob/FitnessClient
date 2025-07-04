// WorkoutTemplateDetailView.swift
import SwiftUI

struct WorkoutTemplateDetailView: View {
    let template: WorkoutTemplate
    let apiService: APIService
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.appTheme) var theme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 16) {
                        Text(template.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                        
                        if let description = template.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(theme.secondaryText)
                        }
                        
                        HStack(spacing: 16) {
                            templateInfoBadge("Category", template.category.capitalized)
                            templateInfoBadge("Difficulty", template.difficulty.capitalized)
                            templateInfoBadge("Duration", "\(template.estimatedDuration)m")
                        }
                    }
                    
                    // Exercises
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Exercises (\(template.exercises.count))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryText)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(template.exercises.sorted(by: { $0.sequence < $1.sequence })) { exercise in
                                exerciseRow(exercise)
                            }
                        }
                    }
                    
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(theme.background)
            .navigationTitle("Template Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Use Template") {
                        // Use template action
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
    }
    
    private func templateInfoBadge(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
    }
    
    private func exerciseRow(_ exercise: WorkoutTemplateExercise) -> some View {
        HStack(spacing: 16) {
            Text("\(exercise.sequence)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(theme.primary)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(theme.primary.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                HStack(spacing: 12) {
                    Text("\(exercise.sets) sets")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                    
                    Text(exercise.reps)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                    
                    Text("Rest: \(exercise.rest)")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                    
                    if let weight = exercise.weight {
                        Text("Weight: \(weight)")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
    }
}

#Preview {
    WorkoutTemplateDetailView(
        template: WorkoutTemplate(
            name: "Upper Body Strength",
            description: "Complete upper body workout focusing on major muscle groups",
            category: "strength",
            difficulty: "intermediate",
            estimatedDuration: 45,
            exercises: [
                WorkoutTemplateExercise(
                    exerciseId: "1",
                    exerciseName: "Push-ups",
                    sets: 3,
                    reps: "12-15",
                    rest: "60s",
                    sequence: 1
                ),
                WorkoutTemplateExercise(
                    exerciseId: "2",
                    exerciseName: "Pull-ups",
                    sets: 3,
                    reps: "8-10",
                    rest: "90s",
                    sequence: 2
                )
            ]
        ),
        apiService: APIService(authService: AuthService())
    )
    .environment(\.appTheme, AppTheme.trainer)
}
