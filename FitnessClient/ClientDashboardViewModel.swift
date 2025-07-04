// ClientDashboardViewModel.swift
import Foundation
import SwiftUI

@MainActor
class ClientDashboardViewModel: ObservableObject {
    @Published var todaysWorkouts: [Workout] = [] // Can be multiple if scheduled
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var greeting: String = "" // For a personalized greeting

    private let apiService: APIService
    private let authService: AuthService // To get client's name for greeting

    let daysOfWeek = ["Not Set", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    init(apiService: APIService, authService: AuthService) {
        self.apiService = apiService
        self.authService = authService
        print("ClientDashboardViewModel: Initialized.")
        updateGreeting()
    }

    func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        if let clientName = authService.loggedInUser?.name.components(separatedBy: " ").first { // Get first name
            switch hour {
            case 0..<12: greeting = "Good Morning, \(clientName)!"
            case 12..<18: greeting = "Good Afternoon, \(clientName)!"
            default: greeting = "Good Evening, \(clientName)!"
            }
        } else {
            greeting = "Welcome!"
        }
    }

    func fetchTodaysWorkouts() async {
        print("ClientDashboardVM: Fetching today's workout(s)...")
        isLoading = true
        errorMessage = nil
        // todaysWorkouts = [] // Optional: Clear or show stale data

        // Client ID is implicit in the token used by APIService
        let endpoint = "/client/workouts/today"

        do {
            let fetchedWorkouts: [Workout] = try await apiService.GET(endpoint: endpoint)
            self.todaysWorkouts = fetchedWorkouts // Already sorted by sequence from backend/ViewModel if needed
            print("ClientDashboardVM: Successfully fetched \(fetchedWorkouts.count) workout(s) for today.")
            if fetchedWorkouts.isEmpty {
                // Don't set errorMessage here if it's just "no workout today",
                // the view will handle the empty state.
                // self.errorMessage = "No workout scheduled for today."
            }
        } catch let error as APINetworkError {
            self.errorMessage = error.localizedDescription
            print("ClientDashboardVM: Error fetching today's workouts (APINetworkError): \(error.localizedDescription)")
            self.todaysWorkouts = []
        } catch {
            self.errorMessage = "An unexpected error occurred while fetching today's schedule."
            print("ClientDashboardVM: Unexpected error fetching today's workouts: \(error.localizedDescription)")
            self.todaysWorkouts = []
        }
        isLoading = false
        print("ClientDashboardVM: fetchTodaysWorkouts finished. isLoading: \(isLoading), Count: \(todaysWorkouts.count), Error: \(errorMessage ?? "None")")
    }
    
    // MARK: - Additional Data Fetching
    
    @Published var recentActivity: [WorkoutSession] = []
    @Published var progressStats: ProgressStats?
    
    func fetchRecentActivity() async {
        print("ClientDashboardVM: Fetching recent activity...")
        
        do {
            let sessions: [WorkoutSession] = try await apiService.GET(endpoint: "/client/workout-sessions/recent")
            self.recentActivity = sessions
            print("ClientDashboardVM: Successfully fetched \(sessions.count) recent activities.")
        } catch {
            print("ClientDashboardVM: Error fetching recent activity: \(error)")
            self.recentActivity = []
        }
    }
    
    func fetchProgressStats() async {
        print("ClientDashboardVM: Fetching progress stats...")
        
        do {
            let stats: ProgressStats = try await apiService.GET(endpoint: "/client/progress/stats")
            self.progressStats = stats
            print("ClientDashboardVM: Successfully fetched progress stats.")
        } catch {
            print("ClientDashboardVM: Error fetching progress stats: \(error)")
            self.progressStats = nil
        }
    }
    
    func refreshAllData() async {
        await fetchTodaysWorkouts()
        await fetchRecentActivity()
        await fetchProgressStats()
    }
}

// MARK: - Supporting Models

struct ProgressStats: Codable {
    let totalWorkouts: Int
    let weeklyGoal: Int
    let currentStreak: Int
    let completionRate: Double
    let totalMinutes: Int
    
    var weeklyProgress: Double {
        return min(Double(totalWorkouts) / Double(weeklyGoal), 1.0)
    }
}

struct WorkoutSession: Codable, Identifiable {
    let id: String
    let workoutName: String
    let completedAt: Date
    let duration: Int // in minutes
    let exercisesCompleted: Int
    let totalExercises: Int
    
    var completionPercentage: Double {
        return Double(exercisesCompleted) / Double(totalExercises)
    }
}
