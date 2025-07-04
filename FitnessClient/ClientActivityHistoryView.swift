// ClientActivityHistoryView.swift
import SwiftUI

struct ClientActivityHistoryView: View {
    let apiService: APIService
    let authService: AuthService
    
    @StateObject private var viewModel: ClientActivityHistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) var theme
    
    init(apiService: APIService, authService: AuthService) {
        self.apiService = apiService
        self.authService = authService
        self._viewModel = StateObject(wrappedValue: ClientActivityHistoryViewModel(apiService: apiService))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.workoutSessions.isEmpty {
                    loadingView
                } else if viewModel.workoutSessions.isEmpty {
                    emptyStateView
                } else {
                    activityList
                }
            }
            .navigationTitle("Activity History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchWorkoutHistory()
                }
            }
        }
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(theme.primary)
            
            Text("Loading your activity...")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundColor(theme.primary.opacity(0.6))
            
            Text("No Activity Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            Text("Complete your first workout to see your activity history here.")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var activityList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.workoutSessions) { session in
                    ActivityCard(session: session, theme: theme)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
}

// MARK: - Activity Card

struct ActivityCard: View {
    let session: WorkoutSession
    let theme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.workoutName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                    
                    Text(formatDate(session.completedAt))
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                }
                
                Spacer()
                
                // Completion badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("\(Int(session.completionPercentage * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.primaryText)
                }
            }
            
            // Stats
            HStack(spacing: 20) {
                StatItem(
                    icon: "clock",
                    value: "\(session.duration)",
                    unit: "min",
                    theme: theme
                )
                
                StatItem(
                    icon: "list.bullet",
                    value: "\(session.exercisesCompleted)",
                    unit: "exercises",
                    theme: theme
                )
                
                Spacer()
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let unit: String
    let theme: AppTheme
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(theme.primary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.primaryText)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(theme.secondaryText)
        }
    }
}

// MARK: - View Model

@MainActor
class ClientActivityHistoryViewModel: ObservableObject {
    @Published var workoutSessions: [WorkoutSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func fetchWorkoutHistory() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let sessions: [WorkoutSession] = try await apiService.GET(endpoint: "/client/workout-sessions")
            self.workoutSessions = sessions.sorted { $0.completedAt > $1.completedAt }
            print("ClientActivityHistoryVM: Fetched \(sessions.count) workout sessions")
        } catch {
            print("ClientActivityHistoryVM: Error fetching workout history: \(error)")
            errorMessage = "Failed to load activity history"
            workoutSessions = []
        }
        
        isLoading = false
    }
}

#Preview {
    ClientActivityHistoryView(
        apiService: APIService(authService: AuthService()),
        authService: AuthService()
    )
    .environment(\.appTheme, AppTheme.client)
}
