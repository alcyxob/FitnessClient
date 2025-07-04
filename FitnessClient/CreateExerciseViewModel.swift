// CreateExerciseViewModel.swift
import Foundation
import SwiftUI

@MainActor
class CreateExerciseViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var exerciseName = ""
    @Published var exerciseDescription = ""
    @Published var selectedMuscleGroup = ""
    @Published var selectedDifficulty = "Beginner"
    @Published var executionTechnique = ""
    @Published var applicability = ""
    @Published var videoUrl = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didCreateSuccessfully = false
    
    // MARK: - Private Properties
    
    private let apiService: APIService
    
    // MARK: - Initialization
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    // MARK: - Exercise Creation
    
    func createExercise() async {
        guard !exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Exercise name is required"
            return
        }
        
        isLoading = true
        errorMessage = nil
        didCreateSuccessfully = false
        
        do {
            let exerciseRequest = CreateExerciseRequest(
                name: exerciseName.trimmingCharacters(in: .whitespacesAndNewlines),
                description: exerciseDescription.isEmpty ? nil : exerciseDescription,
                muscleGroup: selectedMuscleGroup.isEmpty ? nil : selectedMuscleGroup.lowercased(),
                executionTechnic: executionTechnique.isEmpty ? nil : executionTechnique,
                applicability: applicability.isEmpty ? nil : applicability,
                difficulty: selectedDifficulty.lowercased(),
                videoUrl: videoUrl.isEmpty ? nil : videoUrl
            )
            
            let createdExercise: Exercise = try await apiService.POST(
                endpoint: "/exercises",
                body: exerciseRequest
            )
            
            print("CreateExerciseVM: Successfully created exercise: \(createdExercise.name)")
            didCreateSuccessfully = true
            
        } catch {
            print("CreateExerciseVM: Error creating exercise: \(error)")
            
            if let apiError = error as? APINetworkError {
                switch apiError {
                case .serverError(let statusCode, let message):
                    if statusCode == 400 {
                        errorMessage = message ?? "Invalid exercise data. Please check your inputs."
                    } else if statusCode == 409 {
                        errorMessage = message ?? "An exercise with this name already exists."
                    } else {
                        errorMessage = message ?? "Failed to create exercise. Please try again."
                    }
                case .requestFailed:
                    errorMessage = "Network error. Please check your connection and try again."
                case .decodingError:
                    errorMessage = "Failed to process server response. Please try again."
                case .invalidURL:
                    errorMessage = "Invalid request. Please try again."
                case .noData:
                    errorMessage = "No response from server. Please try again."
                case .unauthorized:
                    errorMessage = "Authentication failed. Please log in again."
                case .forbidden:
                    errorMessage = "You don't have permission to create exercises."
                case .unknown(let statusCode):
                    errorMessage = "Server error (\(statusCode)). Please try again."
                }
            } else {
                errorMessage = "Failed to create exercise. Please try again."
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Validation
    
    var isFormValid: Bool {
        !exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Form Reset
    
    func resetForm() {
        exerciseName = ""
        exerciseDescription = ""
        selectedMuscleGroup = ""
        selectedDifficulty = "Beginner"
        executionTechnique = ""
        applicability = ""
        videoUrl = ""
        errorMessage = nil
        didCreateSuccessfully = false
    }
    
    // MARK: - Helper Methods
    
    func validateVideoUrl() -> Bool {
        guard !videoUrl.isEmpty else { return true } // Empty is valid
        
        if let url = URL(string: videoUrl) {
            return url.scheme != nil && url.host != nil
        }
        return false
    }
    
    func formatMuscleGroupForAPI(_ muscleGroup: String) -> String {
        return muscleGroup.lowercased().replacingOccurrences(of: " ", with: "_")
    }
    
    func formatDifficultyForAPI(_ difficulty: String) -> String {
        return difficulty.lowercased()
    }
}
