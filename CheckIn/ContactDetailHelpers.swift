//
//  ContactDetailHelpers.swift
//  moodgpt
//
//  Created by Test on 5/27/25.
//

import SwiftUI

struct ContactDetailHelpers {
    
    // MARK: - Emotional Timeline Generation
    static func generateEmotionalTimeline(for contact: Contact) -> [EmotionalTimelineItem] {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let times = ["6 AM", "9 AM", "12 PM", "3 PM", "6 PM", "9 PM"]
        let timeHours = [6, 9, 12, 15, 18, 21]
        
        let moodProgression = generateMoodProgression(for: contact)
        
        return times.enumerated().map { index, time in
            let isCurrentTime = abs(timeHours[index] - currentHour) <= 1
            return EmotionalTimelineItem(
                time: time,
                mood: moodProgression[index].mood,
                description: moodProgression[index].description,
                isCurrentTime: isCurrentTime
            )
        }
    }
    
    static func generateMoodProgression(for contact: Contact) -> [(mood: String, description: String)] {
        // Only use API data - no hardcoded mood progression
        return [("neutral-face", "Loading...")]
    }
    
    // MARK: - Analysis Generation
    static func generateEmotionAnalysis(for contact: Contact) -> String {
        // Generic analysis for all contacts
        return "This contact shows balanced emotional patterns with professional stability. Their mood variations align with typical business cycles and demonstrate healthy emotional regulation in professional contexts."
    }
    
    // MARK: - Intensity Calculations
    static func generateIntensityPercentage(for contact: Contact) -> String {
        let intensities = ["87%", "92%", "78%", "95%", "83%", "89%", "91%", "76%", "88%", "94%"]
        return intensities[abs(contact.name.hashValue) % intensities.count]
    }
    
    static func generateIntensityValue(for contact: Contact) -> Int {
        let values = [87, 92, 78, 95, 83, 89, 91, 76, 88, 94]
        return values[abs(contact.name.hashValue) % values.count]
    }
    
    static func intensityColor(for contact: Contact) -> Color {
        let value = generateIntensityValue(for: contact)
        switch value {
        case 90...100: return .red
        case 80..<90: return .orange
        case 70..<80: return .yellow
        default: return .green
        }
    }
    
    static func generateIntensityDescription(for contact: Contact) -> String {
        let value = generateIntensityValue(for: contact)
        switch value {
        case 90...100: return "Very intense emotional response"
        case 80..<90: return "High emotional engagement"
        case 70..<80: return "Moderate emotional intensity"
        default: return "Calm emotional state"
        }
    }
    
    // MARK: - Professional Behavior
    static func generateProfessionalFrequency(for contact: Contact) -> String {
        let frequencies = ["Daily", "Weekly", "Bi-weekly", "Monthly", "As needed"]
        return frequencies[abs(contact.name.hashValue) % frequencies.count]
    }
    
    static func generateProfessionalDescription(for contact: Contact) -> String {
        switch contact.location {
        case let location where location.contains("Hedge Fund"):
            return "High-frequency analytical thinking, market-focused decision making"
        case let location where location.contains("CFO"):
            return "Strategic financial planning, executive-level decision processes"
        case let location where location.contains("Angel"):
            return "Investment evaluation, startup mentoring, deal sourcing"
        case let location where location.contains("CEO"):
            return "Leadership decisions, strategic planning, team management"
        case let location where location.contains("Performance"):
            return "Goal-oriented coaching, motivation techniques, progress tracking"
        default:
            return "Professional engagement, strategic thinking, collaborative approach"
        }
    }
    
    static func generateProfessionalTags(for contact: Contact) -> [String] {
        switch contact.location {
        case let location where location.contains("Hedge Fund"):
            return ["analytics", "markets", "strategy"]
        case let location where location.contains("CFO"):
            return ["finance", "planning", "leadership"]
        case let location where location.contains("Angel"):
            return ["investing", "startups", "mentoring"]
        case let location where location.contains("CEO"):
            return ["leadership", "vision", "execution"]
        case let location where location.contains("Performance"):
            return ["coaching", "motivation", "goals"]
        default:
            return ["professional", "collaborative", "strategic"]
        }
    }
    
    // MARK: - Social Interactions
    static func generateSocialFrequency(for contact: Contact) -> String {
        let frequencies = ["High", "Moderate", "Selective", "Professional", "Limited"]
        return frequencies[abs(contact.name.hashValue + 1) % frequencies.count]
    }
    
    static func generateSocialDescription(for contact: Contact) -> String {
        switch contact.moodText {
        case "Happy", "Excited":
            return "Highly engaging, positive social interactions, networking-focused"
        case "Confident", "Professional":
            return "Strategic social connections, business-oriented interactions"
        case "Calm", "Balanced":
            return "Measured social engagement, quality over quantity approach"
        case "Focused", "Analytical":
            return "Purpose-driven social interactions, goal-oriented networking"
        default:
            return "Balanced social approach, professional and personal connections"
        }
    }
    
