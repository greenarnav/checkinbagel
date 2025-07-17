//
//  SharedComponents.swift
//  moodgpt
//
//  Created by Test on 6/1/25.
//

import SwiftUI

// MARK: - Professional Button Styles
struct ProfessionalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Legacy Interactive Button Style (kept for compatibility)
struct InteractiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Ultra Smooth Cross-Screen Floating Emoji
struct SmoothFloatingEmoji: Identifiable {
    let id = UUID()
    let emoji: String
    var startPosition: CGPoint
    var endPosition: CGPoint
    var currentPosition: CGPoint
    var opacity: Double
    var scale: CGFloat
    var animationProgress: Double = 0.0
    var journey: EmojiJourney
    
    enum EmojiJourney {
        case leftToRight
        case rightToLeft
        case topToBottom
        case bottomToTop
        case diagonalDescend
        case diagonalAscend
        case gentleCurve
        case slowFloat
        
        func calculatePath(from start: CGPoint, to end: CGPoint, progress: Double) -> CGPoint {
            let t = progress
            
            switch self {
            case .leftToRight, .rightToLeft, .topToBottom, .bottomToTop:
                return CGPoint(
                    x: start.x + (end.x - start.x) * t,
                    y: start.y + (end.y - start.y) * t
                )
            case .diagonalDescend, .diagonalAscend:
                return CGPoint(
                    x: start.x + (end.x - start.x) * t,
                    y: start.y + (end.y - start.y) * t + sin(t * .pi) * 30
                )
            case .gentleCurve:
                let curveHeight: CGFloat = 60
                return CGPoint(
                    x: start.x + (end.x - start.x) * t,
                    y: start.y + (end.y - start.y) * t + sin(t * .pi) * curveHeight
                )
            case .slowFloat:
                let floatAmplitude: CGFloat = 20
                return CGPoint(
                    x: start.x + (end.x - start.x) * t + sin(t * .pi * 2) * floatAmplitude,
                    y: start.y + (end.y - start.y) * t + cos(t * .pi * 3) * floatAmplitude
                )
            }
        }
    }
    
    init(emoji: String, screenBounds: CGRect) {
        self.emoji = emoji
        self.journey = .gentleCurve
        self.opacity = 0.25
        self.scale = 1.0
        
        // Create random start and end positions that guarantee cross-screen movement
        let margin: CGFloat = 50
        
        switch journey {
        case .leftToRight:
            startPosition = CGPoint(x: -margin, y: CGFloat.random(in: 100...screenBounds.height-100))
            endPosition = CGPoint(x: screenBounds.width + margin, y: CGFloat.random(in: 100...screenBounds.height-100))
        case .rightToLeft:
            startPosition = CGPoint(x: screenBounds.width + margin, y: CGFloat.random(in: 100...screenBounds.height-100))
            endPosition = CGPoint(x: -margin, y: CGFloat.random(in: 100...screenBounds.height-100))
        case .topToBottom:
            startPosition = CGPoint(x: CGFloat.random(in: 50...screenBounds.width-50), y: -margin)
            endPosition = CGPoint(x: CGFloat.random(in: 50...screenBounds.width-50), y: screenBounds.height + margin)
        case .bottomToTop:
            startPosition = CGPoint(x: CGFloat.random(in: 50...screenBounds.width-50), y: screenBounds.height + margin)
            endPosition = CGPoint(x: CGFloat.random(in: 50...screenBounds.width-50), y: -margin)
        case .diagonalDescend:
            startPosition = CGPoint(x: -margin, y: -margin)
            endPosition = CGPoint(x: screenBounds.width + margin, y: screenBounds.height + margin)
        case .diagonalAscend:
            startPosition = CGPoint(x: -margin, y: screenBounds.height + margin)
            endPosition = CGPoint(x: screenBounds.width + margin, y: -margin)
        case .gentleCurve:
            startPosition = CGPoint(x: CGFloat.random(in: -margin...(screenBounds.width + margin)), 
                                   y: CGFloat.random(in: 100...screenBounds.height-100))
            endPosition = CGPoint(x: CGFloat.random(in: -margin...(screenBounds.width + margin)), 
                                 y: CGFloat.random(in: 100...screenBounds.height-100))
        case .slowFloat:
            startPosition = CGPoint(x: CGFloat.random(in: 50...screenBounds.width-50), 
                                   y: CGFloat.random(in: 100...screenBounds.height-100))
            endPosition = CGPoint(x: CGFloat.random(in: 50...screenBounds.width-50), 
                                 y: CGFloat.random(in: 100...screenBounds.height-100))
        }
        
        self.currentPosition = startPosition
    }
    
