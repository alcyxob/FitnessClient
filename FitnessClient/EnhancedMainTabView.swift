// EnhancedMainTabView.swift
import SwiftUI

struct EnhancedMainTabView: View {
    let apiService: APIService
    let authService: AuthService
    let appModeManager: AppModeManager
    
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    
    var body: some View {
        ZStack {
            // Background
            theme.background.ignoresSafeArea()
            
            // Main content with page transitions
            VStack(spacing: 0) {
                // Content area
                ZStack {
                    if let user = authService.loggedInUser {
                        if user.roles.contains("client") && appModeManager.currentMode == .client {
                            clientContent
                        } else if user.roles.contains("trainer") && appModeManager.currentMode == .trainer {
                            trainerContent
                        }
                    } else {
                        // Fallback content
                        Text("Please log in")
                            .font(.title2)
                            .foregroundColor(theme.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Enhanced Tab Bar
                EnhancedTabBarView(
                    selectedTab: $selectedTab,
                    tabs: currentTabs
                )
            }
        }
        .onChange(of: selectedTab) { newValue in
            // Add haptic feedback for tab changes
            HapticManager.shared.selection()
            
            // Track previous tab for transition animations
            previousTab = newValue
        }
    }
    
    // MARK: - Client Content
    
    private var clientContent: some View {
        ZStack {
            Group {
                switch selectedTab {
                case 0:
                    PolishedClientDashboardView(apiService: apiService, authService: authService)
                        .pageTransition(isActive: selectedTab == 0, direction: .leading)
                        
                case 1:
                    PolishedClientPlansView(apiService: apiService)
                        .pageTransition(isActive: selectedTab == 1, direction: selectedTab > previousTab ? .trailing : .leading)
                        
                case 2:
                    ClientProgressView
                        .pageTransition(isActive: selectedTab == 2, direction: selectedTab > previousTab ? .trailing : .leading)
                        
                case 3:
                    PolishedSettingsView(viewModel: SettingsViewModel(apiService: apiService, authService: authService, appModeManager: appModeManager))
                        .pageTransition(isActive: selectedTab == 3, direction: .trailing)
                        
                default:
                    EmptyView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
    }
    
    // MARK: - Trainer Content
    
    private var trainerContent: some View {
        ZStack {
            Group {
                switch selectedTab {
                case 0:
                    PolishedTrainerDashboardView(apiService: apiService, authService: authService)
                        .pageTransition(isActive: selectedTab == 0, direction: .leading)
                        
                case 1:
                    PolishedTrainerExerciseListView(viewModel: TrainerExerciseListViewModel(apiService: apiService, authService: authService))
                        .pageTransition(isActive: selectedTab == 1, direction: selectedTab > previousTab ? .trailing : .leading)
                        
                case 2:
                    PolishedTrainerClientsView(viewModel: TrainerClientsViewModel(apiService: apiService))
                        .pageTransition(isActive: selectedTab == 2, direction: selectedTab > previousTab ? .trailing : .leading)
                        
                case 3:
                    PolishedSettingsView(viewModel: SettingsViewModel(apiService: apiService, authService: authService, appModeManager: appModeManager))
                        .pageTransition(isActive: selectedTab == 3, direction: .trailing)
                        
                default:
                    EmptyView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
    }
    
    // MARK: - Client Progress View
    
    private var ClientProgressView: some View {
        EnhancedNavigationView {
            VStack(spacing: 20) {
                Text("Client Progress")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                
                Text("Beautiful progress tracking coming soon!")
                    .font(.body)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                
                // Mock progress cards
                VStack(spacing: 16) {
                    ProgressCard(
                        title: "Weekly Goal",
                        progress: 0.75,
                        subtitle: "3 of 4 workouts completed"
                    )
                    
                    ProgressCard(
                        title: "Monthly Streak",
                        progress: 0.6,
                        subtitle: "18 day streak"
                    )
                    
                    ProgressCard(
                        title: "Total Workouts",
                        progress: 1.0,
                        subtitle: "127 workouts completed"
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 60)
            .background(theme.background)
        }
    }
    
    // MARK: - Progress Card
    
    private struct ProgressCard: View {
        @Environment(\.appTheme) var theme
        
        let title: String
        let progress: Double
        let subtitle: String
        
        var body: some View {
            ThemedCard {
                HStack(spacing: 16) {
                    CircularProgressView(progress: progress, size: 50)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryText)
                        
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .swipeActions(
                trailing: [
                    SwipeAction(title: "Share", icon: "square.and.arrow.up", color: theme.primary) {
                        HapticManager.shared.impact(.light)
                        print("Share progress")
                    }
                ]
            )
            .longPressMenu([
                MenuAction(title: "View Details", icon: "chart.bar", color: theme.primary) {
                    print("View details")
                },
                MenuAction(title: "Set Goal", icon: "target", color: theme.secondary) {
                    print("Set goal")
                },
                MenuAction(title: "Share", icon: "square.and.arrow.up", color: theme.accent) {
                    print("Share")
                }
            ])
        }
    }
    
    // MARK: - Current Tabs
    
    private var currentTabs: [TabItem] {
        if let user = authService.loggedInUser {
            if user.roles.contains("client") && appModeManager.currentMode == .client {
                return clientTabs
            } else if user.roles.contains("trainer") && appModeManager.currentMode == .trainer {
                return trainerTabs
            }
        }
        return []
    }
    
    private var clientTabs: [TabItem] {
        [
            TabItem(
                title: "Today",
                icon: "figure.mixed.cardio",
                selectedIcon: "figure.mixed.cardio",
                badgeCount: hasNewWorkouts ? 1 : nil
            ),
            TabItem(
                title: "My Plans",
                icon: "list.star",
                selectedIcon: "list.star"
            ),
            TabItem(
                title: "Progress",
                icon: "chart.bar.xaxis",
                selectedIcon: "chart.bar.xaxis"
            ),
            TabItem(
                title: "Settings",
                icon: "gearshape",
                selectedIcon: "gearshape.fill"
            )
        ]
    }
    
    private var trainerTabs: [TabItem] {
        [
            TabItem(
                title: "Dashboard",
                icon: "chart.bar.doc.horizontal",
                selectedIcon: "chart.bar.doc.horizontal"
            ),
            TabItem(
                title: "Exercises",
                icon: "figure.strengthtraining.traditional",
                selectedIcon: "figure.strengthtraining.traditional"
            ),
            TabItem(
                title: "Clients",
                icon: "person.2",
                selectedIcon: "person.2.fill",
                badgeCount: pendingClientRequests
            ),
            TabItem(
                title: "Settings",
                icon: "gearshape",
                selectedIcon: "gearshape.fill"
            )
        ]
    }
    
    // MARK: - Mock Badge Data
    
    private var hasNewWorkouts: Bool {
        // Mock logic for new workouts
        return true
    }
    
    private var pendingClientRequests: Int {
        // Mock logic for pending client requests
        return 2
    }
}

#Preview {
    EnhancedMainTabView(
        apiService: APIService(authService: AuthService()),
        authService: AuthService(),
        appModeManager: AppModeManager()
    )
    .environmentObject(ToastManager())
    .environmentObject(AppModeManager())
    .environmentObject(AppThemeManager(appModeManager: AppModeManager()))
    .environment(\.appTheme, AppTheme.client)
}
