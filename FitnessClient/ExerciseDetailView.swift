// ExerciseDetailView.swift
import SwiftUI
import AVKit

struct ExerciseDetailView: View {
    let exercise: Exercise
    let apiService: APIService
    
    @Environment(\.appTheme) var theme
    @Environment(\.dismiss) var dismiss
    @State private var showingEdit = false
    @State private var showingDeleteConfirmation = false
    @State private var player: AVPlayer?
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    // Header section
                    headerSection
                    
                    // Video section
                    if let videoUrl = exercise.videoUrl, !videoUrl.isEmpty {
                        videoSection(videoUrl)
                    }
                    
                    // Details sections
                    detailsSection
                    
                    // Technique section
                    if let technique = exercise.executionTechnic, !technique.isEmpty {
                        techniqueSection(technique)
                    }
                    
                    // Applicability section
                    if let applicability = exercise.applicability, !applicability.isEmpty {
                        applicabilitySection(applicability)
                    }
                    
                    // Metadata section
                    metadataSection
                    
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(theme.background)
            .navigationTitle("Exercise Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Close") {
                    dismiss()
                }
                .foregroundColor(theme.primary),
                
                trailing: Menu {
                    Button(action: {
                        showingEdit = true
                    }) {
                        Label("Edit Exercise", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        // Duplicate exercise
                    }) {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("Delete Exercise", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(theme.primary)
                }
            )
        }
        .sheet(isPresented: $showingEdit) {
            EditExerciseView(exerciseToEdit: exercise, apiService: apiService)
        }
        .alert("Delete Exercise", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Delete exercise
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete '\(exercise.name)'? This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Exercise icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [muscleGroupColor.opacity(0.2), muscleGroupColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: muscleGroupIcon)
                    .font(.system(size: 40))
                    .foregroundColor(muscleGroupColor)
            }
            
            // Exercise name and basic info
            VStack(spacing: 12) {
                Text(exercise.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    // Muscle group badge
                    if let muscleGroup = exercise.muscleGroup {
                        badgeView(
                            text: muscleGroup.capitalized,
                            icon: "figure.strengthtraining.traditional",
                            color: muscleGroupColor
                        )
                    }
                    
                    // Difficulty badge
                    badgeView(
                        text: exercise.difficulty?.capitalized ?? "Beginner",
                        icon: difficultyIcon,
                        color: difficultyColor
                    )
                }
                
                // Description
                if let description = exercise.description, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Video Section
    
    private func videoSection(_ videoUrl: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Demonstration Video", icon: "play.circle.fill")
            
            if let url = URL(string: videoUrl) {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 200)
                    .cornerRadius(12)
                    .onAppear {
                        self.player = AVPlayer(url: url)
                    }
            } else {
                // Fallback for invalid URL
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.cardBackground)
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                            
                            Text("Invalid video URL")
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryText)
                        }
                    )
            }
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Exercise Details", icon: "info.circle.fill")
            
            VStack(spacing: 12) {
                if let muscleGroup = exercise.muscleGroup {
                    detailRow("Target Muscle Group", value: muscleGroup.capitalized)
                }
                
                detailRow("Difficulty Level", value: exercise.difficulty?.capitalized ?? "Beginner")
                
                if let applicability = exercise.applicability, !applicability.isEmpty {
                    detailRow("Suitable For", value: applicability)
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
    }
    
    // MARK: - Technique Section
    
    private func techniqueSection(_ technique: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Execution Technique", icon: "list.bullet.clipboard.fill")
            
            Text(technique)
                .font(.body)
                .foregroundColor(theme.primaryText)
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
    }
    
    // MARK: - Applicability Section
    
    private func applicabilitySection(_ applicability: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Applicability", icon: "person.2.fill")
            
            Text(applicability)
                .font(.body)
                .foregroundColor(theme.primaryText)
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
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Exercise Information", icon: "calendar.circle.fill")
            
            VStack(spacing: 12) {
                detailRow("Created", value: formatDate(exercise.createdAt))
                detailRow("Last Updated", value: formatDate(exercise.updatedAt))
                detailRow("Exercise ID", value: exercise.id)
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
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(theme.primary)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
        }
    }
    
    private func badgeView(text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
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
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ExerciseDetailView(
        exercise: Exercise(
            id: "preview-1",
            trainerId: "trainer-1",
            name: "Push-ups",
            description: "Classic bodyweight chest exercise that builds upper body strength",
            muscleGroup: "chest",
            executionTechnic: "Start in plank position, lower chest to ground, push back up",
            applicability: "Suitable for all fitness levels",
            difficulty: "beginner",
            videoUrl: "https://example.com/pushups-video",
            createdAt: Date(),
            updatedAt: Date()
        ),
        apiService: APIService(authService: AuthService())
    )
    .environment(\.appTheme, AppTheme.trainer)
}
