// PolishedTrainerExerciseListView.swift
import SwiftUI

struct PolishedTrainerExerciseListView: View {
    @StateObject var viewModel: TrainerExerciseListViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    
    @State private var showingCreateExercise = false
    @State private var searchText = ""
    @State private var selectedFilter: ExerciseFilter = .all
    @State private var showingFilters = false
    
    enum ExerciseFilter: String, CaseIterable {
        case all = "All"
        case recent = "Recent"
        case favorites = "Favorites"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .recent: return "clock"
            case .favorites: return "heart.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom header
                    headerSection
                    
                    // Search and filter bar
                    searchAndFilterSection
                    
                    // Main content
                    mainContent
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCreateExercise) {
                PolishedCreateExerciseView(apiService: viewModel.apiService) {
                    Task {
                        await viewModel.fetchTrainerExercises()
                    }
                }
            }
            .onAppear {
                if viewModel.exercises.isEmpty {
                    Task {
                        await viewModel.fetchTrainerExercises()
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
                            Text("Exercise Library")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Create and manage your exercises")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        // Stats badge
                        VStack(spacing: 2) {
                            Text("\(viewModel.exercises.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Exercises")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                }
            }
            .frame(height: 120)
            
            Rectangle()
                .fill(theme.cardBorder)
                .frame(height: 1)
        }
    }
    
    // MARK: - Search and Filter Section
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.secondaryText)
                    
                    TextField("Search exercises...", text: $searchText)
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
                
                // Filter button
                Button(action: {
                    showingFilters.toggle()
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(theme.primary)
                        .frame(width: 44, height: 44)
                        .background(theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.cardBorder, lineWidth: 1)
                        )
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            
            // Filter chips
            if showingFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ExerciseFilter.allCases, id: \.self) { filter in
                            ExerciseFilterChip(
                                title: filter.rawValue,
                                icon: filter.icon,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 16)
        .background(theme.background)
        .animation(.easeInOut(duration: 0.3), value: showingFilters)
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ZStack {
            if viewModel.isLoading && viewModel.exercises.isEmpty {
                PulsingLoadingView(message: "Loading your exercise library...")
            } else if filteredExercises.isEmpty && !viewModel.isLoading {
                emptyStateView
            } else {
                exercisesList
            }
        }
    }
    
    private var exercisesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Create new exercise card
                createExerciseCard
                
                // Exercise list
                ForEach(filteredExercises, id: \.id) { exercise in
                    NavigationLink(destination: Text("Exercise Detail: \(exercise.name)")) {
                        EnhancedExerciseCard(exercise: exercise)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Tab bar padding
        }
        .refreshable {
            await viewModel.fetchTrainerExercises()
        }
    }
    
    private var createExerciseCard: some View {
        Button(action: {
            showingCreateExercise = true
        }) {
            ThemedCard {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(theme.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create New Exercise")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryText)
                        
                        Text("Add a custom exercise to your library")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle")
                        .font(.system(size: 20))
                        .foregroundColor(theme.primary)
                }
                .padding(.vertical, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Empty state illustration
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "dumbbell.fill")
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
            
            PulseButton(title: "Create Your First Exercise") {
                showingCreateExercise = true
            }
            .frame(maxWidth: 250)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Computed Properties
    
    private var filteredExercises: [Exercise] {
        var exercises = viewModel.exercises
        
        // Apply search filter
        if !searchText.isEmpty {
            exercises = exercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                (exercise.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .recent:
            exercises = exercises.sorted { $0.createdAt > $1.createdAt }.prefix(10).map { $0 }
        case .favorites:
            // This would filter favorites if we had that data
            break
        }
        
        return exercises
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results Found"
        } else if selectedFilter != .all {
            return "No \(selectedFilter.rawValue) Exercises"
        } else {
            return "No Exercises Yet"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms or browse all exercises."
        } else if selectedFilter != .all {
            return "You don't have any exercises in this category yet."
        } else {
            return "Start building your exercise library by creating your first custom exercise."
        }
    }
}

// MARK: - Supporting Views

struct ExerciseFilterChip: View {
    @Environment(\.appTheme) var theme
    
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : theme.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? theme.primary : theme.primary.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedExerciseCard: View {
    @Environment(\.appTheme) var theme
    let exercise: Exercise
    
    var body: some View {
        ThemedCard {
            HStack(spacing: 16) {
                // Exercise type icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.secondary.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: exerciseTypeIcon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(theme.secondary)
                }
                
                // Exercise details
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                        .lineLimit(1)
                    
                    if let description = exercise.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)
                            .lineLimit(2)
                    }
                    
                    // Tags
                    HStack(spacing: 8) {
                        if let muscleGroup = exercise.muscleGroup {
                            ExerciseTag(text: muscleGroup, color: theme.accent)
                        }
                        
                        if let difficulty = exercise.difficulty {
                            ExerciseTag(text: difficulty, color: theme.primary)
                        }
                    }
                }
                
                Spacer()
                
                // Action indicators
                VStack(spacing: 8) {
                    if exercise.videoUrl != nil {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(theme.primary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.tertiaryText)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var exerciseTypeIcon: String {
        // You could map different exercise types to different icons
        if let muscleGroup = exercise.muscleGroup?.lowercased() {
            switch muscleGroup {
            case "chest": return "figure.strengthtraining.traditional"
            case "back": return "figure.rowing"
            case "legs": return "figure.walk"
            case "arms": return "dumbbell.fill"
            case "core": return "figure.core.training"
            default: return "figure.strengthtraining.traditional"
            }
        }
        return "figure.strengthtraining.traditional"
    }
}

struct ExerciseTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(8)
    }
}

#Preview {
    PolishedTrainerExerciseListView(
        viewModel: TrainerExerciseListViewModel(
            apiService: APIService(authService: AuthService()),
            authService: AuthService()
        )
    )
    .environmentObject(ToastManager())
    .environment(\.appTheme, AppTheme.trainer)
}
