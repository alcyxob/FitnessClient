// WorkoutTemplateCard.swift
import SwiftUI

struct WorkoutTemplateCard: View {
    let template: WorkoutTemplate
    let apiService: APIService
    
    @Environment(\.appTheme) var theme
    @State private var showingDetail = false
    @State private var showingEdit = false
    @State private var showingUseTemplate = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 16) {
                    // Category icon
                    ZStack {
                        Circle()
                            .fill(categoryColor.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: categoryIcon)
                            .font(.system(size: 24))
                            .foregroundColor(categoryColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(template.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                            .lineLimit(2)
                        
                        HStack(spacing: 8) {
                            categoryBadge
                            difficultyBadge
                        }
                        
                        HStack(spacing: 12) {
                            durationInfo
                            exerciseCountInfo
                        }
                    }
                    
                    Spacer()
                    
                    // Use template button
                    Button(action: {
                        showingUseTemplate = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(theme.primary)
                    }
                    .buttonStyle(.plain)
                }
                
                // Description
                if let description = template.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                        .lineLimit(3)
                }
                
                // Exercise preview
                exercisePreview
                
                // Action buttons
                actionButtons
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            WorkoutTemplateDetailView(template: template, apiService: apiService)
        }
        .sheet(isPresented: $showingEdit) {
            AdvancedWorkoutBuilderView(template: template, apiService: apiService) {
                // Refresh callback
            }
        }
        .sheet(isPresented: $showingUseTemplate) {
            UseWorkoutTemplateView(template: template, apiService: apiService)
        }
    }
    
    // MARK: - Components
    
    private var categoryBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: categoryIcon)
                .font(.system(size: 10))
            
            Text(template.category.capitalized)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(categoryColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(categoryColor.opacity(0.1))
        )
    }
    
    private var difficultyBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: difficultyIcon)
                .font(.system(size: 10))
            
            Text(template.difficulty.capitalized)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(difficultyColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(difficultyColor.opacity(0.1))
        )
    }
    
    private var durationInfo: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.system(size: 12))
                .foregroundColor(theme.secondaryText)
            
            Text("\(template.estimatedDuration)m")
                .font(.caption)
                .foregroundColor(theme.secondaryText)
        }
    }
    
    private var exerciseCountInfo: some View {
        HStack(spacing: 4) {
            Image(systemName: "list.bullet")
                .font(.system(size: 12))
                .foregroundColor(theme.secondaryText)
            
            Text("\(template.exercises.count) exercises")
                .font(.caption)
                .foregroundColor(theme.secondaryText)
        }
    }
    
    private var exercisePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exercises")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            LazyVStack(spacing: 6) {
                ForEach(template.exercises.prefix(3)) { exercise in
                    HStack(spacing: 8) {
                        Text("\(exercise.sequence).")
                            .font(.caption2)
                            .foregroundColor(theme.secondaryText)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(exercise.exerciseName)
                            .font(.caption)
                            .foregroundColor(theme.primaryText)
                        
                        Spacer()
                        
                        Text("\(exercise.sets) × \(exercise.reps)")
                            .font(.caption2)
                            .foregroundColor(theme.secondaryText)
                    }
                }
                
                if template.exercises.count > 3 {
                    HStack {
                        Text("...")
                            .font(.caption2)
                            .foregroundColor(theme.secondaryText)
                            .frame(width: 20, alignment: .leading)
                        
                        Text("and \(template.exercises.count - 3) more exercises")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.cardBackground.opacity(0.5))
        )
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                showingUseTemplate = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14))
                    
                    Text("Use Template")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.primary)
                )
            }
            
            Button(action: {
                showingEdit = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                    
                    Text("Edit")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(theme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.primary.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                )
            }
            
            Spacer()
            
            Button(action: {
                // Share template
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16))
                    .foregroundColor(theme.secondaryText)
            }
            
            Button(action: {
                // More options
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(theme.secondaryText)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var categoryColor: Color {
        switch template.category.lowercased() {
        case "strength": return .red
        case "cardio": return .pink
        case "hiit": return .orange
        case "flexibility": return .green
        case "fullbody", "full body": return .purple
        case "upperbody", "upper body": return .blue
        case "lowerbody", "lower body": return .indigo
        case "core": return .yellow
        default: return .gray
        }
    }
    
    private var categoryIcon: String {
        switch template.category.lowercased() {
        case "strength": return "dumbbell.fill"
        case "cardio": return "heart.fill"
        case "hiit": return "bolt.fill"
        case "flexibility": return "figure.flexibility"
        case "fullbody", "full body": return "figure.run"
        case "upperbody", "upper body": return "figure.strengthtraining.traditional"
        case "lowerbody", "lower body": return "figure.walk"
        case "core": return "figure.core.training"
        default: return "list.bullet"
        }
    }
    
    private var difficultyColor: Color {
        switch template.difficulty.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .green
        }
    }
    
    private var difficultyIcon: String {
        switch template.difficulty.lowercased() {
        case "beginner": return "star.fill"
        case "intermediate": return "star.leadinghalf.filled"
        case "advanced": return "star.circle.fill"
        default: return "star.fill"
        }
    }
}

#Preview {
    WorkoutTemplateCard(
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
    .padding()
    .background(Color.gray.opacity(0.1))
    .environment(\.appTheme, AppTheme.trainer)
}
