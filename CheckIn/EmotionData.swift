//
//  EmotionData.swift
//  moodgpt
//
//  Created by Test on 5/27/25.
//

import SwiftUI

// MARK: - Enhanced Emotion Data Models for API Integration
struct EmotionData {
    
    // MARK: - 8 Primary API Emotion Gradients
    static let apiEmotionColors: [String: LinearGradient] = [
        // 1. JOY/HAPPINESS - Warm Golden Sunrise
        "joyful": LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.95, blue: 0.4),   // Bright gold
                Color(red: 1.0, green: 0.8, blue: 0.3),    // Golden yellow
                Color(red: 1.0, green: 0.6, blue: 0.2),    // Warm orange
                Color(red: 0.95, green: 0.4, blue: 0.1)    // Deep sunset
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        
        // 2. CALM/PEACEFUL - Ocean Serenity
        "calm": LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.8, green: 0.95, blue: 1.0),   // Light sky
                Color(red: 0.6, green: 0.9, blue: 0.95),   // Soft cyan
                Color(red: 0.4, green: 0.8, blue: 0.9),    // Ocean blue
                Color(red: 0.2, green: 0.6, blue: 0.8)     // Deep sea
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        
        // 3. ENERGETIC/EXCITED - Electric Magenta
        "energetic": LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.9, blue: 0.6),    // Light coral
                Color(red: 1.0, green: 0.7, blue: 0.5),    // Vibrant coral
                Color(red: 0.95, green: 0.5, blue: 0.7),   // Pink energy
                Color(red: 0.9, green: 0.3, blue: 0.6)     // Electric magenta
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        
        // 4. CONTEMPLATIVE/THOUGHTFUL - Deep Purple Wisdom
        "contemplative": LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.85, green: 0.8, blue: 1.0),   // Light lavender
                Color(red: 0.7, green: 0.6, blue: 0.95),   // Soft purple
                Color(red: 0.6, green: 0.4, blue: 0.9),    // Medium purple
                Color(red: 0.5, green: 0.2, blue: 0.8)     // Deep wisdom
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        
        // 5. CONFIDENT/FOCUSED - Cool Professional Blue
        "focused": LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.7, green: 0.9, blue: 1.0),    // Light professional
                Color(red: 0.5, green: 0.8, blue: 0.95),   // Clear blue
                Color(red: 0.3, green: 0.7, blue: 0.9),    // Strong blue
                Color(red: 0.1, green: 0.5, blue: 0.8)     // Deep confidence
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        
        // 6. STRESSED/ANXIOUS - Stormy Gray-Blue
        "stressed": LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.8, green: 0.8, blue: 0.85),   // Light storm
                Color(red: 0.6, green: 0.65, blue: 0.75),  // Gray clouds
                Color(red: 0.5, green: 0.55, blue: 0.65),  // Deep storm
                Color(red: 0.4, green: 0.45, blue: 0.6)    // Dark tension
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        
        // 7. ROMANTIC/LOVING - Warm Rose Garden
        "romantic": LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.95, blue: 0.95),  // Soft blush
                Color(red: 1.0, green: 0.8, blue: 0.85),   // Rose pink
                Color(red: 0.95, green: 0.6, blue: 0.75),  // Warm rose
                Color(red: 0.9, green: 0.4, blue: 0.6)     // Deep love
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        
        // 8. NEUTRAL/BALANCED - Modern Sophisticated Gray
        "neutral": LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.9, green: 0.9, blue: 0.92),   // Light modern
                Color(red: 0.75, green: 0.78, blue: 0.82), // Soft gray
                Color(red: 0.6, green: 0.65, blue: 0.7),   // Medium gray
                Color(red: 0.5, green: 0.55, blue: 0.62)   // Deep neutral
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    ]
    
    // MARK: - Enhanced Background Gradient with API Support
    static func backgroundGradient(for emotion: String) -> LinearGradient {
        let emotionLower = emotion.lowercased()
        
        // First check API emotion colors (8 primary emotions)
        if let apiGradient = apiEmotionColors[emotionLower] {
            return apiGradient
        }
        
        // Map common emotion words to API emotions
        switch emotionLower {
        // Happy variations -> Joyful
        case "happy", "😊", "😄", "joy", "smile", "grinning", "laughing", "very happy", "excited":
            return apiEmotionColors["joyful"]!
            
        // Calm variations -> Calm
        case "😌", "relaxed", "peaceful", "serene", "zen", "relieved", "chill":
            return apiEmotionColors["calm"]!
            
        // Energy variations -> Energetic
        case "🤩", "pumped", "thrilled", "ecstatic", "amazing", "hyped":
            return apiEmotionColors["energetic"]!
            
        // Thinking variations -> Contemplative
        case "thinking", "🤔", "pensive", "thoughtful", "curious", "wondering":
            return apiEmotionColors["contemplative"]!
            
        // Confident variations -> Focused
        case "confident", "😎", "cool", "swagger", "proud", "determined", "focused":
            return apiEmotionColors["focused"]!
            
        // Stress variations -> Stressed
        case "worried", "😰", "anxious", "concerned", "nervous", "overwhelmed":
            return apiEmotionColors["stressed"]!
            
        // Love variations -> Romantic
        case "love", "😍", "romantic", "adoring", "in love", "loving", "heart-eyes", "kiss":
            return apiEmotionColors["romantic"]!
            
        // Neutral variations -> Neutral
        case "😐", "meh", "okay", "fine", "expressionless", "normal", "balanced":
            return apiEmotionColors["neutral"]!
            
        // Sad emotions -> Custom blue gradient
        case "sad", "😢", "😔", "melancholy", "down", "crying", "disappointed", "blue":
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.6, green: 0.8, blue: 1.0),  // Light blue
                    Color(red: 0.4, green: 0.7, blue: 0.95), // Soft blue
                    Color(red: 0.2, green: 0.5, blue: 0.9),  // Ocean blue
                    Color(red: 0.1, green: 0.3, blue: 0.7)   // Deep sadness
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        // Angry emotions -> Custom red gradient
        case "angry", "😡", "frustrated", "annoyed", "furious", "rage", "mad":
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.85, blue: 0.3),  // Warning yellow
                    Color(red: 1.0, green: 0.6, blue: 0.2),   // Orange flame
                    Color(red: 0.95, green: 0.4, blue: 0.3),  // Red fire
                    Color(red: 0.8, green: 0.2, blue: 0.2)    // Deep anger
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        // Surprised emotions -> Custom purple gradient
        case "surprised", "😮", "😯", "amazed", "shocked", "astonished", "wow":
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.9, blue: 1.0),   // Light surprise
                    Color(red: 0.9, green: 0.7, blue: 0.95),  // Soft pink
                    Color(red: 0.8, green: 0.5, blue: 0.9),   // Purple-pink
                    Color(red: 0.6, green: 0.3, blue: 0.8)    // Deep surprise
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        // Tired emotions -> Custom muted gradient
        case "tired", "😴", "sleepy", "exhausted", "weary", "yawning":
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.85, green: 0.85, blue: 0.9), // Light fatigue
                    Color(red: 0.75, green: 0.75, blue: 0.8), // Soft gray
                    Color(red: 0.65, green: 0.65, blue: 0.7), // Medium gray
                    Color(red: 0.55, green: 0.55, blue: 0.6)  // Deep tiredness
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        // Playful emotions -> Custom rainbow gradient
        case "playful", "😛", "silly", "cheeky", "fun", "zany", "winking":
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.9, blue: 0.6),   // Light fun
                    Color(red: 0.9, green: 0.8, blue: 0.9),   // Playful pink
                    Color(red: 0.7, green: 0.9, blue: 0.8),   // Fun green
                    Color(red: 0.8, green: 0.7, blue: 1.0)    // Silly purple
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        // Party emotions -> Custom vibrant gradient
        case "partying", "🥳", "celebrating", "festive", "party":
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.8, blue: 0.4),   // Party gold
                    Color(red: 0.9, green: 0.5, blue: 0.8),   // Celebration pink
                    Color(red: 0.5, green: 0.8, blue: 1.0),   // Party blue
                    Color(red: 0.7, green: 1.0, blue: 0.5)    // Festival green
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        default:
            // Enhanced default gradient - sophisticated and modern
            return apiEmotionColors["neutral"]!
        }
    }
    
    // MARK: - Emotion Category Mapping for API
    static func getEmotionCategory(_ emotion: String) -> String {
        let emotionLower = emotion.lowercased()
        
        switch emotionLower {
        case let e where ["happy", "😊", "😄", "joy", "smile", "grinning", "laughing", "very happy", "excited"].contains(e):
            return "joyful"
        case let e where ["😌", "relaxed", "peaceful", "serene", "zen", "relieved", "chill", "calm"].contains(e):
            return "calm"
        case let e where ["🤩", "pumped", "thrilled", "ecstatic", "amazing", "hyped", "energetic"].contains(e):
            return "energetic"
        case let e where ["thinking", "🤔", "pensive", "thoughtful", "curious", "wondering", "contemplative"].contains(e):
            return "contemplative"
        case let e where ["confident", "😎", "cool", "swagger", "proud", "determined", "focused"].contains(e):
            return "focused"
        case let e where ["worried", "😰", "anxious", "concerned", "nervous", "overwhelmed", "stressed"].contains(e):
            return "stressed"
        case let e where ["love", "😍", "romantic", "adoring", "in love", "loving", "heart-eyes", "kiss"].contains(e):
            return "romantic"
        case let e where ["😐", "meh", "okay", "fine", "expressionless", "normal", "balanced", "neutral"].contains(e):
            return "neutral"
        default:
            return "neutral"
        }
    }
    
    // MARK: - Enhanced Text Colors for Better Readability
    static func primaryTextColor(for emotion: String, theme: AppTheme) -> Color {
        switch theme {
        case .dark, .multiColor:
            return Color.white
        case .light:
            return Color(red: 0.1, green: 0.1, blue: 0.1) // Deep black for maximum contrast
        }
    }
    
    static func secondaryTextColor(for emotion: String, theme: AppTheme) -> Color {
        switch theme {
        case .dark, .multiColor:
            return Color.white.opacity(0.85)
        case .light:
            return Color(red: 0.25, green: 0.25, blue: 0.25) // Dark gray for readability
        }
    }
    
    // MARK: - Enhanced Card Background for Better Contrast
    static func cardBackgroundColor(for emotion: String, theme: AppTheme) -> Color {
        switch theme {
        case .dark:
            return Color.white.opacity(0.12)
        case .light:
            return Color.white.opacity(0.95) // Almost opaque white for maximum contrast
        case .multiColor:
            return Color.black.opacity(0.5) // More opaque for better readability
        }
    }
    
    // MARK: - Enhanced Border Colors
    static func borderColor(for emotion: String, theme: AppTheme) -> Color {
        switch theme {
        case .dark:
            return Color.white.opacity(0.25)
        case .light:
            return Color(red: 0.8, green: 0.82, blue: 0.85) // Darker borders for definition
        case .multiColor:
            return Color.white.opacity(0.5) // More visible borders
        }
    }
} 