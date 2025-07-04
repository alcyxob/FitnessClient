// WorkoutTemplateLibraryView.swift
import SwiftUI

struct WorkoutTemplateLibraryView: View {
    @StateObject private var viewModel: WorkoutTemplateViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    @State private var selectedCategory: WorkoutCategory = .all
    @State private var selectedDifficulty: DifficultyLevel = .all
    @State private var showingFilters = false
    @State private var showingCreateTemplate = false
    
    enum WorkoutCategory: String, CaseIterable {
        case all = "All"
        case strength = "Strength"
        case cardio = "Cardio"
        case hiit = "HIIT"
        case flexibility = "Flexibility"
        case fullBody = "Full Body"
        case upperBody = "Upper Body"
        case lowerBody = "Lower Body"
        case core = "Core"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .strength: return "dumbbell.fill"
            case .cardio: return "heart.fill"
            case .hiit: return "bolt.fill"
            case .flexibility: return "figure.flexibility"
            case .fullBody: return "figure.run"
            case .upperBody: return "figure.strengthtraining.traditional"
            case .lowerBody: return "figure.walk"
            case .core: return "figure.core.training"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .gray
            case .strength: return .red
            case .cardio: return .pink
            case .hiit: return .orange
            case .flexibility: return .green
            case .fullBody: return .purple
            case .upperBody: return .blue
            case .lowerBody: return .indigo
            case .core: return .yellow
            }
        }
    }
    
    enum DifficultyLevel: String, CaseIterable {
        case all = "All Levels"
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        
        var color: Color {
            switch self {
            case .all: return .gray
            case .beginner: return .green
            case .intermediate: return .orange
            case .advanced: return .red
            }
        }
    }
    
    init(apiService: APIService) {
        self._viewModel = StateObject(wrappedValue: WorkoutTemplateViewModel(apiService: apiService))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Search and controls
                    searchAndControlsSection
                    
                    // Filter chips
                    if showingFilters {
                        filterChipsSection
                    }
                    
                    // Main content
                    mainContent
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCreateTemplate) {
                AdvancedWorkoutBuilderView(apiService: viewModel.apiService) {
                    Task {
                        await viewModel.loadTemplates()
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadTemplates()
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
                        Button("Back") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Workout Templates")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Create") {
                            showingCreateTemplate = true
                        }
                        .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Quick stats
                    HStack(spacing: 20) {
                        quickStatCard(
                            value: "\(viewModel.templates.count)",
                            label: "Templates",
                            icon: "doc.text.fill"
                        )
                        
                        quickStatCard(
                            value: "\(viewModel.filteredTemplates.count)",
                            label: "Filtered",
                            icon: "line.3.horizontal.decrease"
                        )
                        
                        quickStatCard(
                            value: "\(viewModel.recentTemplatesCount)",
                            label: "Recent",
                            icon: "clock.fill"
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .frame(height: 140)
        }
    }
    
    private func quickStatCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.2))
        )
    }
    
    // MARK: - Search and Controls Section
    
    private var searchAndControlsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.secondaryText)
                    
                    TextField("Search workout templates...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.cardBorder, lineWidth: 1)
                )
                
                // Filter button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingFilters.toggle()
                    }
                }) {
                    Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 20))
                        .foregroundColor(theme.primary)
                        .frame(width: 44, height: 44)
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
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(theme.background)
    }
    
    // MARK: - Filter Chips Section
    
    private var filterChipsSection: some View {
        VStack(spacing: 12) {
            // Category filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text("Category:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.primaryText)
                        .padding(.leading, 20)
                    
                    ForEach(WorkoutCategory.allCases, id: \.self) { category in
                        filterChip(
                            title: category.rawValue,
                            icon: category.icon,
                            color: category.color,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                            viewModel.updateCategoryFilter(category.rawValue)
                        }
                    }
                }
                .padding(.trailing, 20)
            }
            
            // Difficulty filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text("Difficulty:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.primaryText)
                        .padding(.leading, 20)
                    
                    ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                        filterChip(
                            title: difficulty.rawValue,
                            icon: "star.fill",
                            color: difficulty.color,
                            isSelected: selectedDifficulty == difficulty
                        ) {
                            selectedDifficulty = difficulty
                            viewModel.updateDifficultyFilter(difficulty.rawValue)
                        }
                    }
                }
                .padding(.trailing, 20)
            }
        }
        .padding(.vertical, 12)
        .background(theme.cardBackground.opacity(0.5))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private func filterChip(title: String, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color : color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ZStack {
            if viewModel.isLoading && viewModel.templates.isEmpty {
                loadingView
            } else if viewModel.filteredTemplates.isEmpty {
                emptyStateView
            } else {
                templateContent
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.primary)
            
            Text("Loading workout templates...")
                .font(.headline)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(theme.primary.opacity(0.6))
            
            Text("No Templates Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)
            
            Text("Create your first workout template or adjust your filters")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
            
            Button("Create Template") {
                showingCreateTemplate = true
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.primary)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var templateContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredTemplates) { template in
                    WorkoutTemplateCard(template: template, apiService: viewModel.apiService)
                }
                
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
}

#Preview {
    WorkoutTemplateLibraryView(
        apiService: APIService(authService: AuthService())
    )
    .environmentObject(ToastManager())
    .environment(\.appTheme, AppTheme.trainer)
}
