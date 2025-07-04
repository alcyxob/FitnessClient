// WorkoutAssignmentViewModel.swift
import Foundation
import SwiftUI

@MainActor
class WorkoutAssignmentViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var recentWorkouts: [Workout] = []
    @Published var trainingPlans: [TrainingPlan] = []
    @Published var availableExercises: [Exercise] = []
    
    // MARK: - Private Properties
    
    private let client: UserResponse
    private let apiService: APIService
    
    // MARK: - Initialization
    
    init(client: UserResponse, apiService: APIService) {
        self.client = client
        self.apiService = apiService
    }
    
    // MARK: - Data Loading
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadRecentWorkouts() }
            group.addTask { await self.loadTrainingPlans() }
            group.addTask { await self.loadAvailableExercises() }
        }
        
        isLoading = false
    }
    
    private func loadRecentWorkouts() async {
        do {
            // Load recent workouts created by this trainer
            let workouts: [Workout] = try await apiService.GET(endpoint: "/trainer/workouts/recent")
            self.recentWorkouts = workouts
            print("WorkoutAssignmentVM: Loaded \(workouts.count) recent workouts")
        } catch {
            print("WorkoutAssignmentVM: Error loading recent workouts: \(error)")
            // Don't set error message for this as it's not critical
        }
    }
    
    private func loadTrainingPlans() async {
        do {
            // Load training plans for this specific client
            let plans: [TrainingPlan] = try await apiService.GET(endpoint: "/trainer/clients/\(client.id)/plans")
            self.trainingPlans = plans
            print("WorkoutAssignmentVM: Loaded \(plans.count) training plans for client \(client.name)")
        } catch {
            print("WorkoutAssignmentVM: Error loading training plans: \(error)")
            // Don't set error message for this as it's not critical
        }
    }
    
    private func loadAvailableExercises() async {
        do {
            // Load trainer's exercise library
            let exercises: [Exercise] = try await apiService.GET(endpoint: "/exercises")
            self.availableExercises = exercises
            print("WorkoutAssignmentVM: Loaded \(exercises.count) available exercises")
        } catch {
            print("WorkoutAssignmentVM: Error loading exercises: \(error)")
            // Don't set error message for this as it's not critical
        }
    }
    
    // MARK: - Quick Template Assignment
    
    func assignQuickTemplate(_ templateName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // First create a training plan for this client if they don't have one
            let planId = try await getOrCreateDefaultPlan()
            
            // Create workout based on template
            let workout = try await createWorkoutFromTemplate(templateName, planId: planId)
            
            // Add exercises to the workout based on template
            try await addExercisesToWorkout(workout.id, templateName: templateName)
            
            print("WorkoutAssignmentVM: Successfully assigned \(templateName) template to \(client.name)")
            
            // Show success and refresh data
            await loadData()
            
        } catch {
            print("WorkoutAssignmentVM: Error assigning template: \(error)")
            errorMessage = "Failed to assign workout template"
        }
        
        isLoading = false
    }
    
    private func getOrCreateDefaultPlan() async throws -> String {
        // Check if client has any training plans
        if let existingPlan = trainingPlans.first {
            return existingPlan.id
        }
        
        // Create a default training plan for this client
        let planRequest = CreateTrainingPlanRequest(
            name: "Personal Training Plan",
            description: "Customized training plan for \(client.name)",
            durationWeeks: 12,
            difficulty: "beginner"
        )
        
        let createdPlan: TrainingPlan = try await apiService.POST(
            endpoint: "/trainer/clients/\(client.id)/plans",
            body: planRequest
        )
        
        trainingPlans.append(createdPlan)
        return createdPlan.id
    }
    
    private func createWorkoutFromTemplate(_ templateName: String, planId: String) async throws -> Workout {
        let workoutRequest = CreateWorkoutRequest(
            name: "\(templateName) Workout",
            notes: "Quick \(templateName.lowercased()) workout template",
            dayOfWeek: nil, // Will be scheduled later
            sequence: 0 // Default sequence since we can't access workouts array
        )
        
        let createdWorkout: Workout = try await apiService.POST(
            endpoint: "/trainer/plans/\(planId)/workouts",
            body: workoutRequest
        )
        
        return createdWorkout
    }
    
    private func addExercisesToWorkout(_ workoutId: String, templateName: String) async throws {
        let templateExercises = getTemplateExercises(templateName)
        
        for (index, exerciseTemplate) in templateExercises.enumerated() {
            // Find matching exercise in trainer's library
            if let exercise = availableExercises.first(where: { $0.name.lowercased().contains(exerciseTemplate.name.lowercased()) }) {
                let assignmentRequest = AssignExerciseRequest(
                    exerciseId: exercise.id,
                    sets: exerciseTemplate.sets,
                    reps: exerciseTemplate.reps,
                    rest: exerciseTemplate.rest,
                    weight: exerciseTemplate.weight,
                    sequence: index
                )
                
                let _: Assignment = try await apiService.POST(
                    endpoint: "/trainer/workouts/\(workoutId)/exercises",
                    body: assignmentRequest
                )
            }
        }
    }
    
    private func getTemplateExercises(_ templateName: String) -> [ExerciseTemplate] {
        switch templateName {
        case "Upper Body":
            return [
                ExerciseTemplate(name: "Push-up", sets: 3, reps: "10-15", rest: "60s", weight: nil),
                ExerciseTemplate(name: "Pull-up", sets: 3, reps: "5-10", rest: "90s", weight: nil),
                ExerciseTemplate(name: "Dip", sets: 3, reps: "8-12", rest: "60s", weight: nil),
                ExerciseTemplate(name: "Plank", sets: 3, reps: "30-60s", rest: "45s", weight: nil)
            ]
        case "Lower Body":
            return [
                ExerciseTemplate(name: "Squat", sets: 3, reps: "12-15", rest: "60s", weight: nil),
                ExerciseTemplate(name: "Lunge", sets: 3, reps: "10 each leg", rest: "60s", weight: nil),
                ExerciseTemplate(name: "Calf Raise", sets: 3, reps: "15-20", rest: "45s", weight: nil),
                ExerciseTemplate(name: "Glute Bridge", sets: 3, reps: "12-15", rest: "45s", weight: nil)
            ]
        case "Cardio":
            return [
                ExerciseTemplate(name: "Jumping Jack", sets: 3, reps: "30s", rest: "30s", weight: nil),
                ExerciseTemplate(name: "High Knee", sets: 3, reps: "30s", rest: "30s", weight: nil),
                ExerciseTemplate(name: "Burpee", sets: 3, reps: "5-10", rest: "60s", weight: nil),
                ExerciseTemplate(name: "Mountain Climber", sets: 3, reps: "30s", rest: "45s", weight: nil)
            ]
        case "Full Body":
            return [
                ExerciseTemplate(name: "Burpee", sets: 3, reps: "8-12", rest: "90s", weight: nil),
                ExerciseTemplate(name: "Mountain Climber", sets: 3, reps: "30s", rest: "60s", weight: nil),
                ExerciseTemplate(name: "Push-up", sets: 3, reps: "10-15", rest: "60s", weight: nil),
                ExerciseTemplate(name: "Squat", sets: 3, reps: "12-15", rest: "60s", weight: nil),
                ExerciseTemplate(name: "Plank", sets: 3, reps: "30-60s", rest: "45s", weight: nil)
            ]
        default:
            return []
        }
    }
    
    // MARK: - Workout Assignment
    
    func assignWorkout(_ workout: Workout) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create a copy of the workout for this client
            let planId = try await getOrCreateDefaultPlan()
            
            let workoutRequest = CreateWorkoutRequest(
                name: workout.name,
                notes: workout.notes,
                dayOfWeek: nil, // Will be scheduled later
                sequence: 0 // Default sequence
            )
            
            let _: Workout = try await apiService.POST(
                endpoint: "/trainer/plans/\(planId)/workouts",
                body: workoutRequest
            )
            
            print("WorkoutAssignmentVM: Successfully assigned workout '\(workout.name)' to \(client.name)")
            
            // Refresh data
            await loadData()
            
        } catch {
            print("WorkoutAssignmentVM: Error assigning workout: \(error)")
            errorMessage = "Failed to assign workout"
        }
        
        isLoading = false
    }
    
    // MARK: - Training Plan Creation
    
    func createTrainingPlan(name: String, description: String, durationWeeks: Int, difficulty: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let planRequest = CreateTrainingPlanRequest(
                name: name,
                description: description,
                durationWeeks: durationWeeks,
                difficulty: difficulty
            )
            
            let createdPlan: TrainingPlan = try await apiService.POST(
                endpoint: "/trainer/clients/\(client.id)/plans",
                body: planRequest
            )
            
            trainingPlans.append(createdPlan)
            print("WorkoutAssignmentVM: Successfully created training plan '\(name)' for \(client.name)")
            
        } catch {
            print("WorkoutAssignmentVM: Error creating training plan: \(error)")
            errorMessage = "Failed to create training plan"
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Models

struct ExerciseTemplate {
    let name: String
    let sets: Int
    let reps: String
    let rest: String
    let weight: String?
}

struct CreateTrainingPlanRequest: Codable {
    let name: String
    let description: String
    let durationWeeks: Int
    let difficulty: String
}

struct CreateWorkoutRequest: Codable {
    let name: String
    let notes: String?
    let dayOfWeek: Int?
    let sequence: Int
}

struct AssignExerciseRequest: Codable {
    let exerciseId: String
    let sets: Int
    let reps: String
    let rest: String
    let weight: String?
    let sequence: Int
}
