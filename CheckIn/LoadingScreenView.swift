//
//  LoadingScreenView.swift
//  moodgpt
//
//  Created by Test on 6/1/25.
//

import SwiftUI

// MARK: - Professional Loading Screen View
struct LoadingScreenView: View {
    @State private var logoScale: CGFloat = 0.95
    @State private var logoOpacity: Double = 0.0
    @State private var gradientAnimation: Bool = false
    @State private var pulseAnimation: Bool = false
    @Binding var isLoading: Bool
    
    var body: some View {
        ZStack {
            // Elegant gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color.black
                ]),
                startPoint: gradientAnimation ? .topLeading : .bottomTrailing,
                endPoint: gradientAnimation ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: gradientAnimation)
            
            VStack(spacing: 40) {
                Spacer()
                
                // Elegant minimalist logo
                ZStack {
                    // Subtle outer glow
                    Circle()
                        .fill(Color.white.opacity(0.02))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    // Main logo circle
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.8),
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(logoScale)
                    
                    // Minimalist inner symbol
                    VStack(spacing: 4) {
                        // Elegant connection lines
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 28, height: 3)
                            .rotationEffect(.degrees(45))
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 28, height: 3)
                            .rotationEffect(.degrees(-45))
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                }
                
                // Prominent app name
                Text("CheckIn")
                    .font(.system(size: 42, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .opacity(logoOpacity)
                    .tracking(3)
                
                Spacer()
                
                // Subtle loading indicator
                VStack(spacing: 12) {
                    // Minimal progress bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 120, height: 2)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.6))
                            .frame(width: pulseAnimation ? 120 : 20, height: 2)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                    }
                    
                    Text("Loading...")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(logoOpacity * 0.8)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startElegantAnimation()
        }
    }
    
    private func startElegantAnimation() {
        // Start gradient animation immediately
        gradientAnimation = true
        
        // Logo fade in with subtle scale
        withAnimation(.easeOut(duration: 1.2)) {
            logoOpacity = 1.0
            logoScale = 1.0
        }
        
        // Start pulse animation with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            pulseAnimation = true
        }
        
        // Minimum loading time of 1.0 seconds for professional feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
        }
    }
}

// MARK: - App Coordinator removed (moved to main app file)

// MARK: - Preview
struct LoadingScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingScreenView(isLoading: .constant(true))
    }
} 