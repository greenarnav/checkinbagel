//
//  SignupView.swift
//  moodgpt
//
//  Created by Test on 6/5/25.
//

import SwiftUI

struct SignupView: View {
    @ObservedObject var authManager: AuthManager
    @Binding var authMode: AuthMode
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var phoneNumber: String = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingPhoneInput = false
    
    var body: some View {
        ScrollView {
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
                
                Spacer(minLength: 30)
                
                // Header
                VStack(spacing: 15) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Join CheckIn and connect with your feelings")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Signup form
                VStack(spacing: 20) {
                    // Username field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.headline)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        
                        TextField("Choose a username", text: $username)
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
                        
                        SecureField("Create a password", text: $password)
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
                    
                    // Confirm Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.headline)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        
                        SecureField("Confirm your password", text: $confirmPassword)
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
                                            .stroke(passwordsMatch ? Color.white : Color.red.opacity(0.8), lineWidth: 1)
                                    )
                            )
                        
                        if !confirmPassword.isEmpty && !passwordsMatch {
                            Text("Passwords do not match")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.8))
                        }
                    }
                    
                    // Password requirements
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Password must contain:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack(spacing: 5) {
                            Image(systemName: password.count >= 6 ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(password.count >= 6 ? .green : .white.opacity(0.5))
                            Text("At least 6 characters")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Signup button
                    Button(action: {
                        handleSignup()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text(isLoading ? "Creating Account..." : "Create Account")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isFormValid ? Color.green.opacity(0.8) : Color.gray.opacity(0.3))
                        )
                    }
                    .disabled(!isFormValid || isLoading)
                    .opacity(isFormValid && !isLoading ? 1.0 : 0.6)
                }
                .padding(.horizontal, 30)
                
                // Footer
                VStack(spacing: 15) {
                    Text("Already have an account?")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Button("Sign In") {
                        withAnimation {
                            authMode = .login
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .underline()
                }
                .padding(.bottom, 30)
                
                Spacer(minLength: 30)
            }
        }
        .alert("Signup Failed", isPresented: $showingError) {
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
        .trackScreenAuto(SignupView.self)
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private var passwordsMatch: Bool {
        confirmPassword.isEmpty || password == confirmPassword
    }
    
    private var isPasswordValid: Bool {
        password.count >= 6
    }
    
    private var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isPasswordValid &&
        passwordsMatch &&
        !confirmPassword.isEmpty
    }
    
    private func handleSignup() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedUsername.isEmpty else {
            showError("Please enter a username")
            return
        }
        
        guard isPasswordValid else {
            showError("Password must be at least 6 characters long")
            return
        }
        
        guard passwordsMatch else {
            showError("Passwords do not match")
            return
        }
        
        isLoading = true
        
        // Call the register API
        registerWithAPI(username: trimmedUsername, password: trimmedPassword)
    }
    
    private func registerWithAPI(username: String, password: String) {
        guard let url = URL(string: "https://user-login-register-d6yw.onrender.com/register") else {
            showError("Invalid URL")
            isLoading = false
            return
        }
        
        let registerData = [
            "username": username,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: registerData, options: [])
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
                                // Registration successful - now ask for phone number
                                showingPhoneInput = true
                            } else {
                                // Registration failed
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
                        // Phone number saved, now log in the user
                        authManager.handleSuccessfulLogin(username: self.username.trimmingCharacters(in: .whitespacesAndNewlines), 
                                                        name: self.username.trimmingCharacters(in: .whitespacesAndNewlines))
                        showingPhoneInput = false
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
        
        SignupView(authManager: AuthManager(), authMode: .constant(.signup))
    }
    .preferredColorScheme(.dark)
} 
