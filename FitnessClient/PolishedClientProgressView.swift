// PolishedClientProgressView.swift
import SwiftUI
import Charts

struct PolishedClientProgressView: View {
    let client: UserResponse
    
    @StateObject private var viewModel: ClientProgressViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab: ProgressTab = .overview
    
    enum ProgressTab: String, CaseIterable {
        case overview = "Overview"
        case workouts = "Workouts"
        case achievements = "Achievements"
        case analytics = "Analytics"
        
        var icon: String {
            switch self {
            case .overview: return "chart.pie.fill"
            case .workouts: return "dumbbell.fill"
            case .achievements: return "star.fill"
            case .analytics: return "chart.line.uptrend.xyaxis"
            }
        }
    }
    
    init(client: UserResponse, apiService: APIService) {
        self.client = client
        self._viewModel = StateObject(wrappedValue: ClientProgressViewModel(client: client, apiService: apiService))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Tab selector
                    tabSelector
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        overviewTab
                            .tag(ProgressTab.overview)
                        
                        workoutsTab
                            .tag(ProgressTab.workouts)
                        
                        achievementsTab
                            .tag(ProgressTab.achievements)
                        
                        analyticsTab
                            .tag(ProgressTab.analytics)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await viewModel.loadProgressData()
                }
            }
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [theme.gradientStart, theme.gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 16) {
                    // Top bar
                    HStack {
                        Button("Back") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Progress Tracking")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Export") {
                            // Export progress data
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Client info and quick stats
                    HStack(spacing: 20) {
                        // Client avatar
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 70, height: 70)
                            
                            Text(client.name.prefix(2).uppercased())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(client.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 16) {
                                quickStat(
                                    value: "\(viewModel.totalWorkouts)",
                                    label: "Workouts"
                                )
                                
                                quickStat(
                                    value: "\(viewModel.currentStreak)",
                                    label: "Day Streak"
                                )
                                
                                quickStat(
                                    value: "\(Int(viewModel.workoutCompletionRate * 100))%",
                                    label: "Completion"
                                )
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .frame(height: 160)
        }
    }
    
    private func quickStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(ProgressTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(tab.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedTab == tab ? theme.primary : theme.secondaryText)
                        .frame(minWidth: 80)
                        .padding(.vertical, 12)
                        .background(
                            Rectangle()
                                .fill(selectedTab == tab ? theme.primary.opacity(0.1) : Color.clear)
                        )
                        .overlay(
                            Rectangle()
                                .fill(selectedTab == tab ? theme.primary : Color.clear)
                                .frame(height: 2),
                            alignment: .bottom
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .background(theme.cardBackground)
        .overlay(
            Rectangle()
                .fill(theme.cardBorder)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Time range selector
                timeRangeSelector
                
                // Progress metrics cards
                progressMetricsGrid
                
                // Recent activity
                recentActivitySection
                
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var timeRangeSelector: some View {
        HStack(spacing: 8) {
            ForEach(ClientProgressViewModel.TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    Task {
                        await viewModel.updateTimeRange(range)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: range.icon)
                            .font(.system(size: 14))
                        
                        Text(range.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(viewModel.selectedTimeRange == range ? .white : theme.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(viewModel.selectedTimeRange == range ? theme.primary : theme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(theme.cardBorder, lineWidth: viewModel.selectedTimeRange == range ? 0 : 1)
                    )
                }
            }
            
            Spacer()
        }
    }
    
    private var progressMetricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            if let metrics = viewModel.progressMetrics {
                metricCard(
                    title: "Completion Rate",
                    value: "\(Int(viewModel.workoutCompletionRate * 100))%",
                    subtitle: "\(metrics.completedWorkouts)/\(metrics.assignedWorkouts) workouts",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                metricCard(
                    title: "Current Streak",
                    value: "\(metrics.currentStreak)",
                    subtitle: "days in a row",
                    icon: "flame.fill",
                    color: .orange
                )
                
                metricCard(
                    title: "Avg Duration",
                    value: "\(metrics.averageWorkoutDuration)m",
                    subtitle: "per workout",
                    icon: "clock.fill",
                    color: .blue
                )
                
                metricCard(
                    title: "Consistency",
                    value: "\(metrics.consistencyScore)",
                    subtitle: "out of 100",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .purple
                )
            }
        }
    }
    
    private func metricCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            if viewModel.workoutHistory.isEmpty {
                emptyActivityView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.workoutHistory.prefix(5)) { session in
                        workoutSessionRow(session)
                    }
                }
            }
        }
    }
    
    private var emptyActivityView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 32))
                .foregroundColor(theme.secondaryText)
            
            Text("No recent activity")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackground.opacity(0.5))
        )
    }
    
    private func workoutSessionRow(_ session: WorkoutSession) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 18))
                .foregroundColor(theme.primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(theme.primary.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.workoutName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Text("\(session.exercisesCompleted)/\(session.totalExercises) exercises • \(session.duration)m")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
                
                Text(formatRelativeDate(session.completedAt))
                    .font(.caption2)
                    .foregroundColor(theme.secondaryText)
            }
            
            Spacer()
            
            // Completion percentage indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 30, height: 30)
                
                Circle()
                    .trim(from: 0, to: session.completionPercentage)
                    .stroke(.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(session.completionPercentage * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
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
    
    // MARK: - Workouts Tab
    
    private var workoutsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.workoutHistory.isEmpty {
                    emptyWorkoutsView
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.workoutHistory) { session in
                            detailedWorkoutRow(session)
                        }
                    }
                }
                
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var emptyWorkoutsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundColor(theme.primary.opacity(0.6))
            
            Text("No Workouts Yet")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            Text("\(client.name) hasn't completed any workouts in the selected time period")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
    
    private func detailedWorkoutRow(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(session.workoutName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                Text(formatDate(session.completedAt))
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            
            HStack(spacing: 20) {
                statItem(
                    icon: "clock.fill",
                    value: "\(session.duration)m",
                    label: "Duration"
                )
                
                statItem(
                    icon: "list.bullet",
                    value: "\(session.exercisesCompleted)/\(session.totalExercises)",
                    label: "Exercises"
                )
                
                statItem(
                    icon: "checkmark.circle.fill",
                    value: "\(Int(session.completionPercentage * 100))%",
                    label: "Completed"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
    }
    
    private func statItem(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(theme.primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(theme.secondaryText)
            }
        }
    }
    
    // MARK: - Achievements Tab
    
    private var achievementsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.recentAchievements.isEmpty {
                    emptyAchievementsView
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.recentAchievements) { achievement in
                            achievementRow(achievement)
                        }
                    }
                }
                
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var emptyAchievementsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "star")
                .font(.system(size: 48))
                .foregroundColor(theme.primary.opacity(0.6))
            
            Text("No Achievements Yet")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            Text("Keep working out to unlock achievements!")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
    
    private func achievementRow(_ achievement: Achievement) -> some View {
        HStack(spacing: 16) {
            Image(systemName: achievement.icon)
                .font(.system(size: 24))
                .foregroundColor(colorFromString(achievement.color))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(colorFromString(achievement.color).opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                
                Text(formatDate(achievement.achievedAt))
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Analytics Tab
    
    private var analyticsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Metric selector
                metricSelector
                
                // Performance chart
                performanceChart
                
                // Insights
                insightsSection
                
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var metricSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ClientProgressViewModel.ProgressMetric.allCases, id: \.self) { metric in
                    Button(action: {
                        Task {
                            await viewModel.updateMetric(metric)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: metric.icon)
                                .font(.system(size: 14))
                            
                            Text(metric.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(viewModel.selectedMetric == metric ? .white : theme.primaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(viewModel.selectedMetric == metric ? metric.color : theme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.cardBorder, lineWidth: viewModel.selectedMetric == metric ? 0 : 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var performanceChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Trend")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            if let chartData = viewModel.performanceCharts {
                Chart {
                    ForEach(Array(zip(chartData.dates, chartData.values)), id: \.0) { date, value in
                        LineMark(
                            x: .value("Date", date),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(viewModel.selectedMetric.color)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        
                        AreaMark(
                            x: .value("Date", date),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [viewModel.selectedMetric.color.opacity(0.3), viewModel.selectedMetric.color.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, chartData.dates.count / 5))) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
            } else {
                Rectangle()
                    .fill(theme.cardBackground.opacity(0.5))
                    .frame(height: 200)
                    .overlay(
                        Text("Loading chart...")
                            .foregroundColor(theme.secondaryText)
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            VStack(spacing: 12) {
                insightCard(
                    icon: "arrow.up.circle.fill",
                    title: "Great Progress!",
                    description: "\(client.name) has improved their consistency by 15% this month",
                    color: .green
                )
                
                insightCard(
                    icon: "target",
                    title: "Goal Recommendation",
                    description: "Consider increasing workout frequency to 4x per week for optimal results",
                    color: .blue
                )
                
                insightCard(
                    icon: "flame.fill",
                    title: "Streak Opportunity",
                    description: "Only 2 more days needed to beat their longest streak of \(viewModel.progressMetrics?.longestStreak ?? 0) days",
                    color: .orange
                )
            }
        }
    }
    
    private func insightCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            
            Spacer()
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
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString.lowercased() {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "gold": return .yellow
        default: return .primary
        }
    }
}

#Preview {
    PolishedClientProgressView(
        client: UserResponse(
            id: "1",
            name: "John Doe",
            email: "john@example.com",
            roles: ["client"],
            createdAt: Date(),
            clientIds: nil,
            trainerId: "trainer1"
        ),
        apiService: APIService(authService: AuthService())
    )
    .environmentObject(ToastManager())
    .environment(\.appTheme, AppTheme.trainer)
}
