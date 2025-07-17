//
//  AuthenticationView.swift
//  moodgpt
//
//  Created by Test on 6/5/25.
//

import SwiftUI
import AuthenticationServices

enum AuthMode {
    case initial
    case login
    case signup
}


struct AuthenticationView: View {
    @ObservedObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var authMode: AuthMode = .initial
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
            switch authMode {
            case .initial:
                ScrollView {
                    InitialAuthView(authManager: authManager, authMode: $authMode)
                }
            case .login:
                LoginView(authManager: authManager, authMode: $authMode)
            case .signup:
                SignupView(authManager: authManager, authMode: $authMode)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authMode)
    }
}

struct InitialAuthView: View {
    @ObservedObject var authManager: AuthManager
    @Binding var authMode: AuthMode
    @State private var showingTerms = false
    @State private var showPhoneNumber: Bool = false
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var name: String = ""
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Header section - clean and professional
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
            
            // Professional authentication buttons
            VStack(spacing: 12) {
                // Primary buttons with professional styling
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        authMode = .login
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "person")
                            .font(.system(size: 16, weight: .medium))
                        Text("Sign In")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                            )
                    )
                }
                .buttonStyle(ProfessionalButtonStyle())
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        authMode = .signup
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .medium))
                        Text("Create Account")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                            )
                    )
                }
                .buttonStyle(ProfessionalButtonStyle())
                
                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(.white.opacity(0.3))
                    Text("or")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 16)
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.vertical, 16)
                
                // Secondary authentication options
                Button(action: {
                    self.handleGoogleAuthentication()
                }) {
                    HStack(spacing: 12) {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "globe")
                                .font(.system(size: 14, weight: .medium))
                        }
                        Text("Continue with Google")
                            .font(.system(size: 15, weight: .regular))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button(action: {
                    loginUsingApple()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "applelogo")
                            .font(.system(size: 14, weight: .medium))
                        Text("Continue with Apple")
                            .font(.system(size: 15, weight: .regular))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button(action: {
                    authManager.enterGuestMode()
                }) {
                    HStack(spacing: 12) {
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
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Professional footer with proper alignment
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("By continuing, you agree to our")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 8) {
                        Button("Terms of Service") {
                            showingTerms = true
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .underline()
                        
                        Text("and")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button("Privacy Policy") {
                            // Handle privacy policy
                        }
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
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPhoneNumber) {
            PhoneNumberInputView(
                phoneNumber: $phoneNumber,
                isPresented: $showPhoneNumber,
                onSave: { phone in
                    savePhoneNumberAndAuthenticate(number: phone)
                    showPhoneNumber = false
                }
            )
        }
        .trackScreenAuto(InitialAuthView.self)
    }
    
    func loginUsingApple() {
        AppleSignInManager.shared.startSignInWithAppleFlow { result in
            switch result {
            case .failure(let error):
                // Handle Apple Sign In error
                print("Apple Sign In failed: \(error.localizedDescription)")
                // You could show an alert to the user here if needed
                break
                
            case .success(let authorization):
                authManager.handleAuthorization(authorization, completion: { email, name in
                    self.email = email ?? ""
                    self.name = name ?? ""
                    authManager.checkPhoneNumberExist(username: email ?? "") { exist in
                        if exist == false {
                            self.showPhoneNumber = true
                        } else {
                            authManager.trySocialLogin(email: self.email, name: self.name)
                        }
                    }
                })
            }
        }
    }
    
    func handleGoogleAuthentication() {
        authManager.authenticateUsingGoogle { email, name in
            self.email = email ?? ""
            self.name = name ?? ""
            authManager.checkPhoneNumberExist(username: email ?? "") { exist in
                if exist == false {
                    self.showPhoneNumber = true
                } else {
                    authManager.trySocialLogin(email: self.email, name: self.name)
                }
            }
        }
    }
    
    func savePhoneNumberAndAuthenticate(number: String) {
        authManager.savePhoneNumber(username: self.email, phoneNumber: number) { value in
            authManager.trySocialLogin(email: self.email, name: self.name)
        }
    }
}

#Preview {
    AuthenticationView(authManager: AuthManager())
        .preferredColorScheme(.dark)
}
