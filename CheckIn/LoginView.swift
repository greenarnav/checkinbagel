//
//  LoginView.swift
//  moodgpt
//
//  Created by Test on 6/5/25.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authManager: AuthManager
    @Binding var authMode: AuthMode
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var phoneNumber: String = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingPhoneInput = false
    @State private var needsPhoneNumber = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Back button
            HStack {
                Button(action: {
                    withAnimation {
                        authMode = .initial
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
            
            Spacer()
            
            // Header
            VStack(spacing: 15) {
                Text("Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Sign in to your account")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Login form
            VStack(spacing: 20) {
                // Username field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.headline)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    
                    TextField("Enter your username", text: $username)
                        .font(.body)
                        .foregroundColor(.black)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 20)
                        .frame(height: 55)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        )
                }
                
                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    
                    SecureField("Enter your password", text: $password)
                        .font(.body)
                        .foregroundColor(.black)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 20)
                        .frame(height: 55)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        )
                }
                
                // Login button
                Button(action: {
                    handleLogin()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Text(isLoading ? "Signing In..." : "Sign In")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isFormValid ? Color.blue.opacity(0.8) : Color.gray.opacity(0.3))
                    )
                }
                .disabled(!isFormValid || isLoading)
                .opacity(isFormValid && !isLoading ? 1.0 : 0.6)
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Footer
            VStack(spacing: 15) {
                Text("Don't have an account?")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                
                Button("Create Account") {
                    withAnimation {
                        authMode = .signup
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .underline()
            }
            .padding(.bottom, 30)
        }
        .trackScreenAuto(LoginView.self)
        .alert("Login Failed", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingPhoneInput) {
            PhoneNumberInputView(
                phoneNumber: $phoneNumber,
                isPresented: $showingPhoneInput,
                onSave: { phone in
                    savePhoneNumber(phone)
                }
            )
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func handleLogin() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedUsername.isEmpty else {
            showError("Please enter your username")
            return
        }
        
        guard !trimmedPassword.isEmpty else {
            showError("Please enter your password")
            return
        }
        
        isLoading = true
        
        // Call the login API
        loginWithAPI(username: trimmedUsername, password: trimmedPassword)
    }
    
    private func loginWithAPI(username: String, password: String) {
        // First check if user has phone number
        checkPhoneNumber(username: username) { hasPhone in
            if hasPhone {
                // User has phone number, proceed with normal login
                self.performLogin(username: username, password: password)
            } else {
                // User doesn't have phone number, ask for it first
                self.needsPhoneNumber = true
                self.showingPhoneInput = true
                self.isLoading = false
            }
        }
    }
    
    private func checkPhoneNumber(username: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://user-login-register-d6yw.onrender.com/check_phno") else {
            completion(false)
            return
        }
        
        let checkData = [
            "username": username
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: checkData, options: [])
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    guard let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                          let exists = json["exists"] as? Bool else {
                        completion(false)
                        return
                    }
                    completion(exists)
                }
            }.resume()
            
        } catch {
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
    
    private func performLogin(username: String, password: String) {
        guard let url = URL(string: "https://user-login-register-d6yw.onrender.com/login") else {
            showError("Invalid URL")
            isLoading = false
            return
        }
        
        let loginData = [
            "username": username,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: loginData, options: [])
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let error = error {
                        showError("Network error: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let data = data else {
                        showError("No data received")
                        return
                    }
                    
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            let success = json["success"] as? Bool ?? false
                            let message = json["message"] as? String ?? "Unknown error"
                            
                            if success {
                                // Login successful
                                authManager.handleSuccessfulLogin(username: username, name: username)
                                // No need to dismiss since the app will automatically navigate to ContentView
                            } else {
                                // Login failed
                                showError(message)
                            }
                        } else {
                            showError("Invalid response format")
                        }
                    } catch {
                        showError("Failed to parse response")
                    }
                }
            }.resume()
            
        } catch {
            isLoading = false
            showError("Failed to prepare request")
        }
    }
    
    private func savePhoneNumber(_ phone: String) {
        guard let url = URL(string: "https://user-login-register-d6yw.onrender.com/update_phno") else {
            showError("Invalid URL")
            return
        }
        
        let updateData: [String: Any] = [
            "username": username.trimmingCharacters(in: .whitespacesAndNewlines),
            "phno": Int(phone) ?? 0
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: updateData, options: [])
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.showingPhoneInput = false
                        showError("Failed to save phone number: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                          let success = json["success"] as? Bool else {
                        self.showingPhoneInput = false
                        showError("Failed to save phone number")
                        return
                    }
                    
                    if success {
                        // Phone number saved, now proceed with login
                        self.showingPhoneInput = false
                        self.performLogin(username: self.username.trimmingCharacters(in: .whitespacesAndNewlines), 
                                        password: self.password.trimmingCharacters(in: .whitespacesAndNewlines))
                    } else {
                        self.showingPhoneInput = false
                        showError("Failed to save phone number")
                    }
                }
            }.resume()
            
        } catch {
            showingPhoneInput = false
            showError("Failed to prepare phone number request")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Keyboard Helper Extension
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.2, blue: 0.4),
                Color(red: 0.2, green: 0.4, blue: 0.6),
                Color(red: 0.3, green: 0.5, blue: 0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        LoginView(authManager: AuthManager(), authMode: .constant(.login))
    }
    .preferredColorScheme(.dark)
} 
