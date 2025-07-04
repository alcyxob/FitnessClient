// PolishedClientPlansView.swift
import SwiftUI

struct PolishedClientPlansView: View {
    let apiService: APIService
    @StateObject private var viewModel: ClientPlansViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    
    @State private var selectedTab: PlanTab = .active
    @State private var showingCalendarView = false
    @State private var selectedPlan: TrainingPlan?
    @State private var searchText = ""
    
    enum PlanTab: String, CaseIterable {
        case active = "Active"
        case completed = "Completed"
        case upcoming = "Upcoming"
        
        var icon: String {
            switch self {
            case .active: return "play.circle.fill"
            case .completed: return "checkmark.circle.fill"
            case .upcoming: return "clock.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .active: return .blue
            case .completed: return .green
            case .upcoming: return .orange
            }
        }
    }
    
    init(apiService: APIService) {
        self.apiService = apiService
        self._viewModel = StateObject(wrappedValue: ClientPlansViewModel(apiService: apiService))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom header
                    headerSection
                    
                    // Tab selector and search
                    tabAndSearchSection
                    
                    // Main content
                    mainContent
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedPlan) { plan in
                PlanDetailView(plan: plan)
            }
            .onAppear {
                if viewModel.trainingPlans.isEmpty {
                    Task {
                        await viewModel.fetchMyTrainingPlans()
                    }
                }
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
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Plans")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Track your fitness journey")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        // Calendar toggle button
                        Button(action: {
                            showingCalendarView.toggle()
                        }) {
                            Image(systemName: showingCalendarView ? "list.bullet" : "calendar")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Weekly progress overview
                    WeeklyProgressBar(progress: weeklyProgress)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
            }
            .frame(height: 140)
            
            Rectangle()
                .fill(theme.cardBorder)
                .frame(height: 1)
        }
    }
    
    // MARK: - Tab and Search Section
    
    private var tabAndSearchSection: some View {
        VStack(spacing: 16) {
            // Tab selector
            HStack(spacing: 0) {
                ForEach(PlanTab.allCases, id: \.self) { tab in
                    PlanTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        count: planCount(for: tab)
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Search bar (only show if not in calendar view)
            if !showingCalendarView {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.secondaryText)
                    
                    TextField("Search plans...", text: $searchText)
                        .font(.body)
                        .foregroundColor(theme.primaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.cardBorder, lineWidth: 1)
                )
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(theme.background)
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ZStack {
            if viewModel.isLoading && viewModel.trainingPlans.isEmpty {
                PulsingLoadingView(message: "Loading your workout plans...")
            } else if showingCalendarView {
                calendarView
            } else if filteredPlans.isEmpty && !viewModel.isLoading {
                emptyStateView
            } else {
                plansListView
            }
        }
    }
    
    // MARK: - Plans List View
    
    private var plansListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredPlans, id: \.id) { plan in
                    PlanCard(plan: plan) {
                        selectedPlan = plan
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Tab bar padding
        }
        .refreshable {
            await viewModel.fetchMyTrainingPlans()
        }
        .animation(.easeInOut(duration: 0.3), value: filteredPlans)
    }
    
    // MARK: - Calendar View
    
    private var calendarView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Calendar header
                HStack {
                    Text("This Week")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                    
                    Spacer()
                    
                    Text("4 of 6 completed")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                }
                .padding(.horizontal, 20)
                
                // Weekly calendar
                WeeklyCalendarView(plans: viewModel.trainingPlans)
                    .padding(.horizontal, 20)
                
                // Today's plan (if any)
                if let todaysPlan = todaysPlan {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Today's Workout")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.primaryText)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        TodaysPlanCard(plan: todaysPlan) {
                            selectedPlan = todaysPlan
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Color.clear.frame(height: 100) // Tab bar padding
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(theme.primary.opacity(0.6))
            }
            
            VStack(spacing: 12) {
                Text(emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                
                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            PulseButton(title: "Contact Your Trainer") {
                // Contact trainer action
            }
            .frame(maxWidth: 250)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Computed Properties
    
    private var filteredPlans: [TrainingPlan] {
        var plans = viewModel.trainingPlans
        
        // Apply search filter
        if !searchText.isEmpty {
            plans = plans.filter { plan in
                plan.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply tab filter
        switch selectedTab {
        case .active:
            plans = plans.filter { isActivePlan($0) }
        case .completed:
            plans = plans.filter { isCompletedPlan($0) }
        case .upcoming:
            plans = plans.filter { isUpcomingPlan($0) }
        }
        
        return plans
    }
    
    private var weeklyProgress: Double {
        // Mock weekly progress calculation
        return 0.65 // 65% of weekly goals completed
    }
    
    private var todaysPlan: TrainingPlan? {
        // Find today's plan (mock implementation)
        return viewModel.trainingPlans.first
    }
    
    private func planCount(for tab: PlanTab) -> Int {
        switch tab {
        case .active:
            return viewModel.trainingPlans.filter { isActivePlan($0) }.count
        case .completed:
            return viewModel.trainingPlans.filter { isCompletedPlan($0) }.count
        case .upcoming:
            return viewModel.trainingPlans.filter { isUpcomingPlan($0) }.count
        }
    }
    
    private func isActivePlan(_ plan: TrainingPlan) -> Bool {
        // Mock implementation - would check if plan is currently active
        return true
    }
    
    private func isCompletedPlan(_ plan: TrainingPlan) -> Bool {
        // Mock implementation - would check if plan is completed
        return false
    }
    
    private func isUpcomingPlan(_ plan: TrainingPlan) -> Bool {
        // Mock implementation - would check if plan starts in the future
        return false
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Plans Found"
        } else {
            switch selectedTab {
            case .active: return "No Active Plans"
            case .completed: return "No Completed Plans"
            case .upcoming: return "No Upcoming Plans"
            }
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms or browse all plans."
        } else {
            switch selectedTab {
            case .active: return "You don't have any active workout plans. Contact your trainer to get started!"
            case .completed: return "Complete some workouts to see your achievements here."
            case .upcoming: return "No upcoming plans scheduled. Check back later for new workouts!"
            }
        }
    }
}

// MARK: - Supporting Views

struct WeeklyProgressBar: View {
    @Environment(\.appTheme) var theme
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Weekly Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

struct PlanTabButton: View {
    @Environment(\.appTheme) var theme
    
    let tab: PolishedClientPlansView.PlanTab
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(tab.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(isSelected ? .white : tab.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.white.opacity(0.3) : tab.color.opacity(0.2))
                            )
                    }
                }
                .foregroundColor(isSelected ? .white : tab.color)
                
                Rectangle()
                    .fill(isSelected ? .white : Color.clear)
                    .frame(height: 2)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tab.color.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PlanCard: View {
    @Environment(\.appTheme) var theme
    let plan: TrainingPlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ThemedCard {
                VStack(spacing: 16) {
                    // Header with title and progress
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.name)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.primaryText)
                                .lineLimit(1)
                            
                            Text("Training Plan")
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryText)
                        }
                        
                        Spacer()
                        
                        CircularProgressView(progress: planProgress, size: 50)
                    }
                    
                    // Plan stats
                    HStack(spacing: 20) {
                        PlanStatItem(
                            icon: "calendar",
                            value: "8", // Mock workout count
                            label: "Workouts"
                        )
                        
                        PlanStatItem(
                            icon: "clock",
                            value: estimatedDuration,
                            label: "Duration"
                        )
                        
                        PlanStatItem(
                            icon: "flame.fill",
                            value: difficultyLevel,
                            label: "Level"
                        )
                    }
                    
                    // Plan description (if available)
                    if let description = plan.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Description")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(theme.primaryText)
                                
                                Spacer()
                                
                                Text(plan.isActive ? "Active" : "Inactive")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(plan.isActive ? theme.success : theme.accent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background((plan.isActive ? theme.success : theme.accent).opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryText)
                                .lineLimit(2)
                        }
                        .padding(.top, 8)
                        .overlay(
                            Rectangle()
                                .fill(theme.cardBorder)
                                .frame(height: 1),
                            alignment: .top
                        )
                    }
                    
                    // Action button
                    HStack {
                        Spacer()
                        
                        Text("View Plan")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primary)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.primary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var planProgress: Double {
        // Mock progress calculation
        return 0.4 // 40% completed
    }
    
    private var estimatedDuration: String {
        // Mock duration calculation
        return "4 weeks"
    }
    
    private var difficultyLevel: String {
        // Mock difficulty assessment
        return "Medium"
    }
}

