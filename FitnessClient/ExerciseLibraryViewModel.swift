// ExerciseLibraryViewModel.swift
import Foundation
import SwiftUI

@MainActor
class ExerciseLibraryViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var exercises: [Exercise] = []
    @Published var filteredExercises: [Exercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Filter properties
    @Published var searchText = ""
    @Published var selectedCategory = "All"
    @Published var selectedDifficulty = "All Levels"
    
    // MARK: - Private Properties
    
    let apiService: APIService
    
    // MARK: - Computed Properties
    
    var recentlyAddedCount: Int {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return exercises.filter { $0.createdAt > oneWeekAgo }.count
    }
    
    var exercisesByCategory: [String: [Exercise]] {
        Dictionary(grouping: exercises) { exercise in
            exercise.muscleGroup?.capitalized ?? "Other"
        }
    }
    
    var exercisesByDifficulty: [String: [Exercise]] {
        Dictionary(grouping: exercises) { exercise in
            exercise.difficulty?.capitalized ?? "Beginner"
        }
    }
    
    // MARK: - Initialization
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    // MARK: - Data Loading
    
    func loadExercises() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedExercises: [Exercise] = try await apiService.GET(endpoint: "/exercises")
            self.exercises = fetchedExercises.sorted { $0.name < $1.name }
            applyFilters()
            print("ExerciseLibraryVM: Loaded \(fetchedExercises.count) exercises")
        } catch {
            print("ExerciseLibraryVM: Error loading exercises: \(error)")
            errorMessage = "Failed to load exercises"
            // Create mock exercises for development
            self.exercises = createMockExercises()
            applyFilters()
        }
        
        isLoading = false
    }
    
    func refreshExercises() async {
        await loadExercises()
    }
    
    // MARK: - Filtering
    
    func updateSearchText(_ text: String) {
        searchText = text
        applyFilters()
    }
    
    func updateCategoryFilter(_ category: String) {
        selectedCategory = category
        applyFilters()
    }
    
    func updateDifficultyFilter(_ difficulty: String) {
        selectedDifficulty = difficulty
        applyFilters()
    }
    
    private func applyFilters() {
        var filtered = exercises
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.description?.localizedCaseInsensitiveContains(searchText) == true ||
                exercise.muscleGroup?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply category filter
        if selectedCategory != "All" {
            filtered = filtered.filter { exercise in
                let category = mapCategoryToMuscleGroup(selectedCategory)
                return exercise.muscleGroup?.lowercased() == category.lowercased()
            }
        }
        
        // Apply difficulty filter
        if selectedDifficulty != "All Levels" {
            filtered = filtered.filter { exercise in
                exercise.difficulty?.lowercased() == selectedDifficulty.lowercased()
            }
        }
        
        filteredExercises = filtered
    }
    
    private func mapCategoryToMuscleGroup(_ category: String) -> String {
        switch category {
        case "Chest": return "chest"
        case "Back": return "back"
        case "Shoulders": return "shoulders"
        case "Arms": return "arms"
        case "Legs": return "legs"
        case "Core": return "core"
        case "Cardio": return "cardio"
        case "Full Body": return "full body"
        default: return category.lowercased()
        }
    }
    
    // MARK: - Exercise Management
    
    func deleteExercise(_ exercise: Exercise) async {
        do {
            try await apiService.DELETE(endpoint: "/exercises/\(exercise.id)")
            exercises.removeAll { $0.id == exercise.id }
            applyFilters()
            print("ExerciseLibraryVM: Successfully deleted exercise: \(exercise.name)")
        } catch {
            print("ExerciseLibraryVM: Error deleting exercise: \(error)")
            errorMessage = "Failed to delete exercise"
        }
    }
    
    func duplicateExercise(_ exercise: Exercise) async {
        do {
            let duplicateRequest = CreateExerciseRequest(
                name: "\(exercise.name) (Copy)",
                description: exercise.description,
                muscleGroup: exercise.muscleGroup,
                executionTechnic: exercise.executionTechnic,
                applicability: exercise.applicability,
                difficulty: exercise.difficulty,
                videoUrl: exercise.videoUrl
            )
            
            let duplicatedExercise: Exercise = try await apiService.POST(
                endpoint: "/exercises",
                body: duplicateRequest
            )
            
            exercises.append(duplicatedExercise)
            exercises.sort { $0.name < $1.name }
            applyFilters()
            print("ExerciseLibraryVM: Successfully duplicated exercise: \(exercise.name)")
        } catch {
            print("ExerciseLibraryVM: Error duplicating exercise: \(error)")
            errorMessage = "Failed to duplicate exercise"
        }
    }
    
    // MARK: - Statistics
    
    func getExerciseStats() -> ExerciseStats {
        let totalExercises = exercises.count
        let categoryStats = exercisesByCategory.mapValues { $0.count }
        let difficultyStats = exercisesByDifficulty.mapValues { $0.count }
        let recentlyAdded = recentlyAddedCount
        
        return ExerciseStats(
            totalExercises: totalExercises,
            categoryBreakdown: categoryStats,
            difficultyBreakdown: difficultyStats,
            recentlyAdded: recentlyAdded
        )
    }
    
    // MARK: - Mock Data (for development)
    
    private func createMockExercises() -> [Exercise] {
        [
            Exercise(
                id: "1",
                trainerId: "trainer1",
                name: "Push-ups",
                description: "Classic bodyweight chest exercise",
                muscleGroup: "chest",
                executionTechnic: "Keep body straight, lower chest to ground",
                applicability: "Beginner to advanced",
                difficulty: "beginner",
                videoUrl: nil
            ),
            Exercise(
                id: "2",
                trainerId: "trainer1",
                name: "Pull-ups",
                description: "Upper body pulling exercise",
                muscleGroup: "back",
                executionTechnic: "Hang from bar, pull body up until chin over bar",
                applicability: "Intermediate to advanced",
                difficulty: "intermediate",
                videoUrl: nil
            ),
            Exercise(
                id: "3",
                trainerId: "trainer1",
                name: "Squats",
                description: "Fundamental lower body exercise",
                muscleGroup: "legs",
                executionTechnic: "Feet shoulder-width apart, lower hips back and down",
                applicability: "All levels",
                difficulty: "beginner",
                videoUrl: nil
            ),
            Exercise(
                id: "4",
                trainerId: "trainer1",
                name: "Deadlifts",
                description: "Compound full-body exercise",
                muscleGroup: "full body",
                executionTechnic: "Hip hinge movement, keep back straight",
                applicability: "Intermediate to advanced",
                difficulty: "advanced",
                videoUrl: nil
            ),
            Exercise(
                id: "5",
                trainerId: "trainer1",
                name: "Plank",
                description: "Core stability exercise",
                muscleGroup: "core",
                executionTechnic: "Hold straight body position on forearms",
                applicability: "All levels",
                difficulty: "beginner",
                videoUrl: nil
            ),
            Exercise(
                id: "6",
                trainerId: "trainer1",
                name: "Burpees",
                description: "Full-body cardio exercise",
                muscleGroup: "cardio",
                executionTechnic: "Squat, jump back to plank, push-up, jump forward, jump up",
                applicability: "Intermediate to advanced",
                difficulty: "intermediate",
                videoUrl: nil
            ),
            Exercise(
                id: "7",
                trainerId: "trainer1",
                name: "Shoulder Press",
                description: "Overhead pressing movement",
                muscleGroup: "shoulders",
                executionTechnic: "Press weights overhead from shoulder height",
                applicability: "All levels",
                difficulty: "beginner",
                videoUrl: nil
            ),
            Exercise(
                id: "8",
                trainerId: "trainer1",
                name: "Bicep Curls",
                description: "Isolated arm exercise",
                muscleGroup: "arms",
                executionTechnic: "Curl weights up to shoulders, control the descent",
                applicability: "All levels",
                difficulty: "beginner",
                videoUrl: nil
            )
        ]
    }
}

// MARK: - Supporting Models

struct CreateExerciseRequest: Codable {
    let name: String
    let description: String?
    let muscleGroup: String?
    let executionTechnic: String?
    let applicability: String?
    let difficulty: String?
    let videoUrl: String?
}

struct ExerciseStats {
    let totalExercises: Int
    let categoryBreakdown: [String: Int]
    let difficultyBreakdown: [String: Int]
    let recentlyAdded: Int
}
