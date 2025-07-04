// AddClientByEmailView.swift
import SwiftUI

struct AddClientByEmailView: View {
    @StateObject var viewModel: AddClientViewModel
    @Environment(\.dismiss) var dismiss // To close the sheet
    
    @State private var showingNotFoundAlert = false

    init(apiService: APIService, toastManager: ToastManager) {
        // View creates its own ViewModel instance
        _viewModel = StateObject(wrappedValue: AddClientViewModel(apiService: apiService, toastManager: toastManager))
    }

    var body: some View {
        NavigationView { // Often useful in sheets for title/buttons
            VStack(alignment: .leading, spacing: 20) {
                Text("Enter the email address of the client you want to add to your roster.")
                    .foregroundColor(.secondary)
                    .padding(.bottom)

                TextField("Client Email Address", text: $viewModel.clientEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .onSubmit { // Allow submitting from keyboard
                        Task { await viewModel.addClient() }
                    }

                if viewModel.isLoading {
                    ProgressView("Adding client...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Button("Add Client") {
                        Task {
                            await viewModel.addClient()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.clientEmail.isEmpty ? Color.gray : Color.blue) // Conditional background
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(viewModel.clientEmail.isEmpty || viewModel.isLoading)
                }

                if let errorMessage = viewModel.errorMessage, !isNotFoundError(errorMessage) {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.top)
                }

                Spacer() // Push content to top
            }
            .padding()
            .navigationTitle("Add Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: viewModel.didAddClientSuccessfully) { success in
                if success {
                    print("AddClientView: Client added successfully, dismissing.")
                    dismiss() // Dismiss sheet on success
                }
            }
            .onChange(of: viewModel.errorMessage) { newErrorMessage in
                if let msg = newErrorMessage, isNotFoundError(msg) {
                    self.showingNotFoundAlert = true
                }
            }
            .alert("Client Not Found", isPresented: $showingNotFoundAlert) {
                Button("OK") {
                    // Optionally clear the error message when alert is dismissed
                    viewModel.errorMessage = nil
                }
            } message: {
                Text("No client with the email '\(viewModel.clientEmail)' was found, or they are not available to be added. Please check the email and try again.")
            }
        }
    }

    // Helper to check for the specific error message
    private func isNotFoundError(_ message: String) -> Bool {
        // Match the error string set by your Go backend for ErrClientNotFound
        return message.lowercased().contains("404")
    }
}

struct AddClientByEmailView_Previews: PreviewProvider {
    static var previews: some View {
         let mockAuth = AuthService()
        let mockToast = ToastManager()
         // mockAuth.authToken = "fake" // Simulate login if needed by API Service init
        AddClientByEmailView(apiService: APIService(authService: mockAuth), toastManager: mockToast)
    }
}
