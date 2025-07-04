// WorkoutTemplateViewModel.swift
import Foundation
import SwiftUI

@MainActor
class WorkoutTemplateViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var templates: [WorkoutTemplate] = []
    @Published var filteredTemplates: [WorkoutTemplate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Filter properties
    @Published var searchText = ""
    @Published var selectedCategory = "All"
    @Published var selectedDifficulty = "All Levels"
    
    // MARK: - Private Properties
    
    let apiService: APIService
    
    // MARK: - Computed Properties
    
    var recentTemplatesCount: Int {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return templates.filter { $0.createdAt > oneWeekAgo }.count
    }
    
    var templatesByCategory: [String: [WorkoutTemplate]] {
        Dictionary(grouping: templates) { template in
            template.category.capitalized
        }
    }
    
    var templatesByDifficulty: [String: [WorkoutTemplate]] {
        Dictionary(grouping: templates) { template in
            template.difficulty.capitalized
        }
    }
    
    // MARK: - Initialization
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    // MARK: - Data Loading
    
    func loadTemplates() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedTemplates: [WorkoutTemplate] = try await apiService.GET(endpoint: "/workout-templates")
            self.templates = fetchedTemplates.sorted { $0.name < $1.name }
            applyFilters()
            print("WorkoutTemplateVM: Loaded \(fetchedTemplates.count) workout templates")
        } catch {
            print("WorkoutTemplateVM: Error loading templates: \(error)")
            errorMessage = "Failed to load workout templates"
            // Create mock templates for development
            self.templates = createMockTemplates()
            applyFilters()
        }
        
        isLoading = false
    }
    
    func refreshTemplates() async {
        await loadTemplates()
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
        var filtered = templates
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description?.localizedCaseInsensitiveContains(searchText) == true ||
                template.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        if selectedCategory != "All" {
            filtered = filtered.filter { template in
                template.category.lowercased() == selectedCategory.lowercased()
            }
        }
        
        // Apply difficulty filter
        if selectedDifficulty != "All Levels" {
            filtered = filtered.filter { template in
                template.difficulty.lowercased() == selectedDifficulty.lowercased()
            }
        }
        
        filteredTemplates = filtered
    }
    
    // MARK: - Template Management
    
    func deleteTemplate(_ template: WorkoutTemplate) async {
        do {
            try await apiService.DELETE(endpoint: "/workout-templates/\(template.id)")
            templates.removeAll { $0.id == template.id }
            applyFilters()
            print("WorkoutTemplateVM: Successfully deleted template: \(template.name)")
        } catch {
            print("WorkoutTemplateVM: Error deleting template: \(error)")
            errorMessage = "Failed to delete workout template"
        }
    }
    
    func duplicateTemplate(_ template: WorkoutTemplate) async {
        do {
            let duplicateRequest = CreateWorkoutTemplateRequest(
                name: "\(template.name) (Copy)",
                description: template.description,
                category: template.category,
                difficulty: template.difficulty,
                estimatedDuration: template.estimatedDuration,
                exercises: template.exercises
            )
            
            let duplicatedTemplate: WorkoutTemplate = try await apiService.POST(
                endpoint: "/workout-templates",
                body: duplicateRequest
            )
            
            templates.append(duplicatedTemplate)
            templates.sort { $0.name < $1.name }
            applyFilters()
            print("WorkoutTemplateVM: Successfully duplicated template: \(template.name)")
        } catch {
            print("WorkoutTemplateVM: Error duplicating template: \(error)")
            errorMessage = "Failed to duplicate workout template"
        }
    }
    
    // MARK: - Statistics
    
    func getTemplateStats() -> WorkoutTemplateStats {
        let totalTemplates = templates.count
        let categoryStats = templatesByCategory.mapValues { $0.count }
        let difficultyStats = templatesByDifficulty.mapValues { $0.count }
        let recentlyAdded = recentTemplatesCount
        
        return WorkoutTemplateStats(
            totalTemplates: totalTemplates,
            categoryBreakdown: categoryStats,
            difficultyBreakdown: difficultyStats,
            recentlyAdded: recentlyAdded
        )
    }
    
    // MARK: - Mock Data (for development)
    
    private func createMockTemplates() -> [WorkoutTemplate] {
        [
            WorkoutTemplate(
                id: "1",
                trainerId: "trainer1",
                name: "Upper Body Strength",
                description: "Complete upper body workout focusing on major muscle groups",
                category: "strength",
                difficulty: "intermediate",
                estimatedDuration: 45,
                exercises: [
                    WorkoutTemplateExercise(
                        exerciseId: "ex1",
                        exerciseName: "Push-ups",
                        sets: 3,
                        reps: "12-15",
                        rest: "60s",
                        weight: nil,
                        sequence: 1
                    ),
                    WorkoutTemplateExercise(
                        exerciseId: "ex2",
                        exerciseName: "Pull-ups",
                        sets: 3,
                        reps: "8-10",
                        rest: "90s",
                        weight: nil,
                        sequence: 2
                    )
                ]
            ),
            WorkoutTemplate(
                id: "2",
                trainerId: "trainer1",
                name: "HIIT Cardio Blast",
                description: "High-intensity interval training for maximum calorie burn",
                category: "hiit",
                difficulty: "advanced",
                estimatedDuration: 30,
                exercises: [
                    WorkoutTemplateExercise(
                        exerciseId: "ex3",
                        exerciseName: "Burpees",
                        sets: 4,
                        reps: "30s",
                        rest: "30s",
                        weight: nil,
                        sequence: 1
                    ),
                    WorkoutTemplateExercise(
                        exerciseId: "ex4",
                        exerciseName: "Mountain Climbers",
                        sets: 4,
                        reps: "30s",
                        rest: "30s",
                        weight: nil,
                        sequence: 2
                    )
                ]
            ),
            WorkoutTemplate(
                id: "3",
                trainerId: "trainer1",
                name: "Beginner Full Body",
                description: "Perfect introduction to strength training",
                category: "fullbody",
                difficulty: "beginner",
                estimatedDuration: 35,
                exercises: [
                    WorkoutTemplateExercise(
                        exerciseId: "ex5",
                        exerciseName: "Squats",
                        sets: 2,
                        reps: "10-12",
                        rest: "60s",
                        weight: nil,
                        sequence: 1
                    ),
                    WorkoutTemplateExercise(
                        exerciseId: "ex6",
                        exerciseName: "Plank",
                        sets: 2,
                        reps: "30s",
                        rest: "45s",
                        weight: nil,
                        sequence: 2
                    )
                ]
            )
        ]
    }
}

