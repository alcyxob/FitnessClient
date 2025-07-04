// PolishedCreateExerciseView.swift
import SwiftUI

struct PolishedCreateExerciseView: View {
    @StateObject private var viewModel: CreateExerciseViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    @Environment(\.dismiss) var dismiss
    
    let onExerciseCreated: () -> Void
    
    @State private var showingSuccessAnimation = false
    @State private var pulseAnimation = false
    
    init(apiService: APIService, onExerciseCreated: @escaping () -> Void = {}) {
        self._viewModel = StateObject(wrappedValue: CreateExerciseViewModel(apiService: apiService))
        self.onExerciseCreated = onExerciseCreated
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                
                if showingSuccessAnimation {
                    successView
                } else {
                    mainContent
                }
            }
            .navigationTitle("Create Exercise")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await createExercise()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primary)
                    .disabled(!isFormValid)
                }
            }
        }
        .onChange(of: viewModel.didCreateSuccessfully) { success in
            if success {
                showSuccessAnimation()
            }
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header section
                headerSection
                
                // Basic information
                basicInfoSection
                
                // Exercise details
                exerciseDetailsSection
                
                // Advanced options
                advancedOptionsSection
                
                // Create button
                createExerciseButton
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    errorSection(errorMessage)
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.primary.opacity(0.2), theme.secondary.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(theme.primary)
            }
            
            // Title and description
            VStack(spacing: 8) {
                Text("Create New Exercise")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                
                Text("Add a new exercise to your personal library")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Basic Information", icon: "info.circle")
            
            // Exercise name
            VStack(alignment: .leading, spacing: 8) {
                Text("Exercise Name *")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                TextField("e.g., Push-ups", text: $viewModel.exerciseName)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                TextField("Brief description of the exercise", text: $viewModel.exerciseDescription, axis: .vertical)
                    .textFieldStyle(CustomTextFieldStyle())
                    .lineLimit(3...6)
            }
        }
    }
    
    // MARK: - Exercise Details Section
    
    private var exerciseDetailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Exercise Details", icon: "list.bullet.clipboard")
            
            // Muscle group picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Muscle Group")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Menu {
                    ForEach(muscleGroups, id: \.self) { group in
                        Button(group) {
                            viewModel.selectedMuscleGroup = group
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.selectedMuscleGroup.isEmpty ? "Select muscle group" : viewModel.selectedMuscleGroup)
                            .foregroundColor(viewModel.selectedMuscleGroup.isEmpty ? theme.secondaryText : theme.primaryText)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(theme.secondaryText)
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
            
            // Difficulty picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Difficulty Level")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                HStack(spacing: 12) {
                    ForEach(difficultyLevels, id: \.self) { difficulty in
                        Button(action: {
                            viewModel.selectedDifficulty = difficulty
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: difficultyIcon(difficulty))
                                    .font(.system(size: 14))
                                
                                Text(difficulty)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(viewModel.selectedDifficulty == difficulty ? .white : difficultyColor(difficulty))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(viewModel.selectedDifficulty == difficulty ? difficultyColor(difficulty) : difficultyColor(difficulty).opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(difficultyColor(difficulty).opacity(0.3), lineWidth: viewModel.selectedDifficulty == difficulty ? 0 : 1)
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Advanced Options Section
    
    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Advanced Options", icon: "gearshape")
            
            // Execution technique
            VStack(alignment: .leading, spacing: 8) {
                Text("Execution Technique")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                TextField("How to perform this exercise correctly", text: $viewModel.executionTechnique, axis: .vertical)
                    .textFieldStyle(CustomTextFieldStyle())
                    .lineLimit(3...6)
            }
            
            // Applicability
            VStack(alignment: .leading, spacing: 8) {
                Text("Applicability")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                TextField("Who is this exercise suitable for?", text: $viewModel.applicability)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            
            // Video URL
            VStack(alignment: .leading, spacing: 8) {
                Text("Video URL (Optional)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                TextField("https://example.com/video", text: $viewModel.videoUrl)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }
        }
    }
    
    // MARK: - Create Exercise Button
    
    private var createExerciseButton: some View {
        Button(action: {
            Task { await createExercise() }
        }) {
            HStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(.white)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(viewModel.isLoading ? "Creating Exercise..." : "Create Exercise")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isFormValid ? 
                        LinearGradient(
                            colors: [theme.primary, theme.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .scaleEffect(pulseAnimation ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: pulseAnimation)
        }
        .disabled(!isFormValid)
        .onTapGesture {
            pulseAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pulseAnimation = false
            }
        }
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success animation
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }
                .scaleEffect(showingSuccessAnimation ? 1.0 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSuccessAnimation)
                
                VStack(spacing: 12) {
                    Text("Exercise Created!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(theme.primaryText)
                    
                    Text("Your new exercise has been added to your library")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            Spacer()
            
            // Done button
            Button("Done") {
                onExerciseCreated()
                dismiss()
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green)
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
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
    
    private func errorSection(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    private func createExercise() async {
        await viewModel.createExercise()
    }
    
    private func showSuccessAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingSuccessAnimation = true
        }
        
        // Auto-dismiss after showing success
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onExerciseCreated()
            dismiss()
        }
    }
    
    private var isFormValid: Bool {
        !viewModel.exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Data Arrays
    
    private let muscleGroups = [
        "Chest", "Back", "Shoulders", "Arms", "Legs", "Core", "Cardio", "Full Body"
    ]
    
    private let difficultyLevels = [
        "Beginner", "Intermediate", "Advanced"
    ]
    
    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty {
        case "Beginner": return .green
        case "Intermediate": return .orange
        case "Advanced": return .red
        default: return .green
        }
    }
    
    private func difficultyIcon(_ difficulty: String) -> String {
        switch difficulty {
        case "Beginner": return "star.fill"
        case "Intermediate": return "star.leadinghalf.filled"
        case "Advanced": return "star.circle.fill"
        default: return "star.fill"
        }
    }
}

// MARK: - Custom Text Field Style

struct CustomTextFieldStyle: TextFieldStyle {
    @Environment(\.appTheme) var theme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.body)
            .foregroundColor(theme.primaryText)
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
    PolishedCreateExerciseView(
        apiService: APIService(authService: AuthService())
    )
    .environmentObject(ToastManager())
    .environment(\.appTheme, AppTheme.trainer)
}
