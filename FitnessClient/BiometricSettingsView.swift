// BiometricSettingsView.swift
import SwiftUI
import LocalAuthentication

struct BiometricSettingsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Security Settings")) {
                HStack {
                    Image(systemName: biometricIcon)
                        .foregroundColor(authService.biometricType == .none ? .gray : .blue)
                    VStack(alignment: .leading) {
                        Text("Biometric Authentication")
                            .font(.headline)
                        Text(biometricDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { authService.biometricAuthEnabled },
                        set: { newValue in
                            Task {
                                await toggleBiometric(newValue)
                            }
                        }
                    ))
                    .disabled(authService.biometricType == .none)
                }
            }
            
            Section(footer: Text(footerText)) {
                EmptyView()
            }
        }
        .navigationTitle("Security")
        .alert("Biometric Authentication", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var biometricIcon: String {
        switch authService.biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.shield"
        }
    }
    
    private var biometricDescription: String {
        switch authService.biometricType {
        case .faceID:
            return "Use Face ID to secure your account"
        case .touchID:
            return "Use Touch ID to secure your account"
        default:
            return "Biometric authentication not available"
        }
    }
    
    private var biometricTypeString: String {
        switch authService.biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "biometric authentication"
        }
    }
    
    private var footerText: String {
        if authService.biometricType == .none {
            return "Biometric authentication is not available on this device or in the simulator."
        } else {
            return "When enabled, you'll need to authenticate with \(biometricTypeString) to access your fitness data."
        }
    }
    
    private func toggleBiometric(_ enabled: Bool) async {
        if enabled {
            let success = await authService.enableBiometricAuth()
            if !success {
                alertMessage = "Failed to enable biometric authentication. Please ensure biometric authentication is enabled in your device settings."
                showingAlert = true
            } else {
                alertMessage = "Biometric authentication enabled successfully!"
                showingAlert = true
            }
        } else {
            authService.disableBiometricAuth()
            alertMessage = "Biometric authentication disabled."
            showingAlert = true
        }
    }
}

#Preview {
    NavigationView {
        BiometricSettingsView()
            .environmentObject(AuthService())
    }
}
