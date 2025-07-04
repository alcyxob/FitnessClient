// PolishedExerciseLibraryView.swift
import SwiftUI

struct PolishedExerciseLibraryView: View {
    @StateObject private var viewModel: ExerciseLibraryViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory = .all
    @State private var selectedDifficulty: DifficultyLevel = .all
    @State private var showingFilters = false
    @State private var showingCreateExercise = false
    @State private var selectedViewMode: ViewMode = .grid
    
    enum ViewMode: String, CaseIterable {
        case grid = "Grid"
        case list = "List"
        case cards = "Cards"
        
        var icon: String {
            switch self {
            case .grid: return "rectangle.grid.2x2"
            case .list: return "list.bullet"
            case .cards: return "rectangle.stack"
            }
        }
    }
    
    enum ExerciseCategory: String, CaseIterable {
        case all = "All"
        case chest = "Chest"
        case back = "Back"
        case shoulders = "Shoulders"
        case arms = "Arms"
        case legs = "Legs"
        case core = "Core"
        case cardio = "Cardio"
        case fullBody = "Full Body"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .chest: return "figure.strengthtraining.traditional"
            case .back: return "figure.strengthtraining.functional"
            case .shoulders: return "figure.arms.open"
            case .arms: return "figure.flexibility"
            case .legs: return "figure.walk"
            case .core: return "figure.core.training"
            case .cardio: return "heart.fill"
            case .fullBody: return "figure.run"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .gray
            case .chest: return .red
            case .back: return .blue
            case .shoulders: return .orange
            case .arms: return .purple
            case .legs: return .green
            case .core: return .yellow
            case .cardio: return .pink
            case .fullBody: return .indigo
            }
        }
    }
    
    enum DifficultyLevel: String, CaseIterable {
        case all = "All Levels"
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        
        var icon: String {
            switch self {
            case .all: return "star"
            case .beginner: return "star.fill"
            case .intermediate: return "star.leadinghalf.filled"
            case .advanced: return "star.circle.fill"
            }
        }
        
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
        self._viewModel = StateObject(wrappedValue: ExerciseLibraryViewModel(apiService: apiService))
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
            .sheet(isPresented: $showingCreateExercise) {
                PolishedCreateExerciseView(apiService: viewModel.apiService) {
                    Task {
                        await viewModel.refreshExercises()
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadExercises()
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises...")
            .onChange(of: searchText) { _ in
                viewModel.updateSearchText(searchText)
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
                            Text("Exercise Library")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("\(viewModel.filteredExercises.count) exercises available")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        // Quick stats
                        VStack(spacing: 8) {
                            quickStatCard(
                                value: "\(viewModel.exercises.count)",
                                label: "Total",
                                icon: "list.bullet"
                            )
                            
                            quickStatCard(
                                value: "\(viewModel.recentlyAddedCount)",
                                label: "Recent",
                                icon: "clock"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .frame(height: 120)
        }
    }
    
    private func quickStatCard(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
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
                    
                    TextField("Search exercises...", text: $searchText)
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
                
                // View mode selector
                Menu {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Button(action: {
                            selectedViewMode = mode
                        }) {
                            Label(mode.rawValue, systemImage: mode.icon)
                        }
                    }
                } label: {
                    Image(systemName: selectedViewMode.icon)
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
                
                // Add exercise button
                Button(action: {
                    showingCreateExercise = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.primary)
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
                    
                    ForEach(ExerciseCategory.allCases, id: \.self) { category in
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
                            icon: difficulty.icon,
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
            if viewModel.isLoading && viewModel.exercises.isEmpty {
                loadingView
            } else if viewModel.filteredExercises.isEmpty {
                emptyStateView
            } else {
                exerciseContent
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(theme.primary)
            
            Text("Loading exercises...")
                .font(.headline)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell")
                .font(.system(size: 64))
                .foregroundColor(theme.primary.opacity(0.6))
            
            Text("No Exercises Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)
            
            Text("Create your first exercise or adjust your filters")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
            
            Button("Create Exercise") {
                showingCreateExercise = true
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
    
    private var exerciseContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                switch selectedViewMode {
                case .grid:
                    exerciseGridView
                case .list:
                    exerciseListView
                case .cards:
                    exerciseCardsView
                }
                
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Exercise Views
    
    private var exerciseGridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(viewModel.filteredExercises) { exercise in
                ExerciseGridCard(exercise: exercise, apiService: viewModel.apiService)
            }
        }
    }
    
    private var exerciseListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.filteredExercises) { exercise in
                ExerciseListRow(exercise: exercise, apiService: viewModel.apiService)
            }
        }
    }
    
    private var exerciseCardsView: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.filteredExercises) { exercise in
                ExerciseDetailCard(exercise: exercise, apiService: viewModel.apiService)
            }
        }
    }
}

#Preview {
    PolishedExerciseLibraryView(
        apiService: APIService(authService: AuthService())
    )
    .environmentObject(ToastManager())
    .environment(\.appTheme, AppTheme.trainer)
}
