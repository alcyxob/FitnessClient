// ExerciseCardComponents.swift
import SwiftUI

// MARK: - Exercise Grid Card

struct ExerciseGridCard: View {
    let exercise: Exercise
    let apiService: APIService
    
    @Environment(\.appTheme) var theme
    @State private var showingDetail = false
    @State private var showingEdit = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(spacing: 12) {
                // Exercise icon/image
                exerciseIcon
                
                // Exercise info
                VStack(spacing: 6) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    if let muscleGroup = exercise.muscleGroup {
                        Text(muscleGroup.capitalized)
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }
                    
                    difficultyBadge
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            contextMenuItems
        }
        .sheet(isPresented: $showingDetail) {
            ExerciseDetailView(exercise: exercise, apiService: apiService)
        }
        .sheet(isPresented: $showingEdit) {
            EditExerciseView(exerciseToEdit: exercise, apiService: apiService)
        }
    }
    
    private var exerciseIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [muscleGroupColor.opacity(0.2), muscleGroupColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
            
            Image(systemName: muscleGroupIcon)
                .font(.system(size: 24))
                .foregroundColor(muscleGroupColor)
        }
    }
    
    private var difficultyBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: difficultyIcon)
                .font(.system(size: 10))
            
            Text(exercise.difficulty?.capitalized ?? "Beginner")
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
    
    private var contextMenuItems: some View {
        Group {
            Button(action: {
                showingDetail = true
            }) {
                Label("View Details", systemImage: "eye")
            }
            
            Button(action: {
                showingEdit = true
            }) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(action: {
                // Duplicate exercise
            }) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                // Delete exercise
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var muscleGroupColor: Color {
        switch exercise.muscleGroup?.lowercased() {
        case "chest": return .red
        case "back": return .blue
        case "shoulders": return .orange
        case "arms": return .purple
        case "legs": return .green
        case "core": return .yellow
        case "cardio": return .pink
        default: return .gray
        }
    }
    
    private var muscleGroupIcon: String {
        switch exercise.muscleGroup?.lowercased() {
        case "chest": return "figure.strengthtraining.traditional"
        case "back": return "figure.strengthtraining.functional"
        case "shoulders": return "figure.arms.open"
        case "arms": return "figure.flexibility"
        case "legs": return "figure.walk"
        case "core": return "figure.core.training"
        case "cardio": return "heart.fill"
        default: return "dumbbell.fill"
        }
    }
    
    private var difficultyColor: Color {
        switch exercise.difficulty?.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .green
        }
    }
    
    private var difficultyIcon: String {
        switch exercise.difficulty?.lowercased() {
        case "beginner": return "star.fill"
        case "intermediate": return "star.leadinghalf.filled"
        case "advanced": return "star.circle.fill"
        default: return "star.fill"
        }
    }
}

// MARK: - Exercise List Row

struct ExerciseListRow: View {
    let exercise: Exercise
    let apiService: APIService
    
    @Environment(\.appTheme) var theme
    @State private var showingDetail = false
    @State private var showingEdit = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack(spacing: 16) {
                // Exercise icon
                ZStack {
                    Circle()
                        .fill(muscleGroupColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: muscleGroupIcon)
                        .font(.system(size: 20))
                        .foregroundColor(muscleGroupColor)
                }
                
                // Exercise info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                    
                    HStack(spacing: 8) {
                        if let muscleGroup = exercise.muscleGroup {
                            Text(muscleGroup.capitalized)
                                .font(.caption)
                                .foregroundColor(theme.secondaryText)
                        }
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                        
                        Text(exercise.difficulty?.capitalized ?? "Beginner")
                            .font(.caption)
                            .foregroundColor(difficultyColor)
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 8) {
                    Button(action: {
                        showingEdit = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(theme.primary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(theme.primary.opacity(0.1))
                            )
                    }
                    
                    Button(action: {
                        // More actions
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(theme.secondaryText)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(theme.cardBackground)
                            )
                    }
                }
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
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            ExerciseDetailView(exercise: exercise, apiService: apiService)
        }
        .sheet(isPresented: $showingEdit) {
            EditExerciseView(exerciseToEdit: exercise, apiService: apiService)
        }
    }
    
    // MARK: - Computed Properties (same as ExerciseGridCard)
    