    mutating func updatePosition(progress: Double) {
        self.animationProgress = progress
        self.currentPosition = journey.calculatePath(from: startPosition, to: endPosition, progress: progress)
        
        // Gentle opacity breathing effect
        self.opacity = 0.25 * (0.7 + 0.3 * sin(progress * .pi * 2))
    }
}

extension SmoothFloatingEmoji.EmojiJourney: CaseIterable {
    static var allCases: [SmoothFloatingEmoji.EmojiJourney] {
        return [.leftToRight, .rightToLeft, .topToBottom, .bottomToTop, 
                .diagonalDescend, .diagonalAscend, .gentleCurve, .slowFloat]
    }
}

// MARK: - Perfect Screenshot-Style Floating Emojis  
struct PerfectFloatingEmoji: Identifiable {
    let id = UUID()
    let emoji: String
    var position: CGPoint
    var velocity: CGPoint
    var size: CGFloat
    var opacity: Double
    var rotationSpeed: Double
    var currentRotation: Double = 0
    
    init(emoji: String, screenBounds: CGRect) {
        self.emoji = emoji
        // Perfect size matching screenshot (30-50 pixels)
        self.size = 40
        // Natural opacity like screenshot
        self.opacity = 0.6
        // Start at random position across full screen
        self.position = CGPoint(
            x: CGFloat.random(in: 20...(screenBounds.width - 20)),
            y: CGFloat.random(in: 80...(screenBounds.height - 80))
        )
        // Very slow natural drift velocity
        self.velocity = CGPoint(
            x: CGFloat.random(in: -0.3...0.3),
            y: CGFloat.random(in: -0.3...0.3)
        )
        self.rotationSpeed = 0.005
    }
    
    mutating func update(in screenBounds: CGRect) {
        // Update position with natural drift
        position.x += velocity.x
        position.y += velocity.y
        
        // Update rotation
        currentRotation += rotationSpeed
        
        // Gentle screen edge wrapping
        if position.x < -20 {
            position.x = screenBounds.width + 20
        } else if position.x > screenBounds.width + 20 {
            position.x = -20
        }
        
        if position.y < 60 {
            position.y = screenBounds.height + 20
        } else if position.y > screenBounds.height + 20 {
            position.y = 60
        }
        
        // No random changes
    }
}

// MARK: - Perfect Floating Emojis Background (Matching Screenshot)
struct FloatingEmojisBackground: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var emojis: [PerfectFloatingEmoji] = []
    @State private var animationTimer: Timer?
    
    // Rich variety of emojis matching screenshot diversity
    private let screenshotEmojis = [
        "slightly-happy", "Smile", "warm-smile", "grin", "grinning", 
        "relieved", "blush", "wink", "thinking-face", "neutral-face",
        "sleepy", "smile-with-big-eyes", "heart-eyes", "laughing", "joy",
        "pleased", "content", "peaceful", "dreamy", "serene"
    ]
    
    var body: some View {
        if themeManager.showEmojisInBackground {
            GeometryReader { geometry in
                ZStack {
                    ForEach(emojis) { emoji in
                        AnimatedEmoji(
                            emoji.emoji,
                            size: emoji.size,
                            fallback: "Smile"
                        )
                        .opacity(emoji.opacity)
                        .rotationEffect(.degrees(emoji.currentRotation))
                        .position(emoji.position)
                    }
                }
                .onAppear {
                    setupScreenshotStyleEmojis(in: geometry.frame(in: .global))
                    startNaturalFloating()
                }
                .onDisappear {
                    stopAnimation()
                }
            }
            .allowsHitTesting(false)
        }
    }
    
    private func setupScreenshotStyleEmojis(in bounds: CGRect) {
        let screenBounds = UIScreen.main.bounds
        
        // Perfect count matching screenshot (18 emojis)
        emojis = (0..<18).map { index in
            PerfectFloatingEmoji(
                emoji: screenshotEmojis[index % screenshotEmojis.count],
                screenBounds: screenBounds
            )
        }
        

    }
    
    private func startNaturalFloating() {
        // 60fps for ultra-smooth natural movement
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            let screenBounds = UIScreen.main.bounds
            
            for i in 0..<emojis.count {
                emojis[i].update(in: screenBounds)
            }
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// MARK: - Theme-Aware Background
struct ThemeAwareBackground: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Group {
            switch themeManager.currentTheme {
            case .dark:
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.black.opacity(0.95),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .light:
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white,
                        Color.white.opacity(0.98),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .multiColor:
                // Keep the original emotion-based gradient for multi-color mode
                Color.clear
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Privacy Information Component
struct PrivacyInfoPopup: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            
            // Privacy info card
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "shield.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text("Privacy First")
                        .font(.headingMedium)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Why only 12 contacts?")
                        .font(.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.green)
                                .font(.captionLarge)
                            
                            Text("We limit analysis to 12 contacts to protect your privacy and maintain processing efficiency")
                                .font(.captionLarge)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "cpu")
                                .foregroundColor(.blue)
                                .font(.captionLarge)
                            
                            Text("Smaller contact sets ensure faster, more accurate emotion analysis")
                                .font(.captionLarge)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.captionLarge)
                            
                            Text("Focus on your closest relationships for more meaningful insights")
                                .font(.captionLarge)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                
                Button(action: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPresented = false
                    }
                }) {
                    Text("Got it")
                        .font(.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.green)
                        )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(themeManager.borderColor, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
            .scaleEffect(isPresented ? 1.0 : 0.8)
            .opacity(isPresented ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isPresented)
        }
    }
}

