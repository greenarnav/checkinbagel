//
//  OnboardingView.swift
//  moodgpt
//
//  Created by Test on 5/31/25.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var userName: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Beautiful gradient background inspired by the images
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.7, green: 0.4, blue: 0.9), // Purple
                    Color(red: 0.5, green: 0.6, blue: 0.9), // Purple-blue
                    Color(red: 0.3, green: 0.7, blue: 0.9), // Blue-teal
                    Color(red: 0.2, green: 0.8, blue: 0.8)  // Teal
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating animated emojis background - loads instantly with snapshot
            if themeManager.showEmojisInBackground {
                FloatingEmojisBackground()
            }
            
            // Semi-transparent overlay for readability
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            // Content loads immediately
            VStack(spacing: 40) {
                Spacer()
                
                // Header section
                VStack(spacing: 16) {
                    Text("CheckIn")
                        .font(.system(size: 44, weight: .light, design: .default))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .kerning(2)
                    
                    Text("Did you check in?")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Name input section - professional styling
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What's your name?")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                        
                        TextField("Enter your name", text: $userName)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.words)
                            .disableAutocorrection(false)
                            .padding(.horizontal, 20)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                            .placeholder(when: userName.isEmpty) {
                                Text("Your name")
                                    .foregroundColor(.white.opacity(0.5))
                                    .font(.system(size: 16, weight: .regular))
                                    .padding(.horizontal, 20)
                            }
                        
                        Text("We'll use this to personalize your experience")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Professional continue button
                    Button(action: {
                        handleContinue()
                    }) {
                        Text("Get Started")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isFormValid ? Color.black.opacity(0.4) : Color.black.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(isFormValid ? 0.3 : 0.1), lineWidth: 0.5)
                                    )
                            )
                    }
                    .buttonStyle(ProfessionalButtonStyle())
                    .disabled(!isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    
                    // Professional skip option
                    VStack(spacing: 12) {
                        Button(action: {
                            authManager.enterGuestMode()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Continue as Guest")
                                    .font(.system(size: 15, weight: .regular))
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Text("No registration needed")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Professional footer matching authentication view
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("By continuing, you agree to our")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 8) {
                            Text("Terms of Service")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .underline()
                            
                            Text("and")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Privacy Policy")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .underline()
                        }
                    }
                    
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(.white.opacity(0.2))
                        .frame(maxWidth: 120)
                    
                    Text("Powered by CheckIn AI")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .kerning(0.5)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 34)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            hideKeyboard()
        }
    }
    
    private var isFormValid: Bool {
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        userName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }
    
    private func handleContinue() {
        let cleanName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard cleanName.count >= 2 else {
            showError("Please enter at least 2 characters for your name")
            return
        }
        
        // Generate a unique username from the name and timestamp
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let username = "\(cleanName.lowercased().replacingOccurrences(of: " ", with: ""))_\(timestamp)"
        
        // Store user information locally
        UserDefaults.standard.set(cleanName, forKey: "currentName")
        UserDefaults.standard.set(username, forKey: "username")
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(false, forKey: "isGuestMode")
        
        // Login user immediately without API call
        authManager.loginUserInstantly(username: username, name: cleanName)
        
        
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    OnboardingView(authManager: AuthManager())
        .preferredColorScheme(.dark)
} 