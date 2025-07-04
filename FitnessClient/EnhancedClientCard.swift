// EnhancedClientCard.swift
import SwiftUI

struct EnhancedClientCard: View {
    let client: UserResponse
    let apiService: APIService
    let onTap: () -> Void
    
    @Environment(\.appTheme) var theme
    @State private var isPressed = false
    @State private var showingWorkoutAssignment = false
    @State private var showingClientProgress = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Main client info
                clientInfoSection
                
                // Action buttons
                actionButtonsSection
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.cardBorder, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {
            // Long press action if needed
        }
        .sheet(isPresented: $showingWorkoutAssignment) {
            PolishedWorkoutAssignmentView(client: client, apiService: apiService)
        }
        .sheet(isPresented: $showingClientProgress) {
            PolishedClientProgressView(client: client, apiService: apiService)
        }
    }
    
    // MARK: - Client Info Section
    
    private var clientInfoSection: some View {
        HStack(spacing: 20) {
            // Avatar
            clientAvatar
            
            // Client details
            VStack(alignment: .leading, spacing: 8) {
                // Name and status
                HStack {
                    Text(client.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(theme.primaryText)
                    
                    Spacer()
                    
                    clientStatusBadge
                }
                
                // Email
                Text(client.email)
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                
                // Client since
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                    
                    Text("Client since \(formatDate(client.createdAt))")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(20)
    }
    
    // MARK: - Client Avatar
    
    private var clientAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [theme.primary.opacity(0.2), theme.secondary.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 70, height: 70)
            
            Text(client.name.prefix(2).uppercased())
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.primary)
        }
    }
    
    // MARK: - Client Status Badge
    
    private var clientStatusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            
            Text("Active")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.green.opacity(0.1))
        )
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        HStack(spacing: 1) {
            // Assign workout button
            actionButton(
                icon: "dumbbell.fill",
                title: "Assign Workout",
                color: theme.primary,
                action: {
                    showingWorkoutAssignment = true
                }
            )
            
            // Divider
            Rectangle()
                .fill(theme.cardBorder)
                .frame(width: 1, height: 50)
            
            // View progress button
            actionButton(
                icon: "chart.line.uptrend.xyaxis",
                title: "View Progress",
                color: theme.secondary,
                action: {
                    showingClientProgress = true
                }
            )
            
            // Divider
            Rectangle()
                .fill(theme.cardBorder)
                .frame(width: 1, height: 50)
            
            // Message button
            actionButton(
                icon: "message.fill",
                title: "Send Message",
                color: Color.blue,
                action: {
                    // Message action
                }
            )
        }
        .background(
            Rectangle()
                .fill(theme.cardBackground.opacity(0.5))
        )
    }
    
    private func actionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - List Version

struct EnhancedClientListRow: View {
    let client: UserResponse
    let apiService: APIService
    let onTap: () -> Void
    
    @Environment(\.appTheme) var theme
    @State private var showingWorkoutAssignment = false
    @State private var showingClientProgress = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.primary.opacity(0.2), theme.secondary.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Text(client.name.prefix(2).uppercased())
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(theme.primary)
                }
                
                // Client info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(client.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryText)
                        
                        Spacer()
                        
                        // Status badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            
                            Text("Active")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text(client.email)
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                    
                    Text("Client since \(formatDate(client.createdAt))")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
                
                // Action buttons
                HStack(spacing: 8) {
                    Button(action: {
                        showingWorkoutAssignment = true
                    }) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 16))
                            .foregroundColor(theme.primary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(theme.primary.opacity(0.1))
                            )
                    }
                    
                    Button(action: {
                        showingClientProgress = true
                    }) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 16))
                            .foregroundColor(theme.secondary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(theme.secondary.opacity(0.1))
                            )
                    }
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
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingWorkoutAssignment) {
            PolishedWorkoutAssignmentView(client: client, apiService: apiService)
        }
        .sheet(isPresented: $showingClientProgress) {
            PolishedClientProgressView(client: client, apiService: apiService)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 16) {
        EnhancedClientCard(
            client: UserResponse(
                id: "1",
                name: "John Doe",
                email: "john@example.com",
                roles: ["client"],
                createdAt: Date(),
                clientIds: nil,
                trainerId: "trainer1"
            ),
            apiService: APIService(authService: AuthService()),
            onTap: {}
        )
        
        EnhancedClientListRow(
            client: UserResponse(
                id: "2",
                name: "Jane Smith",
                email: "jane@example.com",
                roles: ["client"],
                createdAt: Date(),
                clientIds: nil,
                trainerId: "trainer1"
            ),
            apiService: APIService(authService: AuthService()),
            onTap: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .environment(\.appTheme, AppTheme.trainer)
}
