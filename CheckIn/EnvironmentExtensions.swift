//
//  EnvironmentExtensions.swift
//  moodgpt
//
//  Created by Test on 5/27/25.
//

import SwiftUI

// MARK: - Environment Keys
private struct ChatIsShowingKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var chatIsShowing: Binding<Bool> {
        get { self[ChatIsShowingKey.self] }
        set { self[ChatIsShowingKey.self] = newValue }
    }
}

// MARK: - Modern Font System (Instagram-inspired)
extension Font {
    // MARK: - Brand Fonts (Inter-inspired using SF Pro)
    static let brandTitle = Font.system(size: 32, weight: .bold, design: .rounded)
    static let brandSubtitle = Font.system(size: 18, weight: .medium, design: .rounded)
    
    // MARK: - Display Fonts (Modern & Clean)
    static let displayLarge = Font.system(size: 56, weight: .bold, design: .default)
    static let displayMedium = Font.system(size: 45, weight: .bold, design: .default)
    static let displaySmall = Font.system(size: 36, weight: .semibold, design: .default)
    
    // MARK: - Heading Fonts (Poppins-inspired)
    static let headingLarge = Font.system(size: 28, weight: .bold, design: .default)
    static let headingMedium = Font.system(size: 24, weight: .semibold, design: .default)
    static let headingSmall = Font.system(size: 20, weight: .semibold, design: .default)
    
    // MARK: - Body Fonts (Clean & Readable)
    static let bodyLarge = Font.system(size: 18, weight: .medium, design: .default)
    static let bodyMedium = Font.system(size: 16, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)
    
    // MARK: - Caption Fonts (Subtle & Light)
    static let captionLarge = Font.system(size: 12, weight: .medium, design: .default)
    static let captionMedium = Font.system(size: 11, weight: .regular, design: .default)
    static let captionSmall = Font.system(size: 10, weight: .light, design: .default)
    
    // MARK: - Special Fonts (Trendy & Fun)
    static let buttonFont = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let tabFont = Font.system(size: 10, weight: .medium, design: .rounded)
    static let numberFont = Font.system(size: 24, weight: .bold, design: .monospaced)
}

// MARK: - Font Weights for Consistency
extension Font.Weight {
    static let ultraLight = Font.Weight.ultraLight
    static let thin = Font.Weight.thin  
    static let light = Font.Weight.light
    static let regular = Font.Weight.regular
    static let medium = Font.Weight.medium
    static let semibold = Font.Weight.semibold
    static let bold = Font.Weight.bold
    static let heavy = Font.Weight.heavy
    static let black = Font.Weight.black
}

// MARK: - Button Responsiveness Modifier
extension View {
    /// Ensures buttons remain responsive with immediate feedback
    func ensureResponsive() -> some View {
        self
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        // Immediate haptic feedback for user assurance
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
            )
    }
    
    /// Adds responsive button behavior with haptic feedback
    func responsiveButton(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self
            .contentShape(Rectangle())
            .onTapGesture {
                let impactFeedback = UIImpactFeedbackGenerator(style: style)
                impactFeedback.impactOccurred()
            }
    }
    
    // MARK: - Typography Modifiers
    /// Apply modern brand styling
    func brandText() -> some View {
        self.font(.brandTitle)
    }
    
    /// Apply trendy heading style
    func trendyHeading() -> some View {
        self.font(.headingLarge)
    }
    
    /// Apply Instagram-style body text
    func modernBody() -> some View {
        self.font(.bodyMedium)
    }
    
    /// Apply sleek caption style
    func sleekCaption() -> some View {
        self.font(.captionLarge)
    }
} 