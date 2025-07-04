// PolishedTrainerDashboardView.swift
import SwiftUI

struct PolishedTrainerDashboardView: View {
    let apiService: APIService
    let authService: AuthService
    
    @StateObject private var viewModel: TrainerDashboardViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    
    @State private var selectedTimeframe: Timeframe = .week
    @State private var showingClientDetails = false
    @State private var selectedMetric: DashboardMetric = .clients
    @State private var showingWorkoutTemplates = false
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        
        var icon: String {
            switch self {
            case .week: return "calendar"
            case .month: return "calendar.badge.clock"
            case .quarter: return "chart.bar.xaxis"
            }
        }
    }
    
    enum DashboardMetric: String, CaseIterable {
        case clients = "Clients"
        case workouts = "Workouts"
        case revenue = "Revenue"
        case engagement = "Engagement"
        
        var icon: String {
            switch self {
            case .clients: return "person.2.fill"
            case .workouts: return "figure.strengthtraining.traditional"
            case .revenue: return "dollarsign.circle.fill"
            case .engagement: return "heart.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .clients: return .blue
            case .workouts: return .green
            case .revenue: return .purple
            case .engagement: return .orange
            }
        }
    }
    
    init(apiService: APIService, authService: AuthService) {
        self.apiService = apiService
        self.authService = authService
        self._viewModel = StateObject(wrappedValue: TrainerDashboardViewModel(apiService: apiService, authService: authService))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Header with greeting and quick stats
                        headerSection
                        
                        // Timeframe selector
                        timeframeSelectorSection
                        
                        // Key metrics cards
                        keyMetricsSection
                        
                        // Charts and analytics
                        analyticsSection
                        
                        // Client activity overview
                        clientActivitySection
                        
                        // Quick actions
                        quickActionsSection
                        
                        // Recent activity feed
                        recentActivitySection
                        
                        // Bottom padding
                        Color.clear.frame(height: 100)
                    }
                }
                .refreshable {
                    await refreshDashboard()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await viewModel.fetchPendingReviews()
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showingWorkoutTemplates) {
            WorkoutTemplateLibraryView(apiService: apiService)
        }
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
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greetingText)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            if let trainer = authService.loggedInUser {
                                Text(trainer.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        // Notification bell
                        Button(action: {
                            // Show notifications
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                
                                // Notification badge
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 12, height: 12)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Quick overview stats
                    HStack(spacing: 16) {
                        QuickOverviewCard(
                            title: "Active Clients",
                            value: "\(mockActiveClients)",
                            trend: "+12%",
                            isPositive: true
                        )
                        
                        QuickOverviewCard(
                            title: "This Week",
                            value: "\(mockWeeklyWorkouts)",
                            trend: "+8%",
                            isPositive: true
                        )
                        
                        QuickOverviewCard(
                            title: "Completion",
                            value: "\(mockCompletionRate)%",
                            trend: "+5%",
                            isPositive: true
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .frame(height: 180)
            
            Rectangle()
                .fill(theme.cardBorder)
                .frame(height: 1)
        }
    }
    
    // MARK: - Timeframe Selector
    
    private var timeframeSelectorSection: some View {
        HStack(spacing: 0) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                TimeframeButton(
                    timeframe: timeframe,
                    isSelected: selectedTimeframe == timeframe
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTimeframe = timeframe
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(theme.background)
    }
    
    // MARK: - Key Metrics Section
    
    private var keyMetricsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Key Metrics")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                Text("Last \(selectedTimeframe.rawValue.lowercased())")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
            }
            .padding(.horizontal, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                MetricCard(
                    metric: .clients,
                    value: "\(mockTotalClients)",
                    change: "+3",
                    changePercent: "+15%",
                    isSelected: selectedMetric == .clients
                ) {
                    selectedMetric = .clients
                }
                
                MetricCard(
                    metric: .workouts,
                    value: "\(mockTotalWorkouts)",
                    change: "+24",
                    changePercent: "+12%",
                    isSelected: selectedMetric == .workouts
                ) {
                    selectedMetric = .workouts
                }
                
                MetricCard(
                    metric: .revenue,
                    value: "$\(mockRevenue)",
                    change: "+$450",
                    changePercent: "+8%",
                    isSelected: selectedMetric == .revenue
                ) {
                    selectedMetric = .revenue
                }
                
                MetricCard(
                    metric: .engagement,
                    value: "\(mockEngagement)%",
                    change: "+5%",
                    changePercent: "+7%",
                    isSelected: selectedMetric == .engagement
                ) {
                    selectedMetric = .engagement
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Analytics Section
    
    private var analyticsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Analytics")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to detailed analytics
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.primary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Chart card
            ThemedCard {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedMetric.rawValue)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.primaryText)
                            
                            Text("Trending upward")
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: selectedMetric.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(selectedMetric.color)
                    }
                    
                    // Mock chart
                    MockChartView(metric: selectedMetric)
                        .frame(height: 120)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Client Activity Section
    
    private var clientActivitySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Client Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                Button("View All") {
                    showingClientDetails = true
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.primary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { index in
                        ClientActivityCard(
                            clientName: mockClientNames[index],
                            progress: mockClientProgress[index],
                            workoutsCompleted: mockClientWorkouts[index],
                            streak: mockClientStreaks[index]
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                QuickActionCard(
                    title: "Add Client",
                    icon: "person.badge.plus",
                    color: theme.primary
                ) {
                    // Add client action
                }
                
                QuickActionCard(
                    title: "Create Exercise",
                    icon: "plus.circle.fill",
                    color: theme.secondary
                ) {
                    // Create exercise action
                }
                
                QuickActionCard(
                    title: "Workout Templates",
                    icon: "doc.text.fill",
                    color: .purple
                ) {
                    showingWorkoutTemplates = true
                }
                
                QuickActionCard(
                    title: "Schedule Workout",
                    icon: "calendar.badge.plus",
                    color: theme.accent
                ) {
                    // Schedule workout action
                }
                
                QuickActionCard(
                    title: "Send Message",
                    icon: "message.fill",
                    color: .orange
                ) {
                    // Send message action
                }
            }
            .padding(.horizontal, 20)
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
                    // Navigate to activity feed
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.primary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            VStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    ActivityFeedItem(
                        clientName: mockClientNames[index],
                        action: mockActivityActions[index],
                        time: mockActivityTimes[index],
                        type: mockActivityTypes[index]
                    )
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    // Mock data properties
    private var mockActiveClients: Int { 23 }
    private var mockWeeklyWorkouts: Int { 156 }
    private var mockCompletionRate: Int { 87 }
    private var mockTotalClients: Int { 28 }
    private var mockTotalWorkouts: Int { 224 }
    private var mockRevenue: Int { 5850 }
    private var mockEngagement: Int { 92 }
    
    private var mockClientNames: [String] {
        ["Sarah Johnson", "Mike Chen", "Emma Davis", "Alex Rodriguez", "Lisa Thompson"]
    }
    
    private var mockClientProgress: [Double] {
        [0.85, 0.72, 0.91, 0.68, 0.79]
    }
    
    private var mockClientWorkouts: [Int] {
        [12, 8, 15, 6, 10]
    }
    
    private var mockClientStreaks: [Int] {
        [7, 3, 12, 2, 5]
    }
    
    private var mockActivityActions: [String] {
        ["Completed workout", "Started new plan", "Achieved milestone", "Missed workout"]
    }
    
    private var mockActivityTimes: [String] {
        ["2 hours ago", "4 hours ago", "1 day ago", "2 days ago"]
    }
    
    private var mockActivityTypes: [ActivityType] {
        [.completed, .started, .achievement, .missed]
    }
    
    // MARK: - Helper Methods
    
    private func refreshDashboard() async {
        await viewModel.fetchPendingReviews()
    }
}

// MARK: - Supporting Views

struct QuickOverviewCard: View {
    let title: String
    let value: String
    let trend: String
    let isPositive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(trend)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isPositive ? Color.green.opacity(0.9) : Color.red.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TimeframeButton: View {
    @Environment(\.appTheme) var theme
    
    let timeframe: PolishedTrainerDashboardView.Timeframe
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: timeframe.icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(timeframe.rawValue)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : theme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.primary : theme.primary.opacity(0.1))
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MetricCard: View {
    @Environment(\.appTheme) var theme
    
    let metric: PolishedTrainerDashboardView.DashboardMetric
    let value: String
    let change: String
    let changePercent: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ThemedCard {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: metric.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(metric.color)
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(theme.success)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(metric.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(theme.secondaryText)
                            
                            Spacer()
                        }
                        
                        Text(value)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                        
                        HStack(spacing: 4) {
                            Text(change)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.success)
                            
                            Text(changePercent)
                                .font(.caption)
                                .foregroundColor(theme.success)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct MockChartView: View {
    @Environment(\.appTheme) var theme
    let metric: PolishedTrainerDashboardView.DashboardMetric
    
    var body: some View {
        GeometryReader { geometry in
            let points = generateMockDataPoints(width: geometry.size.width)
            
            ZStack {
                // Grid lines
                VStack(spacing: 0) {
                    ForEach(0..<4) { _ in
                        Rectangle()
                            .fill(theme.cardBorder.opacity(0.3))
                            .frame(height: 1)
                        
                        Spacer()
                    }
                }
                
                // Chart line
                Path { path in
                    for (index, point) in points.enumerated() {
                        if index == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [metric.color, metric.color.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                
                // Fill area under curve
                Path { path in
                    guard let firstPoint = points.first, let lastPoint = points.last else { return }
                    
                    path.move(to: CGPoint(x: firstPoint.x, y: geometry.size.height))
                    path.addLine(to: firstPoint)
                    
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                    
                    path.addLine(to: CGPoint(x: lastPoint.x, y: geometry.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [metric.color.opacity(0.3), metric.color.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Data points
                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    Circle()
                        .fill(metric.color)
                        .frame(width: 6, height: 6)
                        .position(point)
                }
            }
        }
    }
    
    private func generateMockDataPoints(width: CGFloat) -> [CGPoint] {
        let dataPoints: [Double] = [0.3, 0.7, 0.4, 0.8, 0.6, 0.9, 0.75]
        let stepWidth = width / CGFloat(dataPoints.count - 1)
        
        return dataPoints.enumerated().map { index, value in
            CGPoint(
                x: CGFloat(index) * stepWidth,
                y: 120 * (1 - value) // Invert Y coordinate
            )
        }
    }
}

struct ClientActivityCard: View {
    @Environment(\.appTheme) var theme
    
    let clientName: String
    let progress: Double
    let workoutsCompleted: Int
    let streak: Int
    
    var body: some View {
        ThemedCard {
            VStack(spacing: 12) {
                // Client avatar and name
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Text(clientName.prefix(2).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(theme.primary)
                    }
                    
                    Text(clientName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                        .lineLimit(1)
                }
                
                // Progress ring
                CircularProgressView(progress: progress, size: 40)
                
                // Stats
                VStack(spacing: 4) {
                    HStack {
                        Text("\(workoutsCompleted)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                        
                        Text("workouts")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }
                    
                    HStack {
                        Text("\(streak)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(theme.accent)
                        
                        Text("day streak")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(width: 140)
    }
}

struct QuickActionCard: View {
    @Environment(\.appTheme) var theme
    
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ThemedCard {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(color)
                    }
                    
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 16)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum ActivityType {
    case completed, started, achievement, missed
    
    var color: Color {
        switch self {
        case .completed: return .green
        case .started: return .blue
        case .achievement: return .purple
        case .missed: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .completed: return "checkmark.circle.fill"
        case .started: return "play.circle.fill"
        case .achievement: return "star.fill"
        case .missed: return "exclamationmark.triangle.fill"
        }
    }
}

struct ActivityFeedItem: View {
    @Environment(\.appTheme) var theme
    
    let clientName: String
    let action: String
    let time: String
    let type: ActivityType
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(type.color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(clientName) \(action)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            
            Spacer()
            
            Button(action: {
                // View details
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.tertiaryText)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    PolishedTrainerDashboardView(
        apiService: APIService(authService: AuthService()),
        authService: AuthService()
    )
    .environmentObject(ToastManager())
    .environment(\.appTheme, AppTheme.trainer)
}
