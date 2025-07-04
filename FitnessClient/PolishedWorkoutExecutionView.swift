// PolishedWorkoutExecutionView.swift
import SwiftUI

struct PolishedWorkoutExecutionView: View {
    let workout: Workout
    
    @StateObject private var viewModel: WorkoutExecutionViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    @Environment(\.dismiss) var dismiss
    
    @State private var showingExitConfirmation = false
    @State private var showingCompletionCelebration = false
    @State private var showConfetti = false
    @State private var celebrationScale = 1.0
    @State private var pulseAnimation = false
    
    // Set tracking inputs
    @State private var repsInput = ""
    @State private var weightInput = ""
    @State private var exerciseNotes = ""
    @State private var showingNotesInput = false
    
    init(workout: Workout, apiService: APIService? = nil) {
        self.workout = workout
        
        // Create APIService with a default AuthService if not provided
        let service = apiService ?? {
            let authService = AuthService()
            return APIService(authService: authService)
        }()
        
        self._viewModel = StateObject(wrappedValue: WorkoutExecutionViewModel(workout: workout, apiService: service))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [theme.gradientStart, theme.gradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.isCompleted {
                completionView
            } else if viewModel.isResting {
                restView
            } else {
                exerciseView
            }
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            viewModel.stopAllTimers()
        }
        .alert("Exit Workout?", isPresented: $showingExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Your progress will be saved, but the workout will be marked as incomplete.")
        }
        .sheet(isPresented: $showingNotesInput) {
            ExerciseNotesView(
                notes: $exerciseNotes,
                onSave: {
                    viewModel.addExerciseNote(exerciseNotes)
                    showingNotesInput = false
                }
            )
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Loading workout...")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Exercise View
    
    private var exerciseView: some View {
        VStack(spacing: 0) {
            // Top bar with progress and exit
            topBar
            
            // Exercise content
            ScrollView {
                VStack(spacing: 24) {
                    // Workout progress ring
                    workoutProgressSection
                    
                    // Current exercise card
                    currentExerciseCard
                    
                    // Set tracking
                    setTrackingSection
                    
                    // Action buttons
                    exerciseActionButtons
                    
                    // Bottom padding
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Exit button
            Button(action: {
                showingExitConfirmation = true
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                    )
            }
            
            Spacer()
            
            // Workout timer
            VStack(spacing: 2) {
                Text("WORKOUT TIME")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(viewModel.formatTime(viewModel.totalWorkoutTime))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
            
            Spacer()
            
            // Exercise navigation
            VStack(spacing: 2) {
                Text("EXERCISE")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("\(viewModel.currentExerciseIndex + 1)/\(viewModel.assignments.count)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Workout Progress Section
    
    private var workoutProgressSection: some View {
        VStack(spacing: 16) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: viewModel.workoutProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.white, Color.white.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: viewModel.workoutProgress)
                
                VStack(spacing: 4) {
                    Text("\(Int(viewModel.workoutProgress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Progress stats
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("\(viewModel.completedSetsCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Sets Done")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                VStack(spacing: 4) {
                    Text("\(viewModel.totalSets)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Total Sets")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                VStack(spacing: 4) {
                    Text(viewModel.formatTime(viewModel.exerciseTimeElapsed))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .monospacedDigit()
                    
                    Text("Exercise Time")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Current Exercise Card
    
    private var currentExerciseCard: some View {
        VStack(spacing: 16) {
            if let assignment = viewModel.currentAssignment {
                exerciseInfoCard(for: assignment)
            } else {
                loadingExerciseCard
            }
        }
    }
    
    private func exerciseInfoCard(for assignment: Assignment) -> some View {
        VStack(spacing: 12) {
            exerciseTitle
            exerciseStatsRow(for: assignment)
        }
        .padding(20)
        .background(exerciseCardBackground)
    }
    
    private var exerciseTitle: some View {
        Text("Exercise \(viewModel.currentExerciseIndex + 1)")
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
    }
    
    private func exerciseStatsRow(for assignment: Assignment) -> some View {
        HStack(spacing: 20) {
            exerciseStatItem(title: "SET", value: "\(viewModel.currentSet)/\(assignment.sets ?? 1)")
            exerciseStatItem(title: "REPS", value: assignment.displayReps)
            exerciseStatItem(title: "WEIGHT", value: assignment.displayWeight)
        }
    }
    
    private func exerciseStatItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
    
    private var exerciseCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var loadingExerciseCard: some View {
        Text("Loading exercise...")
            .font(.headline)
            .foregroundColor(.white.opacity(0.8))
            .padding(20)
    }
    
    // MARK: - Set Tracking Section
    
    private var setTrackingSection: some View {
        VStack(spacing: 16) {
            Text("Log Your Set")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                // Reps input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reps")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    TextField("12", text: $repsInput)
                        .textFieldStyle(WorkoutInputStyle())
                        .keyboardType(.numberPad)
                }
                
                // Weight input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight (lbs)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    TextField("135", text: $weightInput)
                        .textFieldStyle(WorkoutInputStyle())
                        .keyboardType(.decimalPad)
                }
            }
        }
    }
    
    // MARK: - Exercise Action Buttons
    
    private var exerciseActionButtons: some View {
        VStack(spacing: 16) {
            // Complete Set button
            Button(action: {
                completeSet()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                    
                    Text("Complete Set")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(theme.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                )
            }
            .disabled(repsInput.isEmpty)
            .opacity(repsInput.isEmpty ? 0.6 : 1.0)
            
            // Secondary actions
            HStack(spacing: 16) {
                // Add notes
                Button(action: {
                    exerciseNotes = viewModel.getExerciseNote()
                    showingNotesInput = true
                }) {
                    HStack {
                        Image(systemName: "note.text")
                        Text("Notes")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                    )
                }
                
                // Skip exercise
                Button(action: {
                    viewModel.skipCurrentExercise()
                }) {
                    HStack {
                        Image(systemName: "forward.fill")
                        Text("Skip")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                    )
                }
            }
        }
    }
    
    // MARK: - Rest View
    
    private var restView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("Rest Time")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Rest timer
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 12)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.restTimeRemaining) / 60.0)
                        .stroke(.white, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    Text(viewModel.formatTime(viewModel.restTimeRemaining))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .onAppear {
                    pulseAnimation = true
                }
                
                Text("Get ready for your next set!")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Skip rest button
            Button(action: {
                viewModel.stopRestTimer()
            }) {
                Text("Skip Rest")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                    )
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                // Celebration icon
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .scaleEffect(celebrationScale)
                    .onAppear {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            celebrationScale = 1.2
                        }
                        
                        // Trigger confetti
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showConfetti = true
                        }
                    }
                
                Text("Workout Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Great job! You've completed your workout.")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                // Workout stats
                VStack(spacing: 12) {
                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            Text("\(viewModel.totalWorkoutTime / 60)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Minutes")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(viewModel.completedSetsCount)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Sets")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(viewModel.assignments.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Exercises")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
            }
            
            // Done button
            Button(action: {
                dismiss()
            }) {
                Text("Done")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                    )
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    
    private func completeSet() {
        guard let reps = Int(repsInput) else { return }
        let weight = Double(weightInput)
        
        viewModel.completeSet(reps: reps, weight: weight)
        
        // Clear inputs for next set
        repsInput = ""
        weightInput = ""
    }
}

// MARK: - Supporting Views

struct WorkoutInputStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

struct ExerciseNotesView: View {
    @Binding var notes: String
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.appTheme) var theme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Exercise Notes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                
                TextEditor(text: $notes)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.cardBorder, lineWidth: 1)
                    )
                    .frame(minHeight: 120)
                
                Spacer()
            }
            .padding(20)
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                Circle()
                    .fill(Color.random)
                    .frame(width: 8, height: 8)
                    .offset(
                        x: animate ? CGFloat.random(in: -200...200) : 0,
                        y: animate ? CGFloat.random(in: -400...400) : 0
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeOut(duration: 2.0)
                        .delay(Double(index) * 0.02),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

extension Color {
    static var random: Color {
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

#Preview {
    PolishedWorkoutExecutionView(
        workout: Workout(
            id: "1",
            trainingPlanId: "plan1",
            trainerId: "trainer1",
            clientId: "client1",
            name: "Morning Workout",
            dayOfWeek: 1,
            notes: "Great workout!",
            sequence: 1,
            createdAt: Date(),
            updatedAt: Date()
        )
    )
    .environmentObject(ToastManager())
    .environment(\.appTheme, AppTheme.client)
}
