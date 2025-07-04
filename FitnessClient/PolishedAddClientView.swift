// PolishedAddClientView.swift
import SwiftUI

struct PolishedAddClientView: View {
    @StateObject private var viewModel: AddClientViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.appTheme) var theme
    @Environment(\.dismiss) var dismiss
    
    @State private var showingSuccessAnimation = false
    @State private var pulseAnimation = false
    
    let onClientAdded: () -> Void
    
    init(apiService: APIService, onClientAdded: @escaping () -> Void = {}) {
        self._viewModel = StateObject(wrappedValue: AddClientViewModel(apiService: apiService, toastManager: ToastManager()))
        self.onClientAdded = onClientAdded
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                theme.background.ignoresSafeArea()
                
                if showingSuccessAnimation {
                    successView
                } else {
                    mainContent
                }
            }
            .navigationTitle("Add Client")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
        .onChange(of: viewModel.didAddClientSuccessfully) { success in
            if success {
                showSuccessAnimation()
            }
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header section
                headerSection
                
                // Email input section
                emailInputSection
                
                // Add button
                addClientButton
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    errorSection(errorMessage)
                }
                
                // Info section
                infoSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.primary.opacity(0.2), theme.secondary.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(theme.primary)
            }
            
            // Title and description
            VStack(spacing: 8) {
                Text("Add New Client")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                
                Text("Enter your client's email address to add them to your roster")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Email Input Section
    
    private var emailInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Client Email Address")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            HStack {
                Image(systemName: "envelope")
                    .font(.system(size: 18))
                    .foregroundColor(theme.secondaryText)
                    .frame(width: 24)
                
                TextField("client@example.com", text: $viewModel.clientEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    .font(.body)
                    .foregroundColor(theme.primaryText)
                    .onSubmit {
                        Task { await addClient() }
                    }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        viewModel.errorMessage != nil ? Color.red : theme.cardBorder,
                        lineWidth: 1
                    )
            )
        }
    }
    
    // MARK: - Add Client Button
    
    private var addClientButton: some View {
        Button(action: {
            Task { await addClient() }
        }) {
            HStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(.white)
                } else {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(viewModel.isLoading ? "Adding Client..." : "Add Client")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isButtonEnabled ? 
                        LinearGradient(
                            colors: [theme.primary, theme.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .scaleEffect(pulseAnimation ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: pulseAnimation)
        }
        .disabled(!isButtonEnabled)
        .onTapGesture {
            pulseAnimation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pulseAnimation = false
            }
        }
    }
    
    private var isButtonEnabled: Bool {
        !viewModel.clientEmail.isEmpty && !viewModel.isLoading && isValidEmail(viewModel.clientEmail)
    }
    
    // MARK: - Error Section
    
    private func errorSection(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How it works")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            VStack(spacing: 12) {
                infoItem(
                    icon: "1.circle.fill",
                    title: "Enter Email",
                    description: "Type the email address of your client"
                )
                
                infoItem(
                    icon: "2.circle.fill",
                    title: "We Find Them",
                    description: "We'll search for an existing user with that email"
                )
                
                infoItem(
                    icon: "3.circle.fill",
                    title: "Connection Made",
                    description: "They'll be added to your client roster"
                )
            }
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
    
    private func infoItem(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(theme.primary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success animation
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }
                .scaleEffect(showingSuccessAnimation ? 1.0 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSuccessAnimation)
                
                VStack(spacing: 12) {
                    Text("Client Added!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(theme.primaryText)
                    
                    Text("Your new client has been successfully added to your roster")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            Spacer()
            
            // Done button
            Button("Done") {
                onClientAdded()
                dismiss()
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green)
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Methods
    
    private func addClient() async {
        await viewModel.addClient()
    }
    
    private func showSuccessAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingSuccessAnimation = true
        }
        
        // Auto-dismiss after showing success
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onClientAdded()
            dismiss()
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    PolishedAddClientView(
        apiService: APIService(authService: AuthService())
    )
    .environmentObject(ToastManager())
    .environment(\.appTheme, AppTheme.trainer)
}