// MARK: - Theme-Aware Text Color
extension Color {
    static func themeAwareText(for theme: AppTheme) -> Color {
        switch theme {
        case .dark:
            return .white
        case .light:
            return .black
        case .multiColor:
            return .white // Default for multi-color backgrounds
        }
    }
    
    static func themeAwareSecondaryText(for theme: AppTheme) -> Color {
        switch theme {
        case .dark:
            return .white.opacity(0.7)
        case .light:
            return .black.opacity(0.7)
        case .multiColor:
            return .white.opacity(0.8)
        }
    }
} 

// MARK: - Unified Design System for App Cohesiveness
struct UnifiedCardStyle: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    let cardType: CardType
    let isSelected: Bool
    
    enum CardType {
        case standard
        case celebrity
        case elevated
        case selection
    }
    
    init(cardType: CardType = .standard, isSelected: Bool = false) {
        self.cardType = cardType
        self.isSelected = isSelected
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .shadow(color: shadowColor, radius: shadowRadius, x: shadowX, y: shadowY)
            )
    }
    
    private var cornerRadius: CGFloat {
        switch cardType {
        case .standard:
            return 12
        case .celebrity:
            return 16
        case .elevated:
            return 16
        case .selection:
            return 20
        }
    }
    
    private var backgroundFill: Color {
        if isSelected {
            return themeManager.selectionBackgroundColor
        }
        
        switch cardType {
        case .standard:
            return themeManager.cardBackgroundColor
        case .celebrity:
            return themeManager.celebrityCardBackground
        case .elevated:
            return themeManager.elevatedCardBackground
        case .selection:
            return themeManager.cardBackgroundColor
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return themeManager.accentColor.opacity(0.6)
        }
        
        switch cardType {
        case .standard:
            return themeManager.borderColor
        case .celebrity:
            return themeManager.celebrityBorderColor
        case .elevated:
            return themeManager.borderColor
        case .selection:
            return themeManager.borderColor
        }
    }
    
    private var borderWidth: CGFloat {
        return isSelected ? 1.5 : 1
    }
    
    private var shadowColor: Color {
        return themeManager.shadowColor
    }
    
    private var shadowRadius: CGFloat {
        switch cardType {
        case .standard:
            return 1
        case .celebrity:
            return 2
        case .elevated:
            return 3
        case .selection:
            return 2
        }
    }
    
    private var shadowX: CGFloat {
        return 0
    }
    
    private var shadowY: CGFloat {
        switch cardType {
        case .standard:
            return 0.5
        case .celebrity:
            return 1
        case .elevated:
            return 2
        case .selection:
            return 1
        }
    }
}

// MARK: - Enhanced Button Styles for Consistency
struct UnifiedButtonStyle: ButtonStyle {
    @EnvironmentObject var themeManager: ThemeManager
    let buttonType: ButtonType
    let isSelected: Bool
    
