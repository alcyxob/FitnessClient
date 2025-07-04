// OfflineComponents.swift
import SwiftUI

// MARK: - Offline Status Banner
struct OfflineStatusBanner: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @EnvironmentObject var syncManager: SyncManager
    @Environment(\.appTheme) var theme
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 12) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("You're offline")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Data will sync when connection is restored")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                if let lastSync = syncManager.lastSyncDate {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Last sync")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(RelativeDateTimeFormatter().localizedString(for: lastSync, relativeTo: Date()))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.orange, Color.red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Sync Status Indicator
struct SyncStatusIndicator: View {
    @EnvironmentObject var syncManager: SyncManager
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.appTheme) var theme
    
    let showText: Bool
    
    init(showText: Bool = true) {
        self.showText = showText
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // Status icon
            Group {
                if syncManager.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                } else if networkMonitor.isConnected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.success)
                } else {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.orange)
                }
            }
            .font(.system(size: 14))
            
            if showText {
                Text(statusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(statusColor)
            }
        }
    }
    
    private var statusText: String {
        if syncManager.isSyncing {
            return "Syncing..."
        } else if networkMonitor.isConnected {
            if let lastSync = syncManager.lastSyncDate {
                let formatter = RelativeDateTimeFormatter()
                formatter.dateTimeStyle = .named
                return "Synced \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
            } else {
                return "Online"
            }
        } else {
            return "Offline"
        }
    }
    
    private var statusColor: Color {
        if syncManager.isSyncing {
            return theme.primary
        } else if networkMonitor.isConnected {
            return theme.success
        } else {
            return .orange
        }
    }
}

// MARK: - Sync Button
struct SyncButton: View {
    @EnvironmentObject var syncManager: SyncManager
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.appTheme) var theme
    
    let onSync: (() async -> Void)?
    
    init(onSync: (() async -> Void)? = nil) {
        self.onSync = onSync
    }
    
    var body: some View {
        Button(action: {
            Task {
                if let onSync = onSync {
                    await onSync()
                } else {
                    await syncManager.forcSync()
                }
            }
        }) {
            HStack(spacing: 6) {
                if syncManager.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Text(syncManager.isSyncing ? "Syncing..." : "Sync")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                networkMonitor.isConnected ? theme.primary : Color.gray
            )
            .cornerRadius(6)
        }
        .disabled(!networkMonitor.isConnected || syncManager.isSyncing)
    }
}

// MARK: - Offline Data Badge
struct OfflineDataBadge: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.appTheme) var theme
    
    let itemCount: Int
    let itemType: String
    
    var body: some View {
        if !networkMonitor.isConnected && itemCount > 0 {
            HStack(spacing: 4) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 10, weight: .semibold))
                
                Text("\(itemCount) \(itemType) offline")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(theme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.accent.opacity(0.1))
            .cornerRadius(4)
        }
    }
}

// MARK: - Connection Type Indicator
struct ConnectionTypeIndicator: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.appTheme) var theme
    
    var body: some View {
        if networkMonitor.isConnected, let connectionType = networkMonitor.connectionType {
            HStack(spacing: 4) {
                Image(systemName: connectionIcon)
                    .font(.system(size: 12))
                    .foregroundColor(theme.success)
                
                Text(connectionText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.secondaryText)
            }
        }
    }
    
    private var connectionIcon: String {
        switch networkMonitor.connectionType {
        case .wifi:
            return "wifi"
        case .cellular:
            return "antenna.radiowaves.left.and.right"
        case .wiredEthernet:
            return "cable.connector"
        default:
            return "network"
        }
    }
    
    private var connectionText: String {
        switch networkMonitor.connectionType {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        default:
            return "Connected"
        }
    }
}

// MARK: - Offline-Aware List View
struct OfflineAwareListView<Item: Identifiable, Content: View>: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.appTheme) var theme
    
    let items: [Item]
    let isLoading: Bool
    let onRefresh: () async -> Void
    let onSync: (() async -> Void)?
    let emptyTitle: String
    let emptyMessage: String
    let emptyIcon: String
    let content: (Item) -> Content
    
    init(
        items: [Item],
        isLoading: Bool = false,
        onRefresh: @escaping () async -> Void,
        onSync: (() async -> Void)? = nil,
        emptyTitle: String,
        emptyMessage: String,
        emptyIcon: String,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.isLoading = isLoading
        self.onRefresh = onRefresh
        self.onSync = onSync
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self.emptyIcon = emptyIcon
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Offline status banner
            OfflineStatusBanner()
            
            // Main content
            if isLoading && items.isEmpty {
                ThemedProgressView(
                    message: networkMonitor.isConnected ? 
                    "Loading..." : "Loading from offline storage..."
                )
            } else if items.isEmpty {
                ThemedEmptyState(
                    title: emptyTitle,
                    message: networkMonitor.isConnected ? 
                    emptyMessage : "\(emptyMessage)\n\nYou're currently offline. Data will sync when connection is restored.",
                    icon: emptyIcon
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Sync status header
                        if !items.isEmpty {
                            HStack {
                                OfflineDataBadge(
                                    itemCount: items.count,
                                    itemType: "items"
                                )
                                
                                Spacer()
                                
                                SyncStatusIndicator()
                                
                                if let onSync = onSync {
                                    SyncButton(onSync: onSync)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                        }
                        
                        // List items
                        ForEach(items) { item in
                            content(item)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .refreshable {
            await onRefresh()
        }
    }
}

// MARK: - Offline Settings Section
struct OfflineSettingsSection: View {
    @EnvironmentObject var syncManager: SyncManager
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @Environment(\.appTheme) var theme
    
    var body: some View {
        ThemedCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.primary)
                    
                    Text("Offline & Sync")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                    
                    Spacer()
                }
                
                // Connection status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Connection Status")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.primaryText)
                        
                        HStack(spacing: 8) {
                            SyncStatusIndicator(showText: false)
                            
                            Text(networkMonitor.isConnected ? "Online" : "Offline")
                                .font(.subheadline)
                                .foregroundColor(
                                    networkMonitor.isConnected ? theme.success : .orange
                                )
                            
                            ConnectionTypeIndicator()
                        }
                    }
                    
                    Spacer()
                    
                    SyncButton()
                }
                
                // Last sync info
                if let lastSync = syncManager.lastSyncDate {
                    HStack {
                        Text("Last sync:")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                        
                        Text(RelativeDateTimeFormatter().localizedString(for: lastSync, relativeTo: Date()))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(theme.primaryText)
                        
                        Spacer()
                    }
                }
                
                // Sync errors
                if !syncManager.syncErrors.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sync Issues:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        
                        ForEach(syncManager.syncErrors, id: \.self) { error in
                            Text("• \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Info text
                Text("Your data is automatically saved offline and will sync when you're connected to the internet.")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
                    .italic()
            }
        }
        .padding(.horizontal, 16)
    }
}
