// WorkoutExecutionViewModel.swift
import Foundation
import SwiftUI

@MainActor
class WorkoutExecutionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var isCompleted = false
    @Published var currentExerciseIndex = 0
    @Published var currentSet = 1
    @Published var isResting = false
    @Published var restTimeRemaining = 0
    @Published var exerciseTimeElapsed = 0
    @Published var totalWorkoutTime = 0
    @Published var errorMessage: String?
    
    // Exercise execution data
    @Published var assignments: [Assignment] = []
    @Published var completedSets: [String: [SetResult]] = [:] // Assignment ID -> Set Results
    @Published var exerciseNotes: [String: String] = [:] // Assignment ID -> Notes
    
    // Timer management
    @Published var restTimer: Timer?
    @Published var workoutTimer: Timer?
    
    // MARK: - Private Properties
    
    private let workout: Workout
    private let apiService: APIService
    
    // MARK: - Computed Properties
    
    var currentAssignment: Assignment? {
        guard currentExerciseIndex < assignments.count else { return nil }
        return assignments[currentExerciseIndex]
    }
    
    var currentExercise: Exercise? {
        // This would be populated when we fetch the assignment details
        return currentAssignment?.exercise
    }
    
    var workoutProgress: Double {
        guard !assignments.isEmpty else { return 0 }
        let completedExercises = assignments.prefix(currentExerciseIndex).count
        let currentExerciseProgress = Double(currentSet - 1) / Double(currentAssignment?.sets ?? 1)
        return (Double(completedExercises) + currentExerciseProgress) / Double(assignments.count)
    }
    
    var totalSets: Int {
        assignments.reduce(0) { total, assignment in
            total + (assignment.sets ?? 1)
        }
    }
    
    var completedSetsCount: Int {
        completedSets.values.reduce(0) { total, sets in
            total + sets.count
        }
    }
    
    // MARK: - Initialization
    
    init(workout: Workout, apiService: APIService) {
        self.workout = workout
        self.apiService = apiService
        
        Task {
            await fetchWorkoutAssignments()
            startWorkoutTimer()
        }
    }
    
    // MARK: - Data Loading
    
    func fetchWorkoutAssignments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch assignments for this workout
            let fetchedAssignments: [Assignment] = try await apiService.GET(
                endpoint: "/client/workouts/\(workout.id)/assignments"
            )
            
            self.assignments = fetchedAssignments
            print("WorkoutExecutionVM: Loaded \(fetchedAssignments.count) assignments for workout")
            
        } catch {
            print("WorkoutExecutionVM: Error fetching assignments: \(error)")
            errorMessage = "Failed to load workout exercises"
            assignments = []
        }
        
        isLoading = false
    }
    
    // MARK: - Timer Management
    
    func startWorkoutTimer() {
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.totalWorkoutTime += 1
                if !self.isResting {
                    self.exerciseTimeElapsed += 1
                }
            }
        }
    }
    
    func startRestTimer(duration: Int = 60) {
        isResting = true
        restTimeRemaining = duration
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.restTimeRemaining -= 1
                
                if self.restTimeRemaining <= 0 {
                    self.stopRestTimer()
                }
            }
        }
    }
    
    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        isResting = false
        restTimeRemaining = 0
    }
    
    func stopAllTimers() {
        workoutTimer?.invalidate()
        restTimer?.invalidate()
        workoutTimer = nil
        restTimer = nil
    }
    
    // MARK: - Exercise Progression
    
    func completeSet(reps: Int, weight: Double? = nil, notes: String? = nil) {
        guard let assignment = currentAssignment else { return }
        
        let setResult = SetResult(
            setNumber: currentSet,
            reps: reps,
            weight: weight,
            notes: notes,
            completedAt: Date()
        )
        
        // Add to completed sets
        if completedSets[assignment.id] == nil {
            completedSets[assignment.id] = []
        }
        completedSets[assignment.id]?.append(setResult)
        
        // Check if exercise is complete
        let targetSets = assignment.sets ?? 1
        if currentSet >= targetSets {
            completeCurrentExercise()
        } else {
            // Move to next set
            currentSet += 1
            
            // Start rest timer if not the last set
            if currentSet <= targetSets {
                let restDuration = parseRestTime(assignment.rest) ?? 60
                startRestTimer(duration: restDuration)
            }
        }
        
        // Haptic feedback
        HapticManager.shared.impact(.medium)
    }
    
    func completeCurrentExercise() {
        guard currentExerciseIndex < assignments.count else { return }
        
        // Save exercise notes if any
        if let assignment = currentAssignment, !exerciseNotes[assignment.id, default: ""].isEmpty {
            // Notes are already stored in exerciseNotes dictionary
        }
        
        // Move to next exercise or complete workout
        if currentExerciseIndex < assignments.count - 1 {
            currentExerciseIndex += 1
            currentSet = 1
            exerciseTimeElapsed = 0
            
            // Start rest between exercises
            startRestTimer(duration: 90) // Longer rest between exercises
        } else {
            completeWorkout()
        }
        
        // Haptic feedback
        HapticManager.shared.impact(.heavy)
    }
    
    func skipCurrentExercise() {
        guard let assignment = currentAssignment else { return }
        
        // Mark as skipped
        let skipResult = SetResult(
            setNumber: 0,
            reps: 0,
            weight: nil,
            notes: "Skipped",
            completedAt: Date()
        )
        
        completedSets[assignment.id] = [skipResult]
        completeCurrentExercise()
    }
    
    func goToPreviousExercise() {
        guard currentExerciseIndex > 0 else { return }
        
        stopRestTimer()
        currentExerciseIndex -= 1
        currentSet = 1
        exerciseTimeElapsed = 0
        
        // Remove completed sets for this exercise if going back
        if currentExerciseIndex < assignments.count {
            let assignment = assignments[currentExerciseIndex]
            completedSets[assignment.id] = []
        }
    }
    
    // MARK: - Workout Completion
    
    func completeWorkout() {
        stopAllTimers()
        isCompleted = true
        
        Task {
            await saveWorkoutResults()
        }
        
        // Celebration haptic
        HapticManager.shared.impact(.heavy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            HapticManager.shared.impact(.heavy)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            HapticManager.shared.impact(.heavy)
        }
    }
    
    private func saveWorkoutResults() async {
        do {
            let workoutSession = WorkoutSessionResult(
                workoutId: workout.id,
                completedAt: Date(),
                totalDuration: totalWorkoutTime,
                assignmentResults: completedSets.compactMap { (assignmentId, setResults) in
                    AssignmentResult(
                        assignmentId: assignmentId,
                        setResults: setResults,
                        notes: exerciseNotes[assignmentId]
                    )
                }
            )
            
            let _: EmptyResponse = try await apiService.POST(
                endpoint: "/client/workout-sessions",
                body: workoutSession
            )
            
            print("WorkoutExecutionVM: Workout results saved successfully")
            
        } catch {
            print("WorkoutExecutionVM: Error saving workout results: \(error)")
            errorMessage = "Failed to save workout results"
        }
    }
    
    // MARK: - Utility Methods
    
    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    func addExerciseNote(_ note: String) {
        guard let assignment = currentAssignment else { return }
        exerciseNotes[assignment.id] = note
    }
    
    func getExerciseNote() -> String {
        guard let assignment = currentAssignment else { return "" }
        return exerciseNotes[assignment.id] ?? ""
    }
    
    func getCompletedSetsForCurrentExercise() -> [SetResult] {
        guard let assignment = currentAssignment else { return [] }
        return completedSets[assignment.id] ?? []
    }
    
    private func parseRestTime(_ restString: String?) -> Int? {
        guard let restString = restString else { return nil }
        
        // Handle different rest time formats
        // e.g., "60", "60s", "1:30", "90 seconds"
        let cleanString = restString.lowercased()
            .replacingOccurrences(of: "seconds", with: "")
            .replacingOccurrences(of: "second", with: "")
            .replacingOccurrences(of: "s", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for minute:second format (e.g., "1:30")
        if cleanString.contains(":") {
            let components = cleanString.components(separatedBy: ":")
            if components.count == 2,
               let minutes = Int(components[0]),
               let seconds = Int(components[1]) {
                return minutes * 60 + seconds
            }
        }
        
        // Simple integer format
        return Int(cleanString)
    }
}

// MARK: - Supporting Models

struct SetResult: Codable, Identifiable {
    let id = UUID()
    let setNumber: Int
    let reps: Int
    let weight: Double?
    let notes: String?
    let completedAt: Date
}

struct AssignmentResult: Codable {
    let assignmentId: String
    let setResults: [SetResult]
    let notes: String?
}

struct WorkoutSessionResult: Codable {
    let workoutId: String
    let completedAt: Date
    let totalDuration: Int // in seconds
    let assignmentResults: [AssignmentResult]
}
