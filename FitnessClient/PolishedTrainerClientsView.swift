// PolishedTrainerClientsView.swift
import SwiftUI

struct PolishedTrainerClientsView: View {
    @StateObject private var viewModel: TrainerClientsViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    
    @State private var searchText = ""
    @State private var selectedFilter: ClientFilter = .all
    @State private var showingFilters = false
    @State private var showingAddClient = false
    @State private var selectedViewMode: ViewMode = .cards
    
    enum ClientFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case inactive = "Inactive"
        case newClients = "New"
        
        var icon: String {
            switch self {
            case .all: return "person.2.fill"
            case .active: return "checkmark.circle.fill"
            case .inactive: return "pause.circle.fill"
            case .newClients: return "star.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .active: return .green
            case .inactive: return .orange
            case .newClients: return .purple
            }
        }
    }
    
    enum ViewMode: String, CaseIterable {
        case cards = "Cards"
        case list = "List"
        
        var icon: String {
            switch self {
            case .cards: return "rectangle.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
    init(viewModel: TrainerClientsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom header
                    headerSection
                    
                    // Search and controls
                    searchAndControlsSection
                    
                    // Main content
                    mainContent
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddClient) {
                PolishedAddClientView(
                    apiService: viewModel.apiService,
                    onClientAdded: {
                        Task {
                            await viewModel.refreshClients()
                        }
                    }
                )
            }
            .onAppear {
                if viewModel.items.isEmpty {
                    Task {
                        await viewModel.fetchManagedClients()
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
                            Text("My Clients")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Manage and track client progress")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        // Quick stats
                        HStack(spacing: 16) {
                            QuickStatBadge(
                                value: "\(viewModel.items.count)",
                                label: "Total",
                                color: .white
                            )
                            
                            QuickStatBadge(
                                value: "\(activeClientsCount)",
                                label: "Active",
                                color: theme.success
                            )
                        }
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
    
    // MARK: - Search and Controls Section
    
    private var searchAndControlsSection: some View {
        VStack(spacing: 12) {
            // Search bar and view mode toggle
            HStack(spacing: 12) {
                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.secondaryText)
                    
                    TextField("Search clients...", text: $searchText)
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
                
                // View mode toggle
                HStack(spacing: 4) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Button(action: {
                            selectedViewMode = mode
                        }) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(selectedViewMode == mode ? .white : theme.primary)
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedViewMode == mode ? theme.primary : theme.surface)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(4)
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
                        ForEach(ClientFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                icon: filter.icon,
                                color: filter.color,
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
            if viewModel.isLoading && viewModel.items.isEmpty {
                PulsingLoadingView(message: "Loading your clients...")
            } else if filteredClients.isEmpty && !viewModel.isLoading {
                emptyStateView
            } else {
                clientsContent
            }
        }
    }
    
    private var clientsContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Add client card
                addClientCard
                
                // Clients list/grid
                if selectedViewMode == .cards {
                    clientCardsView
                } else {
                    clientListView
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Tab bar padding
        }
        .refreshable {
            await viewModel.refreshClients()
        }
    }
    
    // MARK: - Add Client Card
    
    private var addClientCard: some View {
        Button(action: {
            showingAddClient = true
        }) {
            ThemedCard {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(theme.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add New Client")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryText)
                        
                        Text("Invite a new client to join your training program")
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
    
    // MARK: - Client Cards View
    
    private var clientCardsView: some View {
        LazyVStack(spacing: 16) {
            ForEach(filteredClients, id: \.id) { client in
                EnhancedClientCard(
                    client: client,
                    apiService: viewModel.apiService,
                    onTap: {
                        // Navigate to client detail
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: filteredClients)
    }
    
    // MARK: - Client List View
    
    private var clientListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredClients, id: \.id) { client in
                EnhancedClientListRow(
                    client: client,
                    apiService: viewModel.apiService,
                    onTap: {
                        // Navigate to client detail
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: filteredClients)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Empty state illustration
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.2.badge.plus")
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
            
            PulseButton(title: "Add Your First Client") {
                showingAddClient = true
            }
            .frame(maxWidth: 250)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Computed Properties
    
    private var filteredClients: [UserResponse] {
        var clients = viewModel.items
        
        // Apply search filter
        if !searchText.isEmpty {
            clients = clients.filter { client in
                client.name.localizedCaseInsensitiveContains(searchText) ||
                client.email.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            // Filter active clients (this would need real activity data)
            break
        case .inactive:
            // Filter inactive clients
            break
        case .newClients:
            // Filter new clients (joined recently)
            clients = clients.sorted { $0.createdAt > $1.createdAt }.prefix(5).map { $0 }
        }
        
        return clients
    }
    
    private var activeClientsCount: Int {
        // This would be calculated based on real activity data
        return max(0, viewModel.items.count - 2)
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Clients Found"
        } else if selectedFilter != .all {
            return "No \(selectedFilter.rawValue) Clients"
        } else {
            return "No Clients Yet"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms or browse all clients."
        } else if selectedFilter != .all {
            return "You don't have any clients in this category yet."
        } else {
            return "Start building your client base by adding your first client to begin their fitness journey."
        }
    }
}

// MARK: - Supporting Views

struct QuickStatBadge: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FilterChip: View {
    @Environment(\.appTheme) var theme
    
    let title: String
    let icon: String
    let color: Color
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
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? color : color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ClientCard: View {
    @Environment(\.appTheme) var theme
    let client: UserResponse
    
    var body: some View {
        ThemedCard {
            VStack(spacing: 12) {
                // Client avatar and basic info
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Text(client.name.prefix(2).uppercased())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(theme.primary)
                    }
                    
                    Text(client.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                        .lineLimit(1)
                    
                    Text(client.email)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                        .lineLimit(1)
                }
                
                // Progress ring (mock data)
                ZStack {
                    Circle()
                        .stroke(theme.cardBorder, lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: 0.7) // Mock 70% progress
                        .stroke(theme.success, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Text("70%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(theme.success)
                }
                
                // Quick stats
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("12")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                        
                        Text("Workouts")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }
                    
                    VStack(spacing: 2) {
                        Text("5")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                        
                        Text("Streak")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }
                }
                
                // Action buttons
                HStack(spacing: 8) {
                    ClientActionButton(
                        icon: "message.fill",
                        color: theme.primary
                    ) {
                        // Message client
                    }
                    
                    ClientActionButton(
                        icon: "plus.circle.fill",
                        color: theme.secondary
                    ) {
                        // Assign workout
                    }
                    
                    ClientActionButton(
                        icon: "chart.bar.fill",
                        color: theme.accent
                    ) {
                        // View progress
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct ClientListRow: View {
    @Environment(\.appTheme) var theme
    let client: UserResponse
    
    var body: some View {
        ThemedCard {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(theme.primary.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Text(client.name.prefix(2).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.primary)
                }
                
                // Client info
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                    
                    Text(client.email)
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                    
                    // Status and stats
                    HStack(spacing: 12) {
                        StatusIndicator(status: "Active", color: theme.success)
                        
                        Text("12 workouts")
                            .font(.caption)
                            .foregroundColor(theme.tertiaryText)
                        
                        Text("5 day streak")
                            .font(.caption)
                            .foregroundColor(theme.tertiaryText)
                    }
                }
                
                Spacer()
                
                // Progress and actions
                VStack(spacing: 8) {
                    CircularProgressView(progress: 0.7, size: 40)
                    
                    HStack(spacing: 4) {
                        ClientActionButton(
                            icon: "message.fill",
                            color: theme.primary,
                            size: 28
                        ) {
                            // Message client
                        }
                        
                        ClientActionButton(
                            icon: "plus.circle.fill",
                            color: theme.secondary,
                            size: 28
                        ) {
                            // Assign workout
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct ClientActionButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let action: () -> Void
    
    init(icon: String, color: Color, size: CGFloat = 32, action: @escaping () -> Void) {
        self.icon = icon
        self.color = color
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(color)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatusIndicator: View {
    let status: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            
            Text(status)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct AddClientView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.appTheme) var theme
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add Client Feature")
                    .font(.title)
                    .padding()
                
                Text("This would be the client invitation interface")
                    .foregroundColor(theme.secondaryText)
                
                Spacer()
            }
            .navigationTitle("Add Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PolishedTrainerClientsView(
        viewModel: TrainerClientsViewModel(apiService: APIService(authService: AuthService()))
    )
    .environmentObject(ToastManager())
    .environment(\.appTheme, AppTheme.trainer)
}
