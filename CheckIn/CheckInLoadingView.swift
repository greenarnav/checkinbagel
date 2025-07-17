//
//  CheckInLoadingView.swift
//  moodgpt
//
//  Created by Test on 12/20/24.
//

import SwiftUI

// MARK: - Check-In Loading Screen View
struct CheckInLoadingView: View {
    @State private var textOpacity: Double = 0.0
    @Binding var isLoading: Bool
    
    var body: some View {
        ZStack {
            // Pure black background
            Color.black
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Simple cute white "checkin" text
                VStack(spacing: 16) {
                    Text("CheckIn")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(textOpacity)
                    
                    Text("Did you CheckIn?")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(textOpacity)
                }
                
                Spacer()
            }
        }
        .onAppear {
            startSimpleAnimation()
        }
    }
    
    private func startSimpleAnimation() {
        // Simple fade in
        withAnimation(.easeOut(duration: 1.0)) {
            textOpacity = 1.0
        }
        
        // Complete loading after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = false
            }
        }
    }
}

// MARK: - Matrix-Style Loading Effect
struct MatrixLoadingView: View {
    @State private var isAnimating = false
    @State private var columns: [MatrixColumn] = []
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Matrix rain effect
            HStack(spacing: 0) {
                ForEach(columns.indices, id: \.self) { index in
                    VStack(spacing: 2) {
                        ForEach(0..<columns[index].characters.count, id: \.self) { charIndex in
                            Text(String(columns[index].characters[charIndex]))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.green.opacity(columns[index].opacities[charIndex]))
                        }
                    }
                    .offset(y: columns[index].offset)
                }
            }
            
            // "checkin" text overlay
            Text("CheckIn")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .green, radius: 10)

            // "checkin" text overlay
            Text("Did you CheckIn?")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .green, radius: 10)
        }
        .onAppear {
            generateMatrixColumns()
            startMatrixAnimation()
        }
    }
    
    private func generateMatrixColumns() {
        let screenWidth = UIScreen.main.bounds.width
        let columnCount = Int(screenWidth / 20)
        
        for _ in 0..<columnCount {
            let column = MatrixColumn(
                characters: generateRandomCharacters(),
                opacities: generateRandomOpacities(),
                offset: CGFloat.random(in: -100...100)
            )
            columns.append(column)
        }
    }
    
    private func generateRandomCharacters() -> [Character] {
        let chars = "01チカタナハマ"
        return (0..<20).map { _ in chars.randomElement() ?? "0" }
    }
    
    private func generateRandomOpacities() -> [Double] {
        return (0..<20).map { _ in Double.random(in: 0.1...1.0) }
    }
    
    private func startMatrixAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            for index in columns.indices {
                columns[index].offset += CGFloat.random(in: 1...5)
                if columns[index].offset > UIScreen.main.bounds.height {
                    columns[index].offset = -100
                    columns[index].characters = generateRandomCharacters()
                    columns[index].opacities = generateRandomOpacities()
                }
            }
        }
    }
}

// MARK: - Matrix Column Model
struct MatrixColumn {
    var characters: [Character]
    var opacities: [Double]
    var offset: CGFloat
}

// MARK: - Preview
struct CheckInLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        CheckInLoadingView(isLoading: .constant(true))
    }
} 