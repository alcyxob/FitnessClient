// PolishedClientDashboard.swift
import SwiftUI

struct PolishedClientDashboardView: View {
    let apiService: APIService
    let authService: AuthService
    
    @StateObject private var viewModel: ClientDashboardViewModel
    @EnvironmentObject var toastManager: ToastManager
    @EnvironmentObject var appModeManager: AppModeManager
    @Environment(\.appTheme) var theme
    @State private var showingProfile = false
    @State private var refreshing = false
    @State private var selectedWorkout: Workout?
    @State private var showingWorkoutExecution = false
    @State private var showingAllPlans = false
    @State private var showingRecentActivity = false
    
    init(apiService: APIService, authService: AuthService) {
        self.apiService = apiService
        self.authService = authService
        self._viewModel = StateObject(wrappedValue: ClientDashboardViewModel(apiService: apiService, authService: authService))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Themed background
                theme.background.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.todaysWorkouts.isEmpty {
                    loadingView
                } else {
                    mainContent
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await refreshData()
            }
            .onAppear {
                if viewModel.todaysWorkouts.isEmpty {
                    Task {
                        await viewModel.refreshAllData()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showingProfile) {
            PolishedSettingsView(
                viewModel: SettingsViewModel(
                    apiService: apiService,
                    authService: authService,
                    appModeManager: appModeManager
                )
            )
        }
        .sheet(isPresented: $showingAllPlans) {
            PolishedClientPlansView(apiService: apiService)
        }
        .sheet(isPresented: $showingRecentActivity) {
            ClientActivityHistoryView(apiService: apiService, authService: authService)
        }
        .fullScreenCover(isPresented: $showingWorkoutExecution) {
            if let workout = selectedWorkout {
                PolishedWorkoutExecutionView(workout: workout)
                    .onDisappear {
                        showingWorkoutExecution = false
                        selectedWorkout = nil
                        // Refresh dashboard data after workout completion
                        Task {
                            await refreshData()
                        }
                    }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.primary)
            
            Text("Loading your dashboard...")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header with greeting and profile
                headerSection
                
                // Quick stats cards
                if !viewModel.todaysWorkouts.isEmpty {
                    quickStatsSection
                }
                
                // Weekly progress section
                if let progressStats = viewModel.progressStats {
                    weeklyProgressSection(progressStats)
                }
                
                // Today's workouts section
                todaysWorkoutsSection
                
                // Recent activity section
                recentActivitySection
                
                // Bottom padding for tab bar
                Color.clear.frame(height: 100)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Gradient header background
            ZStack {
                LinearGradient(
                    colors: [theme.gradientStart, theme.gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 16) {
                    // Top bar with greeting and profile
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greetingText)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            if let user = authService.loggedInUser {
                                Text(user.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        // Profile button
                        Button(action: {
                            showingProfile = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Date and motivational message
                    VStack(spacing: 8) {
                        Text(todayDateString)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(motivationalMessage)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 20)
                }
            }
            .frame(height: 180)
        }
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            HStack(spacing: 12) {
                // Total workouts
                QuickStatCard(
                    title: "Workouts",
                    value: "\(viewModel.todaysWorkouts.count)",
                    icon: "figure.strengthtraining.traditional",
                    color: theme.primary
                )
                
                // Total exercises (estimated)
                QuickStatCard(
                    title: "Exercises",
                    value: "\(estimatedExerciseCount)",
                    icon: "list.bullet.clipboard",
                    color: theme.secondary
                )
                
                // Completion status
                QuickStatCard(
                    title: "Status",
                    value: workoutStatusText,
                    icon: "checkmark.circle.fill",
                    color: theme.success
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Weekly Progress Section
    
    private func weeklyProgressSection(_ stats: ProgressStats) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Weekly Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                Text("\(stats.totalWorkouts)/\(stats.weeklyGoal)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.secondaryText)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.cardBorder.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [theme.primary, theme.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * stats.weeklyProgress, height: 8)
                        .animation(.easeInOut(duration: 0.8), value: stats.weeklyProgress)
                }
            }
            .frame(height: 8)
            
            // Additional stats
            HStack(spacing: 20) {
                ProgressStatItem(
                    title: "Streak",
                    value: "\(stats.currentStreak)",
                    unit: "days",
                    icon: "flame.fill",
                    color: .orange,
                    theme: theme
                )
                
                ProgressStatItem(
                    title: "Completion",
                    value: "\(Int(stats.completionRate * 100))",
                    unit: "%",
                    icon: "target",
                    color: theme.success,
                    theme: theme
                )
                
                ProgressStatItem(
                    title: "Total Time",
                    value: "\(stats.totalMinutes)",
                    unit: "min",
                    icon: "clock.fill",
                    color: theme.primary,
                    theme: theme
                )
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Today's Workouts Section
    
    private var todaysWorkoutsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Workouts")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                if !viewModel.todaysWorkouts.isEmpty {
                    Button("View All Plans") {
                        showingAllPlans = true
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            if viewModel.todaysWorkouts.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 48))
                        .foregroundColor(theme.primary.opacity(0.6))
                    
                    Text("No workouts scheduled for today")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.primaryText)
                    
                    Text("Take a rest day or check your training plans")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                    
                    Button("Browse Plans") {
                        showingAllPlans = true
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primary)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 40)
            } else {
                // Workout cards
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.todaysWorkouts) { workout in
                        WorkoutCard(
                            workout: workout,
                            onStartWorkout: { startWorkout(workout) }
                        )
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Activity Section
    
    private var recentActivitySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                Button("View All") {
                    showingRecentActivity = true
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.primary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Recent activity items
            if viewModel.recentActivity.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 32))
                        .foregroundColor(theme.primary.opacity(0.6))
                    
                    Text("No recent activity")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.recentActivity.prefix(3))) { session in
                        RecentActivityRow(
                            title: session.workoutName,
                            subtitle: "\(session.exercisesCompleted) exercises completed",
                            time: formatRelativeTime(session.completedAt),
                            icon: "checkmark.circle.fill",
                            iconColor: theme.success
                        )
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let firstName = authService.loggedInUser?.name.components(separatedBy: " ").first ?? "there"
        
        switch hour {
        case 0..<12:
            return "Good Morning, \(firstName)!"
        case 12..<18:
            return "Good Afternoon, \(firstName)!"
        default:
            return "Good Evening, \(firstName)!"
        }
    }
    
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private var motivationalMessage: String {
        let messages = [
            "Ready to crush your goals today!",
            "Every workout brings you closer to your best self.",
            "Your only competition is who you were yesterday.",
            "Strong is the new beautiful.",
            "Progress, not perfection.",
            "Make today count!",
            "You've got this!"
        ]
        return messages.randomElement() ?? "Let's get moving!"
    }
    
    private var estimatedExerciseCount: Int {
        // Since Workout model doesn't have exercises array, estimate based on workout count
        return viewModel.todaysWorkouts.count * 4 // Assume 4 exercises per workout on average
    }
    
    private var workoutStatusText: String {
        if viewModel.todaysWorkouts.isEmpty {
            return "Rest Day"
        } else {
            // Since we don't have completion status in the model, show "Ready"
            return "Ready"
        }
    }
    
    // MARK: - Helper Methods
    
    private func startWorkout(_ workout: Workout) {
        HapticManager.shared.impact(.medium)
        selectedWorkout = workout
        showingWorkoutExecution = true
        
        // Track workout start analytics
        print("Starting workout: \(workout.name)")
    }
    
    private func refreshData() async {
        refreshing = true
        await viewModel.refreshAllData()
        refreshing = false
        
        toastManager.showToast(
            style: .success,
            message: "Dashboard updated",
            duration: 2.0
        )
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    @Environment(\.appTheme) var theme
    
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)
            
            Text(title)
                .font(.caption)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
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

struct WorkoutCard: View {
    @Environment(\.appTheme) var theme
    
    let workout: Workout
    let onStartWorkout: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                    
                    HStack(spacing: 16) {
                        Label("Workout Plan", systemImage: "list.bullet")
                        
                        if let dayOfWeek = workout.dayOfWeek, dayOfWeek > 0 && dayOfWeek <= 7 {
                            let days = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                            Label(days[dayOfWeek], systemImage: "calendar")
                        }
                        
                        Label("Ready", systemImage: "star.fill")
                    }
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
                }
                
                Spacer()
                
                // Action button
                Button(action: onStartWorkout) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(theme.primary)
                }
            }
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

struct RecentActivityRow: View {
    @Environment(\.appTheme) var theme
    
    let title: String
    let subtitle: String
    let time: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(theme.secondaryText)
        }
        .padding(.vertical, 8)
    }
}

struct ProgressStatItem: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(theme.secondaryText)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(theme.secondaryText)
        }
    }
}

#Preview {
    PolishedClientDashboardView(
        apiService: APIService(authService: AuthService()),
        authService: AuthService()
    )
    .environmentObject(ToastManager())
    .environmentObject(AppModeManager())
    .environment(\.appTheme, AppTheme.client)
}
