// PolishedWorkoutAssignmentView.swift
import SwiftUI

struct PolishedWorkoutAssignmentView: View {
    let client: UserResponse
    
    @StateObject private var viewModel: WorkoutAssignmentViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab: AssignmentTab = .quickAssign
    @State private var showingCreatePlan = false
    @State private var showingCreateWorkout = false
    
    enum AssignmentTab: String, CaseIterable {
        case quickAssign = "Quick Assign"
        case trainingPlans = "Training Plans"
        case templates = "Templates"
        
        var icon: String {
            switch self {
            case .quickAssign: return "bolt.fill"
            case .trainingPlans: return "calendar"
            case .templates: return "doc.on.doc"
            }
        }
    }
    
    init(client: UserResponse, apiService: APIService) {
        self.client = client
        self._viewModel = StateObject(wrappedValue: WorkoutAssignmentViewModel(client: client, apiService: apiService))
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
                    
                    // Content based on selected tab
                    TabView(selection: $selectedTab) {
                        quickAssignView
                            .tag(AssignmentTab.quickAssign)
                        
                        trainingPlansView
                            .tag(AssignmentTab.trainingPlans)
                        
                        templatesView
                            .tag(AssignmentTab.templates)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await viewModel.loadData()
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
                    // Top bar
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Assign Workout")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Help") {
                            // Show help
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Client info
                    HStack(spacing: 16) {
                        // Client avatar
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Text(client.name.prefix(2).uppercased())
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Assigning to")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(client.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(client.email)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
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
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(AssignmentTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: .medium))
                        
                        Text(tab.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == tab ? theme.primary : theme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
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
        .background(theme.cardBackground)
        .overlay(
            Rectangle()
                .fill(theme.cardBorder)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Quick Assign View
    
    private var quickAssignView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Quick workout templates
                quickWorkoutTemplates
                
                // Recent workouts
                recentWorkouts
                
                // Create new workout
                createNewWorkoutSection
                
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var quickWorkoutTemplates: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Templates")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                quickTemplateCard(
                    title: "Upper Body",
                    exercises: "Push-ups, Pull-ups, Dips",
                    duration: "30 min",
                    icon: "figure.strengthtraining.traditional",
                    color: theme.primary
                )
                
                quickTemplateCard(
                    title: "Lower Body",
                    exercises: "Squats, Lunges, Calf Raises",
                    duration: "25 min",
                    icon: "figure.walk",
                    color: theme.secondary
                )
                
                quickTemplateCard(
                    title: "Cardio",
                    exercises: "Running, Jumping Jacks",
                    duration: "20 min",
                    icon: "heart.fill",
                    color: .red
                )
                
                quickTemplateCard(
                    title: "Full Body",
                    exercises: "Burpees, Mountain Climbers",
                    duration: "45 min",
                    icon: "figure.run",
                    color: .orange
                )
            }
        }
    }
    
    private func quickTemplateCard(title: String, exercises: String, duration: String, icon: String, color: Color) -> some View {
        Button(action: {
            // Assign quick template
            Task {
                await viewModel.assignQuickTemplate(title)
            }
        }) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                    
                    Text(exercises)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                    
                    Text(duration)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(color)
                }
            }
            .frame(maxWidth: .infinity)
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
        .buttonStyle(PlainButtonStyle())
    }
    
    private var recentWorkouts: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Workouts")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                Button("View All") {
                    // Show all recent workouts
                }
                .font(.subheadline)
                .foregroundColor(theme.primary)
            }
            
            if viewModel.recentWorkouts.isEmpty {
                emptyRecentWorkouts
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.recentWorkouts) { workout in
                        recentWorkoutRow(workout)
                    }
                }
            }
        }
    }
    
    private var emptyRecentWorkouts: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32))
                .foregroundColor(theme.secondaryText)
            
            Text("No recent workouts")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
            
            Text("Create your first workout to see it here")
                .font(.caption)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.cardBackground.opacity(0.5))
        )
    }
    
    private func recentWorkoutRow(_ workout: Workout) -> some View {
        Button(action: {
            Task {
                await viewModel.assignWorkout(workout)
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.primary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(theme.primary.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                    
                    if let notes = workout.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(theme.secondaryText)
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
        .buttonStyle(PlainButtonStyle())
    }
    
    private var createNewWorkoutSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                showingCreateWorkout = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    
                    Text("Create New Workout")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [theme.primary, theme.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
        }
    }
    
    // MARK: - Training Plans View
    
    private var trainingPlansView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Existing plans
                existingPlansSection
                
                // Create new plan
                createNewPlanSection
                
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var existingPlansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Training Plans for \(client.name)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            if viewModel.trainingPlans.isEmpty {
                emptyTrainingPlans
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.trainingPlans) { plan in
                        trainingPlanRow(plan)
                    }
                }
            }
        }
    }
    
    private var emptyTrainingPlans: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(theme.primary.opacity(0.6))
            
            Text("No Training Plans Yet")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            Text("Create a structured training plan to help \(client.name) achieve their fitness goals")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
    }
    
    private func trainingPlanRow(_ plan: TrainingPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(plan.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                Text(plan.isActive ? "Active" : "Inactive")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(plan.isActive ? .green : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((plan.isActive ? Color.green : Color.orange).opacity(0.1))
                    )
            }
            
            if let description = plan.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .lineLimit(2)
            }
            
            HStack(spacing: 20) {
                Label("Training Plan", systemImage: "calendar")
                Label(formatDate(plan.createdAt), systemImage: "clock")
                Label("Custom", systemImage: "star")
            }
            .font(.caption)
            .foregroundColor(theme.secondaryText)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private var createNewPlanSection: some View {
        Button(action: {
            showingCreatePlan = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                
                Text("Create Training Plan")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [theme.primary, theme.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
    }
    
    // MARK: - Templates View
    
    private var templatesView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Workout Templates")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                
                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(theme.secondaryText)
                
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
}

#Preview {
    PolishedWorkoutAssignmentView(
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