struct PlanStatItem: View {
    @Environment(\.appTheme) var theme
    
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.accent)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)
            
            Text(label)
                .font(.caption)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeeklyCalendarView: View {
    @Environment(\.appTheme) var theme
    let plans: [TrainingPlan]
    
    private let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                    VStack(spacing: 8) {
                        Text(day)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.secondaryText)
                        
                        CalendarDayView(
                            day: index + 1,
                            hasWorkout: index < 4, // Mock: first 4 days have workouts
                            isCompleted: index < 2, // Mock: first 2 days completed
                            isToday: index == 2 // Mock: Wednesday is today
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 16)
        .background(theme.surface)
        .cornerRadius(16)
    }
}

struct CalendarDayView: View {
    @Environment(\.appTheme) var theme
    
    let day: Int
    let hasWorkout: Bool
    let isCompleted: Bool
    let isToday: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 40, height: 40)
            
            if hasWorkout {
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(day)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(textColor)
                }
            } else {
                Text("\(day)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.tertiaryText)
            }
        }
        .overlay(
            Circle()
                .stroke(isToday ? theme.primary : Color.clear, lineWidth: 2)
                .frame(width: 44, height: 44)
        )
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return theme.success
        } else if hasWorkout {
            return theme.primary.opacity(0.1)
        } else {
            return theme.cardBorder.opacity(0.3)
        }
    }
    
    private var textColor: Color {
        if hasWorkout && !isCompleted {
            return theme.primary
        } else {
            return theme.tertiaryText
        }
    }
}

struct TodaysPlanCard: View {
    @Environment(\.appTheme) var theme
    let plan: TrainingPlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ThemedCard {
                HStack(spacing: 16) {
                    // Workout icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.primary.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(theme.primary)
                    }
                    
                    // Workout info
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Today's Workout")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryText)
                        
                        Text("From \(plan.name)")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)
                        
                        HStack(spacing: 12) {
                            Label("45 min", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(theme.tertiaryText)
                            
                            Label("8 exercises", systemImage: "list.bullet")
                                .font(.caption)
                                .foregroundColor(theme.tertiaryText)
                        }
                    }
                    
                    Spacer()
                    
                    // Start button
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(theme.primary)
                        
                        Text("Start")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PlanDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.appTheme) var theme
    let plan: TrainingPlan
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Plan Detail: \(plan.name)")
                    .font(.title)
                    .padding()
                
                Text("This would show detailed plan information")
                    .foregroundColor(theme.secondaryText)
                
                Spacer()
            }
            .navigationTitle("Plan Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PolishedClientPlansView(apiService: APIService(authService: AuthService()))
        .environmentObject(ToastManager())
        .environment(\.appTheme, AppTheme.client)
}