    static func generateSocialTags(for contact: Contact) -> [String] {
        switch contact.moodText {
        case "Happy", "Excited":
            return ["networking", "events", "social"]
        case "Confident", "Professional":
            return ["business", "strategic", "leadership"]
        case "Calm", "Balanced":
            return ["selective", "quality", "meaningful"]
        case "Focused", "Analytical":
            return ["purposeful", "goal-oriented", "efficient"]
        default:
            return ["balanced", "professional", "social"]
        }
    }
    
    // MARK: - Mood Triggers
    static func generateMoodTriggers(for contact: Contact) -> [String] {
        // Generic mood triggers for all contacts
        return ["Professional achievements", "Team collaboration", "Strategic decisions", "Growth opportunities"]
    }
    
    // MARK: - Communication Insights
    static func generateBestContactTime(for contact: Contact) -> String {
        let times = ["9-11 AM EST", "2-4 PM EST", "10 AM-12 PM EST", "3-5 PM EST", "Morning hours", "Afternoon preferred"]
        return times[abs(contact.name.hashValue) % times.count]
    }
    
    static func generatePreferredMethod(for contact: Contact) -> String {
        let methods = ["Email first", "Phone calls", "Text messages", "Video calls", "In-person meetings", "LinkedIn messages"]
        return methods[abs(contact.name.hashValue + 2) % methods.count]
    }
    
    static func generateResponseRate(for contact: Contact) -> String {
        let rates = ["95% within 2 hours", "87% same day", "92% within 4 hours", "89% within 1 hour", "94% within 3 hours", "91% same day"]
        return rates[abs(contact.name.hashValue + 3) % rates.count]
    }
    
    static func generateRelationshipStrength(for contact: Contact) -> String {
        let strengths = ["Strong professional", "Excellent rapport", "Growing connection", "Established trust", "Strategic alliance", "Close business relationship"]
        return strengths[abs(contact.name.hashValue + 4) % strengths.count]
    }
    
    // MARK: - Recent Changes
    static func generateRecentMoodChanges(for contact: Contact) -> [MoodChange] {
        let changes = [
            MoodChange(fromMood: "😐", toMood: contact.mood, timeAgo: "2 hours ago", reason: "Successful meeting outcome"),
            MoodChange(fromMood: "🤔", toMood: "😐", timeAgo: "6 hours ago", reason: "Strategic planning session"),
            MoodChange(fromMood: "😊", toMood: "🤔", timeAgo: "1 day ago", reason: "New business opportunity evaluation")
        ]
        return Array(changes.prefix(3))
    }
    
    // MARK: - Secondary Emotions
    static func generateSecondaryEmotions(for contact: Contact) -> [SecondaryEmotion] {
        switch contact.moodText {
        case "Happy":
            return [
                SecondaryEmotion(emotion: "Optimistic", emoji: "😌", percentage: 25),
                SecondaryEmotion(emotion: "Energetic", emoji: "😄", percentage: 20),
                SecondaryEmotion(emotion: "Grateful", emoji: "🥰", percentage: 15)
            ]
        case "Confident":
            return [
                            SecondaryEmotion(emotion: "Determined", emoji: "😤", percentage: 30),
            SecondaryEmotion(emotion: "Ambitious", emoji: "😄", percentage: 25),
                SecondaryEmotion(emotion: "Strategic", emoji: "🤔", percentage: 20)
            ]
        case "Focused":
            return [
                SecondaryEmotion(emotion: "Analytical", emoji: "🤔", percentage: 35),
                SecondaryEmotion(emotion: "Methodical", emoji: "😐", percentage: 25),
                SecondaryEmotion(emotion: "Precise", emoji: "😐", percentage: 20)
            ]
        case "Motivated":
            return [
                SecondaryEmotion(emotion: "Driven", emoji: "😤", percentage: 30),
                SecondaryEmotion(emotion: "Inspiring", emoji: "🤩", percentage: 25),
                SecondaryEmotion(emotion: "Goal-oriented", emoji: "😤", percentage: 20)
            ]
        default:
            return [
                SecondaryEmotion(emotion: "Thoughtful", emoji: "thinking-face", percentage: 25),
                SecondaryEmotion(emotion: "Balanced", emoji: "relieved", percentage: 20),
                SecondaryEmotion(emotion: "Professional", emoji: "neutral-face", percentage: 15)
            ]
        }
    }
    
    // MARK: - Related Contacts
    static func generateRelatedContacts(for contact: Contact) -> [Contact] {
        // No related contacts - return empty array
        return []
    }
} 