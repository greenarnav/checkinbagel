//
//  CoolLoadingAnimations.swift
//  moodgpt
//
//  Created by Test on 12/20/24.
//

import SwiftUI

// MARK: - Pulse Loading Animation
struct PulseLoadingView: View {
    @State private var isAnimating = false
    let color: Color
    let size: CGFloat
    
    init(color: Color = .blue, size: CGFloat = 60) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 3)
                    .frame(width: size, height: size)
                    .scaleEffect(isAnimating ? 1.5 : 0.5)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever()
                        .delay(Double(index) * 0.3),
                        value: isAnimating
                    )
            }
            
            Circle()
                .fill(color)
                .frame(width: size * 0.3, height: size * 0.3)
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .animation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Wave Loading Animation
struct WaveLoadingView: View {
    @State private var isAnimating = false
    let color: Color
    let count: Int
    
    init(color: Color = .blue, count: Int = 5) {
        self.color = color
        self.count = count
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 4, height: 20)
                    .scaleEffect(y: isAnimating ? 2.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.8)
                        .repeatForever()
                        .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Orbit Loading Animation
struct OrbitLoadingView: View {
    @State private var isAnimating = false
    let color: Color
    let size: CGFloat
    
    init(color: Color = .blue, size: CGFloat = 50) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .fill(color)
                    .frame(width: size * 0.2, height: size * 0.2)
                    .offset(y: -size * 0.4)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        .linear(duration: 1.2)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
                    .rotationEffect(.degrees(Double(index) * 120))
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Morphing Shapes Loading
struct MorphingLoadingView: View {
    @State private var isAnimating = false
    let color: Color
    let size: CGFloat
    
    init(color: Color = .blue, size: CGFloat = 40) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: isAnimating ? size / 2 : 8)
                .fill(color)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(isAnimating ? 180 : 0))
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Particle Loading Animation
struct ParticleLoadingView: View {
    @State private var isAnimating = false
    let color: Color
    let particleCount: Int
    
    init(color: Color = .blue, particleCount: Int = 8) {
        self.color = color
        self.particleCount = particleCount
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .offset(
                        x: isAnimating ? cos(Double(index) * 2 * .pi / Double(particleCount)) * 25 : 0,
                        y: isAnimating ? sin(Double(index) * 2 * .pi / Double(particleCount)) * 25 : 0
                    )
                    .opacity(isAnimating ? 0.3 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating ? 1.5 : 0.5)
                .animation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - DNA Helix Loading
struct DNAHelixLoadingView: View {
    @State private var isAnimating = false
    let color: Color
    
    init(color: Color = .blue) {
        self.color = color
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .offset(
                        x: sin(Double(index) * .pi / 3 + (isAnimating ? .pi * 2 : 0)) * 15,
                        y: Double(index - 2) * 8
                    )
                    .opacity(0.7)
                    .animation(
                        .linear(duration: 2.0)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Heart Beat Loading
struct HeartBeatLoadingView: View {
    @State private var isAnimating = false
    let color: Color
    
    init(color: Color = .red) {
        self.color = color
    }
    
    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 30))
            .foregroundColor(color)
            .scaleEffect(isAnimating ? 1.3 : 1.0)
            .animation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Simple Dots Loading (Just circles)
struct CoolDotsLoadingView: View {
    @State private var isAnimating = false
    let color: Color
    let dotCount: Int
    
    init(color: Color = .blue, dotCount: Int = 3) {
        self.color = color
        self.dotCount = dotCount
    }
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.15),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Spinner Loading (iOS Style Enhanced)
struct SpinnerLoadingView: View {
    @State private var isAnimating = false
    let color: Color
    let size: CGFloat
    
    init(color: Color = .blue, size: CGFloat = 30) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<12) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: size * 0.15, height: size * 0.4)
                    .offset(y: -size * 0.3)
                    .opacity(isAnimating ? 1.0 : 0.3)
                    .rotationEffect(.degrees(Double(index) * 30))
                    .animation(
                        .linear(duration: 1.2)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .rotationEffect(.degrees(isAnimating ? 360 : 0))
        .animation(
            .linear(duration: 1.2)
            .repeatForever(autoreverses: false),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Loading Text with Animation
struct LoadingTextView: View {
    let text: String
    let color: Color
    @State private var visibleCharacters = 0
    
    init(text: String = "Loading", color: Color = .primary) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .opacity(visibleCharacters > index ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .delay(Double(index) * 0.1),
                        value: visibleCharacters
                    )
            }
            
            CoolDotsLoadingView(color: color, dotCount: 3)
        }
        .onAppear {
            startTextAnimation()
        }
    }
    
    private func startTextAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if visibleCharacters < text.count {
                visibleCharacters += 1
            } else {
                visibleCharacters = 0
            }
        }
    }
}

// MARK: - Combined Loading View (Multiple Animations)
struct UltimateLoadingView: View {
    let text: String
    let primaryColor: Color
    let secondaryColor: Color
    @State private var currentAnimation = 0
    
    init(text: String = "Loading", primaryColor: Color = .blue, secondaryColor: Color = .purple) {
        self.text = text
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated loading indicator
            Group {
                switch currentAnimation {
                case 0:
                    PulseLoadingView(color: primaryColor, size: 60)
                case 1:
                    OrbitLoadingView(color: primaryColor, size: 50)
                case 2:
                    ParticleLoadingView(color: primaryColor, particleCount: 8)
                default:
                    MorphingLoadingView(color: primaryColor, size: 40)
                }
            }
            .frame(height: 80)
            
            // Animated text
            LoadingTextView(text: text, color: primaryColor)
        }
        .onAppear {
            // Cycle through different animations every 3 seconds
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentAnimation = (currentAnimation + 1) % 4
                }
            }
        }
    }
} 