// MARK: - Supporting Models

struct WorkoutTemplate: Codable, Identifiable {
    let id: String
    let trainerId: String
    var name: String
    var description: String?
    var category: String
    var difficulty: String
    var estimatedDuration: Int // in minutes
    var exercises: [WorkoutTemplateExercise]
    let createdAt: Date
    let updatedAt: Date
    
    init(id: String = UUID().uuidString, trainerId: String = "", name: String = "", description: String? = nil, category: String = "", difficulty: String = "beginner", estimatedDuration: Int = 30, exercises: [WorkoutTemplateExercise] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.trainerId = trainerId
        self.name = name
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.estimatedDuration = estimatedDuration
        self.exercises = exercises
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct WorkoutTemplateExercise: Codable, Identifiable {
    let id: String
    let exerciseId: String
    var exerciseName: String
    var sets: Int
    var reps: String
    var rest: String
    var weight: String?
    var sequence: Int
    
    init(id: String = UUID().uuidString, exerciseId: String, exerciseName: String, sets: Int, reps: String, rest: String, weight: String? = nil, sequence: Int) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.sets = sets
        self.reps = reps
        self.rest = rest
        self.weight = weight
        self.sequence = sequence
    }
}

struct CreateWorkoutTemplateRequest: Codable {
    let name: String
    let description: String?
    let category: String
    let difficulty: String
    let estimatedDuration: Int
    let exercises: [WorkoutTemplateExercise]
}

struct WorkoutTemplateStats {
    let totalTemplates: Int
    let categoryBreakdown: [String: Int]
    let difficultyBreakdown: [String: Int]
    let recentlyAdded: Int
}
