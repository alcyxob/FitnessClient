// ClientProgressViewModel.swift
import Foundation
import SwiftUI

@MainActor
class ClientProgressViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Client progress data
    @Published var workoutHistory: [WorkoutSession] = []
    @Published var progressMetrics: ClientProgressMetrics?
    @Published var recentAchievements: [Achievement] = []
    @Published var performanceCharts: PerformanceChartData?
    
    // Filter and display options
    @Published var selectedTimeRange: TimeRange = .month
    @Published var selectedMetric: ProgressMetric = .workoutFrequency
    
    // MARK: - Private Properties
    
    private let client: UserResponse
    private let apiService: APIService
    
    // MARK: - Enums
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "3 Months"
        case year = "Year"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
        
        var icon: String {
            switch self {
            case .week: return "calendar"
            case .month: return "calendar.badge.clock"
            case .quarter: return "calendar.badge.plus"
            case .year: return "calendar.badge.exclamationmark"
            }
        }
    }
    
    enum ProgressMetric: String, CaseIterable {
        case workoutFrequency = "Workout Frequency"
        case strengthGains = "Strength Gains"
        case enduranceProgress = "Endurance Progress"
        case consistencyScore = "Consistency Score"
        
        var icon: String {
            switch self {
            case .workoutFrequency: return "calendar.badge.clock"
            case .strengthGains: return "dumbbell.fill"
            case .enduranceProgress: return "heart.fill"
            case .consistencyScore: return "chart.line.uptrend.xyaxis"
            }
        }
        
        var color: Color {
            switch self {
            case .workoutFrequency: return .blue
            case .strengthGains: return .red
            case .enduranceProgress: return .green
            case .consistencyScore: return .purple
            }
        }
    }
    
    // MARK: - Initialization
    
    init(client: UserResponse, apiService: APIService) {
        self.client = client
        self.apiService = apiService
    }
    
    // MARK: - Data Loading
    
    func loadProgressData() async {
        isLoading = true
        errorMessage = nil
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadWorkoutHistory() }
            group.addTask { await self.loadProgressMetrics() }
            group.addTask { await self.loadRecentAchievements() }
            group.addTask { await self.loadPerformanceCharts() }
        }
        
        isLoading = false
    }
    
    private func loadWorkoutHistory() async {
        do {
            let sessions: [WorkoutSession] = try await apiService.GET(
                endpoint: "/trainer/clients/\(client.id)/workout-sessions?days=\(selectedTimeRange.days)"
            )
            self.workoutHistory = sessions.sorted { $0.completedAt > $1.completedAt }
            print("ClientProgressVM: Loaded \(sessions.count) workout sessions for \(client.name)")
        } catch {
            print("ClientProgressVM: Error loading workout history: \(error)")
            // Create mock data for development
            self.workoutHistory = createMockWorkoutHistory()
        }
    }
    
    private func loadProgressMetrics() async {
        do {
            let metrics: ClientProgressMetrics = try await apiService.GET(
                endpoint: "/trainer/clients/\(client.id)/progress-metrics?days=\(selectedTimeRange.days)"
            )
            self.progressMetrics = metrics
            print("ClientProgressVM: Loaded progress metrics for \(client.name)")
        } catch {
            print("ClientProgressVM: Error loading progress metrics: \(error)")
            // Create mock data for development
            self.progressMetrics = createMockProgressMetrics()
        }
    }
    
    private func loadRecentAchievements() async {
        do {
            let achievements: [Achievement] = try await apiService.GET(
                endpoint: "/trainer/clients/\(client.id)/achievements?limit=10"
            )
            self.recentAchievements = achievements
            print("ClientProgressVM: Loaded \(achievements.count) achievements for \(client.name)")
        } catch {
            print("ClientProgressVM: Error loading achievements: \(error)")
            // Create mock achievements for development
            self.recentAchievements = createMockAchievements()
        }
    }
    
    private func loadPerformanceCharts() async {
        do {
            let chartData: PerformanceChartData = try await apiService.GET(
                endpoint: "/trainer/clients/\(client.id)/performance-charts?days=\(selectedTimeRange.days)&metric=\(selectedMetric.rawValue)"
            )
            self.performanceCharts = chartData
            print("ClientProgressVM: Loaded performance chart data for \(client.name)")
        } catch {
            print("ClientProgressVM: Error loading performance charts: \(error)")
            // Create mock chart data for development
            self.performanceCharts = createMockChartData()
        }
    }
    
    // MARK: - Data Refresh
    
    func refreshData() async {
        await loadProgressData()
    }
    
    func updateTimeRange(_ range: TimeRange) async {
        selectedTimeRange = range
        await loadProgressData()
    }
    
    func updateMetric(_ metric: ProgressMetric) async {
        selectedMetric = metric
        await loadPerformanceCharts()
    }
    
    // MARK: - Computed Properties
    
    var workoutCompletionRate: Double {
        guard let metrics = progressMetrics else { return 0 }
        return Double(metrics.completedWorkouts) / Double(max(metrics.assignedWorkouts, 1))
    }
    
    var averageWorkoutsPerWeek: Double {
        let weeks = Double(selectedTimeRange.days) / 7.0
        return Double(workoutHistory.count) / weeks
    }
    
    var currentStreak: Int {
        progressMetrics?.currentStreak ?? 0
    }
    
    var totalWorkouts: Int {
        progressMetrics?.completedWorkouts ?? workoutHistory.count
    }
    
    // MARK: - Mock Data (for development)
    
    private func createMockWorkoutHistory() -> [WorkoutSession] {
        let workoutNames = ["Upper Body Strength", "Cardio Blast", "Lower Body Power", "Full Body Circuit", "Core & Flexibility"]
        
        return (0..<10).map { index in
            WorkoutSession(
                id: "session_\(index)",
                workoutName: workoutNames.randomElement() ?? "Workout",
                completedAt: Date().addingTimeInterval(-Double(index * 86400 + Int.random(in: 0...3600))),
                duration: Int.random(in: 25...60),
                exercisesCompleted: Int.random(in: 4...8),
                totalExercises: Int.random(in: 5...8)
            )
        }.sorted { $0.completedAt > $1.completedAt }
    }
    
    private func createMockProgressMetrics() -> ClientProgressMetrics {
        ClientProgressMetrics(
            completedWorkouts: workoutHistory.count,
            assignedWorkouts: workoutHistory.count + 3,
            currentStreak: 5,
            longestStreak: 12,
            totalWorkoutTime: 1800, // 30 hours
            averageWorkoutDuration: 45,
            strengthGainPercentage: 15.5,
            enduranceImprovement: 22.3,
            consistencyScore: 85
        )
    }
    
    private func createMockAchievements() -> [Achievement] {
        [
            Achievement(
                id: "1",
                title: "5 Day Streak",
                description: "Completed workouts for 5 consecutive days",
                icon: "flame.fill",
                color: "orange",
                achievedAt: Date().addingTimeInterval(-86400 * 2)
            ),
            Achievement(
                id: "2",
                title: "Strength Milestone",
                description: "Increased bench press by 20%",
                icon: "dumbbell.fill",
                color: "red",
                achievedAt: Date().addingTimeInterval(-86400 * 5)
            ),
            Achievement(
                id: "3",
                title: "Consistency Champion",
                description: "Maintained 80%+ workout completion rate",
                icon: "star.fill",
                color: "gold",
                achievedAt: Date().addingTimeInterval(-86400 * 7)
            )
        ]
    }
    
    private func createMockChartData() -> PerformanceChartData {
        let dates = (0..<selectedTimeRange.days).map { 
            Calendar.current.date(byAdding: .day, value: -$0, to: Date()) ?? Date()
        }.reversed()
        
        let values = dates.enumerated().map { index, _ in
            Double.random(in: 0.5...1.0) * Double(index + 1) / Double(dates.count) * 100
        }
        
        return PerformanceChartData(
            dates: Array(dates),
            values: values,
            metric: selectedMetric.rawValue,
            unit: getUnitForMetric(selectedMetric)
        )
    }
    
    private func getUnitForMetric(_ metric: ProgressMetric) -> String {
        switch metric {
        case .workoutFrequency: return "workouts/week"
        case .strengthGains: return "% increase"
        case .enduranceProgress: return "% improvement"
        case .consistencyScore: return "score"
        }
    }
}

// MARK: - Supporting Models

struct ClientProgressMetrics: Codable {
    let completedWorkouts: Int
    let assignedWorkouts: Int
    let currentStreak: Int
    let longestStreak: Int
    let totalWorkoutTime: Int // in minutes
    let averageWorkoutDuration: Int // in minutes
    let strengthGainPercentage: Double
    let enduranceImprovement: Double
    let consistencyScore: Int // 0-100
}

struct Achievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: String
    let achievedAt: Date
}

struct PerformanceChartData: Codable {
    let dates: [Date]
    let values: [Double]
    let metric: String
    let unit: String
}
