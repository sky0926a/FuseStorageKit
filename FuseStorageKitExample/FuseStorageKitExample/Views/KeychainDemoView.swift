import SwiftUI

/// Demonstration view for Keychain functionality
struct KeychainDemoView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var token = ""
    @State private var biometricEnabled = false
    @State private var showMessage = false
    @State private var message = ""
    
    
    var body: some View {
        NavigationView {
            List {
                // User Authentication Section
                Section("User Authentication") {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        SecureField("Token", text: $token)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        HStack {
                            Button("Save Credentials") {
                                saveUserCredentials()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(username.isEmpty || password.isEmpty || token.isEmpty)
                            
                            Spacer()
                            
                            Button("Load Password") {
                                loadUserPassword()
                            }
                            .buttonStyle(.bordered)
                            .disabled(username.isEmpty)
                        }
                    }
                }
                
                
                // Auth Status Section
                Section("Authentication Status") {
                    HStack {
                        Text("Login Status:")
                        Spacer()
                        Text(AppStorage.shared.isUserLoggedIn() ? "Logged In" : "Not Logged In")
                            .foregroundColor(AppStorage.shared.isUserLoggedIn() ? .green : .red)
                    }
                }
                
                // Actions Section
                Section("Actions") {
                    Button("Clear All Auth Data") {
                        clearAllAuthData()
                    }
                    .foregroundColor(.red)
                    
                    Button("Clear User Password") {
                        clearUserPassword()
                    }
                    .foregroundColor(.orange)
                    .disabled(username.isEmpty)
                }
            }
            .navigationTitle("Keychain Usage")
            .alert("Message", isPresented: $showMessage) {
                Button("OK") {}
            } message: {
                Text(message)
            }
            .onAppear {
                loadUserPassword()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func saveUserCredentials() {
        AppStorage.shared.saveUserPassword(password, for: username)
        AppStorage.shared.saveUserToken(token)
        showMessage(text: "Credentials saved to Keychain")
    }
    
    private func loadUserPassword() {
        if let savedPassword = AppStorage.shared.getUserPassword(for: username), let savedToken = AppStorage.shared.getUserToken() {
            password = savedPassword
            token = savedToken
            showMessage(text: "Password / keychain loaded from Keychain")
        } else {
            showMessage(text: "No password or keychain found for user: \(username)")
        }
    }
    
    private func clearAllAuthData() {
        AppStorage.shared.clearUserAuth()
        token = ""
        showMessage(text: "All authentication data cleared")
    }
    
    private func clearUserPassword() {
        AppStorage.shared.clearUserPassword(for: username)
        password = ""
        showMessage(text: "Password cleared for user: \(username)")
    }
    
    private func showMessage(text: String) {
        message = text
        showMessage = true
    }
}

#Preview {
    KeychainDemoView()
} 
