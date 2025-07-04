// UseWorkoutTemplateView.swift
import SwiftUI

struct UseWorkoutTemplateView: View {
    let template: WorkoutTemplate
    let apiService: APIService
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.appTheme) var theme
    @State private var selectedClient: UserResponse?
    @State private var clients: [UserResponse] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Template preview
                    templatePreview
                    
                    // Client selection
                    clientSelection
                    
                    // Use template button
                    useTemplateButton
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Use Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
            .onAppear {
                loadClients()
            }
        }
    }
    
    private var templatePreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Template Preview")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(template.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                
                if let description = template.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                }
                
                HStack(spacing: 16) {
                    templateBadge(template.category.capitalized, color: .blue)
                    templateBadge(template.difficulty.capitalized, color: .orange)
                    templateBadge("\(template.estimatedDuration)m", color: .green)
                    templateBadge("\(template.exercises.count) exercises", color: .purple)
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
    }
    
    private func templateBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.1))
            )
    }
    
    private var clientSelection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Client")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            if clients.isEmpty {
                Text("No clients available")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.cardBackground)
                    )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(clients, id: \.id) { client in
                        clientRow(client)
                    }
                }
            }
        }
    }
    
    private func clientRow(_ client: UserResponse) -> some View {
        Button(action: {
            selectedClient = client
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(theme.primary.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Text(client.name.prefix(2).uppercased())
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(theme.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                    
                    Text(client.email)
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
                
                Spacer()
                
                if selectedClient?.id == client.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(theme.primary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedClient?.id == client.id ? theme.primary.opacity(0.1) : theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedClient?.id == client.id ? theme.primary : theme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var useTemplateButton: some View {
        Button(action: {
            useTemplate()
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(.white)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                }
                
                Text(isLoading ? "Creating Workout..." : "Create Workout from Template")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedClient != nil ? theme.primary : Color.gray.opacity(0.6))
            )
        }
        .disabled(selectedClient == nil || isLoading)
    }
    
    private func loadClients() {
        // Mock clients for now
        clients = [
            UserResponse(
                id: "1",
                name: "John Doe",
                email: "john@example.com",
                roles: ["client"],
                createdAt: Date(),
                clientIds: nil,
                trainerId: "trainer1"
            ),
            UserResponse(
                id: "2",
                name: "Jane Smith",
                email: "jane@example.com",
                roles: ["client"],
                createdAt: Date(),
                clientIds: nil,
                trainerId: "trainer1"
            )
        ]
    }
    
    private func useTemplate() {
        guard let client = selectedClient else { return }
        
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            dismiss()
        }
    }
}

#Preview {
    UseWorkoutTemplateView(
        template: WorkoutTemplate(
            name: "Upper Body Strength",
            description: "Complete upper body workout focusing on major muscle groups",
            category: "strength",
            difficulty: "intermediate",
            estimatedDuration: 45,
            exercises: []
        ),
        apiService: APIService(authService: AuthService())
    )
    .environment(\.appTheme, AppTheme.trainer)
}