    private var muscleGroupColor: Color {
        switch exercise.muscleGroup?.lowercased() {
        case "chest": return .red
        case "back": return .blue
        case "shoulders": return .orange
        case "arms": return .purple
        case "legs": return .green
        case "core": return .yellow
        case "cardio": return .pink
        default: return .gray
        }
    }
    
    private var muscleGroupIcon: String {
        switch exercise.muscleGroup?.lowercased() {
        case "chest": return "figure.strengthtraining.traditional"
        case "back": return "figure.strengthtraining.functional"
        case "shoulders": return "figure.arms.open"
        case "arms": return "figure.flexibility"
        case "legs": return "figure.walk"
        case "core": return "figure.core.training"
        case "cardio": return "heart.fill"
        default: return "dumbbell.fill"
        }
    }
    
    private var difficultyColor: Color {
        switch exercise.difficulty?.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .green
        }
    }
}

// MARK: - Exercise Detail Card

struct ExerciseDetailCard: View {
    let exercise: Exercise
    let apiService: APIService
    
    @Environment(\.appTheme) var theme
    @State private var showingDetail = false
    @State private var showingEdit = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 16) {
                    // Exercise icon
                    ZStack {
                        Circle()
                            .fill(muscleGroupColor.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: muscleGroupIcon)
                            .font(.system(size: 28))
                            .foregroundColor(muscleGroupColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(exercise.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                        
                        HStack(spacing: 8) {
                            if let muscleGroup = exercise.muscleGroup {
                                Text(muscleGroup.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(theme.secondaryText)
                            }
                            
                            difficultyBadge
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingEdit = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(theme.primary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(theme.primary.opacity(0.1))
                            )
                    }
                }
                
                // Description
                if let description = exercise.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                        .lineLimit(3)
                }
                
                // Technique
                if let technique = exercise.executionTechnic, !technique.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Technique")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryText)
                        
                        Text(technique)
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                            .lineLimit(2)
                    }
                }
                
                // Video indicator
                if exercise.videoUrl != nil {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                        
                        Text("Video available")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
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
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            ExerciseDetailView(exercise: exercise, apiService: apiService)
        }
        .sheet(isPresented: $showingEdit) {
            EditExerciseView(exerciseToEdit: exercise, apiService: apiService)
        }
    }
    
    private var difficultyBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: difficultyIcon)
                .font(.system(size: 10))
            
            Text(exercise.difficulty?.capitalized ?? "Beginner")
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
    
    // MARK: - Computed Properties (same as above)
    
    private var muscleGroupColor: Color {
        switch exercise.muscleGroup?.lowercased() {
        case "chest": return .red
        case "back": return .blue
        case "shoulders": return .orange
        case "arms": return .purple
        case "legs": return .green
        case "core": return .yellow
        case "cardio": return .pink
        default: return .gray
        }
    }
    
    private var muscleGroupIcon: String {
        switch exercise.muscleGroup?.lowercased() {
        case "chest": return "figure.strengthtraining.traditional"
        case "back": return "figure.strengthtraining.functional"
        case "shoulders": return "figure.arms.open"
        case "arms": return "figure.flexibility"
        case "legs": return "figure.walk"
        case "core": return "figure.core.training"
        case "cardio": return "heart.fill"
        default: return "dumbbell.fill"
        }
    }
    
    private var difficultyColor: Color {
        switch exercise.difficulty?.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .green
        }
    }
    
    private var difficultyIcon: String {
        switch exercise.difficulty?.lowercased() {
        case "beginner": return "star.fill"
        case "intermediate": return "star.leadinghalf.filled"
        case "advanced": return "star.circle.fill"
        default: return "star.fill"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ExerciseGridCard(
            exercise: Exercise(
                name: "Push-ups",
                description: "Classic bodyweight exercise",
                muscleGroup: "chest",
                difficulty: "beginner"
            ),
            apiService: APIService(authService: AuthService())
        )
        
        ExerciseListRow(
            exercise: Exercise(
                name: "Pull-ups",
                description: "Upper body pulling exercise",
                muscleGroup: "back",
                difficulty: "intermediate"
            ),
            apiService: APIService(authService: AuthService())
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .environment(\.appTheme, AppTheme.trainer)
}