    enum ButtonType {
        case primary
        case secondary
        case accent
        case celebrity
    }
    
    init(buttonType: ButtonType = .primary, isSelected: Bool = false) {
        self.buttonType = buttonType
        self.isSelected = isSelected
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(textColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private var textColor: Color {
        if isSelected {
            return themeManager.selectionTextColor
        }
        
        switch buttonType {
        case .primary:
            return themeManager.primaryTextColor
        case .secondary:
            return themeManager.secondaryTextColor
        case .accent:
            return themeManager.accentColor
        case .celebrity:
            return themeManager.primaryTextColor
        }
    }
    
    private var backgroundFill: Color {
        if isSelected {
            return themeManager.selectionBackgroundColor
        }
        
        switch buttonType {
        case .primary:
            return themeManager.cardBackgroundColor
        case .secondary:
            return themeManager.surfaceColor
        case .accent:
            return themeManager.accentColor.opacity(0.1)
        case .celebrity:
            return themeManager.celebrityCardBackground
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return themeManager.accentColor.opacity(0.6)
        }
        
        switch buttonType {
        case .primary:
            return themeManager.borderColor
        case .secondary:
            return themeManager.borderColor.opacity(0.5)
        case .accent:
            return themeManager.accentColor.opacity(0.3)
        case .celebrity:
            return themeManager.celebrityBorderColor
        }
    }
    
    private var shadowColor: Color {
        return themeManager.shadowColor
    }
    
    private var shadowRadius: CGFloat {
        return isSelected ? 3 : 1
    }
    
    private var shadowY: CGFloat {
        return isSelected ? 2 : 0.5
    }
    
    private var cornerRadius: CGFloat {
        switch buttonType {
        case .primary:
            return 12
        case .secondary:
            return 10
        case .accent:
            return 14
        case .celebrity:
            return 16
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch buttonType {
        case .primary:
            return 16
        case .secondary:
            return 12
        case .accent:
            return 18
        case .celebrity:
            return 14
        }
    }
    
    private var verticalPadding: CGFloat {
        switch buttonType {
        case .primary:
            return 12
        case .secondary:
            return 8
        case .accent:
            return 14
        case .celebrity:
            return 10
        }
    }
}

// MARK: - Enhanced Text Styles for Better Typography
struct UnifiedTextStyle: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    let textType: TextType
    
    enum TextType {
        case headline
        case title
        case body
        case caption
        case accent
    }
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(textColor)
            .font(textFont)
            .fontWeight(fontWeight)
    }
    
    private var textColor: Color {
        switch textType {
        case .headline, .title:
            return themeManager.primaryTextColor
        case .body:
            return themeManager.primaryTextColor
        case .caption:
            return themeManager.secondaryTextColor
        case .accent:
            return themeManager.accentColor
        }
    }
    
    private var textFont: Font {
        switch textType {
        case .headline:
            return .system(size: 24, weight: .bold, design: .rounded)
        case .title:
            return .system(size: 20, weight: .semibold, design: .rounded)
        case .body:
            return .system(size: 16, weight: .medium, design: .default)
        case .caption:
            return .system(size: 14, weight: .regular, design: .default)
        case .accent:
            return .system(size: 16, weight: .semibold, design: .rounded)
        }
    }
    
    private var fontWeight: Font.Weight {
        switch textType {
        case .headline:
            return .bold
        case .title:
            return .semibold
        case .body:
            return .medium
        case .caption:
            return .regular
        case .accent:
            return .semibold
        }
    }
}

// MARK: - View Extensions for Easy Usage
extension View {
    func unifiedCard(_ cardType: UnifiedCardStyle.CardType = .standard, isSelected: Bool = false) -> some View {
        self.modifier(UnifiedCardStyle(cardType: cardType, isSelected: isSelected))
    }
    
    func unifiedButton(_ buttonType: UnifiedButtonStyle.ButtonType = .primary, isSelected: Bool = false) -> some View {
        self.buttonStyle(UnifiedButtonStyle(buttonType: buttonType, isSelected: isSelected))
    }
    
    func unifiedText(_ textType: UnifiedTextStyle.TextType) -> some View {
        self.modifier(UnifiedTextStyle(textType: textType))
    }
} 