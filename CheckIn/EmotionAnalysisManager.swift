//
//  EmotionAnalysisManager.swift
//  moodgpt
//
//  Created by Test on 6/3/25.
//

import Foundation
import SwiftUI

// MARK: - Emotion Analysis Manager
class EmotionAnalysisManager: ObservableObject {
    @Published var userEmotionAnalysis: EmotionSnapshotResponse?
    @Published var contactsSentimentAnalysis: EmotionContactsSentimentResponse?
    @Published var contactProfiles: [String: ContactProfile] = [:]
    @Published var isLoadingUserEmotion = false
    @Published var isLoadingContactsSentiment = false
    @Published var errorMessage: String?
    @Published var emojiLoaded: Bool = false
    @Published var parsedLocationAnalysis: String?
    @Published var parsedPsychologicalAnalysis: String?
    
    private let emotionService: EmotionAnalysisService
    
    // Singleton for global access
    static let shared = EmotionAnalysisManager()
    
    init(service: EmotionAnalysisService = EmotionAnalysisService()) {
        self.emotionService = service
    }
    
    // MARK: - Public Methods
    
    /// Analyze user emotion with async/await
    @MainActor
    func analyzeUserEmotion(username: String) async {
        guard !username.isEmpty else { return }
        
        // Provide instant feedback
        isLoadingUserEmotion = true
        errorMessage = nil
        
        // No fallback data - only use real API data
        
        do {
            let response = try await emotionService.analyzeUserEmotion(username: username)
            
            print("User emotion analysis API response received")
            print("Behavior factors: \(response.behavior_factors?.prefix(100) ?? "None")...")
            print("Health factors: \(response.health_factors?.prefix(100) ?? "None")...")
            print("Predicted emoji ID: \(response.emotion_id ?? 0)")
            print("User emotion profile: \(response.user_emotion_profile?.prefix(100) ?? "None")...")
            
            userEmotionAnalysis = response
            
            // Save the user emotion data to UserDefaults for persistence and future inference
            saveUserEmotionData(response)
            
            print("User emotion analysis saved and ready for inference")
            
        } catch {
            errorMessage = "API temporarily unavailable"
            print("User emotion analysis failed: \(error)")
            userEmotionAnalysis = nil // Clear any existing data
        }
        
        isLoadingUserEmotion = false
    }
    
    /// Analyze contacts sentiment with async/await
    @MainActor
    func analyzeContactsSentiment(contacts: [String: String]) async {
        guard !contacts.isEmpty else { return }
        
        // Provide instant feedback
        isLoadingContactsSentiment = true
        errorMessage = nil
        
        do {
            let response = try await emotionService.analyzeContactsSentiment(contacts: contacts)
            
            contactsSentimentAnalysis = response
            processContactsSentimentData(response, originalContacts: contacts)
            print("Contacts sentiment analysis received: \(response.contacts.count) contacts")
            
        } catch {
            errorMessage = "API temporarily unavailable"
            print("Contacts sentiment analysis failed: \(error)")
            contactsSentimentAnalysis = nil // Clear any existing data
            contactProfiles.removeAll() // Clear any existing profiles
        }
        
        isLoadingContactsSentiment = false
    }
    
    // MARK: - Contact Profile Processing
    
    private func processContactsSentimentData(_ response: EmotionContactsSentimentResponse, originalContacts: [String: String]) {
        let contactsData = response.contacts
        
        print("Processing \(contactsData.count) contacts from API response")
        contactProfiles.removeAll()
        
        for (contactName, contactData) in contactsData {
            print("Processing contact: \(contactName)")
            print("   - City: \(contactData.city)")
            print("   - Emoji ID: \(contactData.emotion.predictedEmojiId)")
            
            let profile = ContactProfile(
                contactName: contactName,
                city: contactData.city,
                emotion: ContactProfile.ContactEmotionDetail(
                    behaviorFactors: contactData.emotion.behaviorFactors,
                    healthFactors: contactData.emotion.healthFactors,
                    predictedEmojiId: contactData.emotion.predictedEmojiId,
                    userEmotionProfile: contactData.emotion.userEmotionProfile
                ),
                phoneNumber: originalContacts[contactName],
                lastUpdated: Date()
            )
            
            contactProfiles[contactName] = profile
            print(" Created profile for \(contactName): \(profile.emotion?.emoji ?? "❓") \(profile.emotion?.emotionText ?? "Unknown")")
        }
        
        print("Total profiles created: \(contactProfiles.count)")
    }
    
    // MARK: - Contact Update Methods
    
    func updateContact(_ contact: inout Contact) {
        guard let profile = contactProfiles[contact.name] else {
            contact.mood = ""
            contact.moodText = ""
            return
        }
        
        // Update contact with sentiment data
        if let emotion = profile.emotion {
            contact.mood = emotion.emoji
            contact.moodText = emotion.emotionText
        } else {
            contact.mood = ""
            contact.moodText = ""
        }
    }
    
    func updateContactsArray(_ contacts: inout [Contact]) {
        for i in 0..<contacts.count {
            updateContact(&contacts[i])
        }
    }
    
    // NEW METHOD: Returns updated contacts instead of modifying in place
    func getUpdatedContacts(from contacts: [Contact]) -> [Contact] {
        var updatedContacts = contacts
        for i in 0..<updatedContacts.count {
            updateContact(&updatedContacts[i])
        }
        return updatedContacts
    }
    
    // MARK: - Profile Generation Methods
    
    func generateContactProfile(for contact: Contact) -> String {
        let profile = contactProfiles[contact.name]
        return ContactProfileHelpers.generateContactProfile(
            from: contact,
            apiData: profile?.emotion
        )
    }
    
    func getContactEmotionData(for contactName: String) -> ContactProfile.ContactEmotionDetail? {
        return contactProfiles[contactName]?.emotion
    }
    
    // MARK: - Demo Method for Testing API Integration
    
    func testContactsSentimentAPI() {
        let demoContacts = [
            "Alice": "+1-555-123-4567",
            "Bob": "+1-310-987-6543",
            "Charlie": "+1-212-555-0123",
            "Diana": "+1-713-456-7890"
        ]
        
        print("Testing Contacts Sentiment API with demo data...")
        Task {
            await analyzeContactsSentiment(contacts: demoContacts)
        }
    }
    
    func testParsingWithSampleData() {
        print("Testing parsing with sample API response...")
        
        // Test with a minimal API response format
        let sampleJSON = """
        {
            "contacts": {
                "Alice": {
                    "city": "",
                    "emotion": {
                        "behavior_factors": "Test behavior",
                        "health_factors": "Test health",
                        "predicted_emoji_id": 46,
                        "user_emotion_profile": "Test profile"
                    },
                    "number": "+1-555-123-4567"
                }
            }
        }
        """
        
        guard let data = sampleJSON.data(using: .utf8) else {
            print("Failed to create test data")
            return
        }
        
        do {
            let response = try JSONDecoder().decode(EmotionContactsSentimentResponse.self, from: data)
            print("Sample parsing successful!")
            print("Contacts: \(response.contacts.count)")
            
            let contacts = response.contacts
            for (name, contactData) in contacts {
                print("\(name): Emoji ID \(contactData.emotion.predictedEmojiId)")
            }
        } catch {
            print("Sample parsing failed: \(error)")
            if let decodingError = error as? DecodingError {
                print("Decoding details: \(decodingError)")
            }
        }
    }
    
    func testParsingWithRealAPIResponse() {
        print("Testing parsing with REAL API response format...")
        
        // Test with the exact API response format from the user's curl command
        let realAPIJSON = """
        {
            "contacts": {
                "Alice": {
                    "city": "",
                    "emotion": {
                        "behavior_factors": "**Behavioral Analysis for User 'Alice' in California**\\n\\n**Subject:** Alice\\n**Location:** California\\n**Date:** Ongoing\\n**Device Usage:** Smartphone (iOS)/ Tablet (Android)\\n**App Interactions:** Various, including social media, productivity, entertainment, and location-based services\\n**Location Patterns:** Predominantly urban and suburban areas\\n**City Sentiment Data:** {} ( awaiting updates)\\n\\n**Behavioral Patterns:**\\n\\nBased on the available data, Alice's behavioral patterns in California reveal a dynamic mix of urban influences and regional preferences. Key patterns observed include:\\n\\n- **Peak usage hours:** 8 AM - 10 AM (morning routine) and 5 PM - 7 PM (post-work and evening routine)\\n- **Highest app usage:** Social media (45%), productivity (30%), and entertainment (25%)\\n- **Top-visited locations:** Office(s), coffee shops, grocery stores, parks, and beaches\\n- **Frequency of movement:** Alice moves frequently, using public transportation and ride-hailing services (35% of trips)",
                        "health_factors": "**Comprehensive Health Analysis Report**\\n\\n**Date:** June 4, 2023\\n**Location:** California, USA\\n**Sentiment Score:** 72/100 (Neutral/Positive)\\n\\n**Simulated Health Metrics:**\\n\\n1. **Resting Heart Rate (RHR):** 60 BPM (Below average)\\nYour RHR is slightly lower than the national average, suggesting a potentially relaxed and low-strain lifestyle.",
                        "predicted_emoji_id": 46,
                        "user_emotion_profile": "• The Sentiment Score of 72/100 (Neutral/Positive) suggests that Alice is generally positive but not overwhelmingly so, supporting the \\"neutral\\" emotional state.\\n• A resting heart rate of 60 BPM, while slightly concerning due to California's fast-paced lifestyle, may indicate that Alice is able to manage stress levels to some extent, aligning with a neutral emotional state."
                    },
                    "number": "+1-555-123-4567"
                },
                "Bob": {
                    "city": "California",
                    "emotion": {
                        "behavior_factors": "**Behavioral Analysis - User 'Bob'**\\n\\n**Location:** California, United States\\n**City Sentiment Data:** {}\\n\\n**Behavioral Patterns:**\\n\\nBased on user data, Bob exhibits a \\"Relaxed Pioneer\\" behavioral pattern typical of California residents.",
                        "health_factors": "**Comprehensive Health Analysis Report**\\n\\n**User's City Environment:** California\\n\\n**Date:** 04 June 2024\\n\\n**Summary:**\\nBased on the city sentiment data for California, this health report provides a comprehensive analysis.",
                        "predicted_emoji_id": 39,
                        "user_emotion_profile": "• Bob's behavior analysis patterns indicate a \\"Relaxed Pioneer\\" type, which suggests that he is relatively stress-free and content with his lifestyle."
                    },
                    "number": "+1-310-987-6543"
                }
            }
        }
        """
        
        guard let data = realAPIJSON.data(using: .utf8) else {
            print("Failed to create real API test data")
            return
        }
        
        do {
            let response = try JSONDecoder().decode(EmotionContactsSentimentResponse.self, from: data)
            print("Real API response parsing successful!")
            print("Contacts: \(response.contacts.count)")
            
            let contacts = response.contacts
            for (name, contactData) in contacts {
                print("\(name):")
                print("    - City: \(contactData.city)")
                print("    - Emoji ID: \(contactData.emotion.predictedEmojiId)")
                print("    - Emoji: \(ContactProfileHelpers.emojiForID(contactData.emotion.predictedEmojiId))")
                print("    - Has Behavior: \(!contactData.emotion.behaviorFactors.isEmpty)")
                print("    - Has Health: \(!contactData.emotion.healthFactors.isEmpty)")
                print("    - Has Emotion Profile: \(!contactData.emotion.userEmotionProfile.isEmpty)")
            }
            
            // Test processing the response
            let testContacts = ["Alice": "+1-555-123-4567", "Bob": "+1-310-987-6543"]
            processContactsSentimentData(response, originalContacts: testContacts)
            
            print("Real API response processing completed!")
            print("Contact profiles created: \(contactProfiles.count)")
            
        } catch {
            print("Real API response parsing failed: \(error)")
            if let decodingError = error as? DecodingError {
                print("Decoding details: \(decodingError)")
            }
        }
    }
    
    func checkCurrentErrorState() {
        print("Current Error State:")
        print("   - Has API Error: \(hasAPIError())")
        print("   - Error Message: \(errorMessage ?? "None")")
        print("   - Is Loading Contacts: \(isLoadingContactsSentiment)")
        print("   - Is Loading User: \(isLoadingUserEmotion)")
        print("   - Has Contacts Data: \(hasContactsData())")
        print("   - Has User Data: \(hasUserEmotionData())")
        print("   - Contact Profiles Count: \(contactProfiles.count)")
    }
    
    func refreshAllAnalysis(username: String, contacts: [String: String]) {
        Task {
            await analyzeUserEmotion(username: username)
            await analyzeContactsSentiment(contacts: contacts)
        }
    }

    // MARK: - Fast User Emotion Display Methods
    
    func getUserEmoji() -> String {
        guard let analysis = userEmotionAnalysis else {
            return "" // No fallback data
        }
        
        return ContactProfileHelpers.emojiForID(analysis.emotion_id)
    }
    
    func getUserMoodText() -> String {
        guard let analysis = userEmotionAnalysis else {
            return "" // No fallback data
        }
        
        return ContactProfileHelpers.emojiNameForID(analysis.emotion_id)
    }
    
    // New method to get the raw user emotion profile for display
    func getUserEmotionProfile() -> String {
        guard let analysis = userEmotionAnalysis else {
            return ""
        }
        
        return analysis.user_emotion_profile ?? ""
    }
    
    // New method to get behavior factors
    func getUserBehaviorFactors() -> String {
        guard let analysis = userEmotionAnalysis else {
            return ""
        }
        
        return analysis.behavior_factors ?? ""
    }
    
    // New method to get health factors
    func getUserHealthFactors() -> String {
        guard let analysis = userEmotionAnalysis else {
            return ""
        }
        
        return analysis.health_factors ?? ""
    }
    
    func getContactEmoji(for contactName: String) -> String {
        guard let profile = contactProfiles[contactName],
              let emotion = profile.emotion else {
            return "" // No fallback data
        }
        
        return emotion.emoji
    }
    
    func getContactMoodText(for contactName: String) -> String {
        guard let profile = contactProfiles[contactName],
              let emotion = profile.emotion else {
            return "" // No fallback data
        }
        
        let emotionText = emotion.emotionText
        if emotionText.lowercased().contains("neutral") || emotionText.isEmpty || emotionText == "Neutral" {
            return ContactProfileHelpers.emojiNameForID(emotion.predictedEmojiId)
        }
        
        return emotionText
    }
    
    func getContactEmojiName(for contactName: String) -> String {
        guard let profile = contactProfiles[contactName],
              let emotion = profile.emotion else {
            return "" // No fallback data
        }
        
        return ContactProfileHelpers.emojiNameForID(emotion.predictedEmojiId)
    }
    
    // MARK: - Status Check Methods
    
    func hasUserEmotionData() -> Bool {
        return userEmotionAnalysis != nil
    }
    
    func hasContactsData() -> Bool {
        return contactsSentimentAnalysis != nil
    }
    
    func hasContactProfile(for contactName: String) -> Bool {
        return contactProfiles[contactName] != nil
    }
    
    func hasAPIError() -> Bool {
        return errorMessage != nil
    }
    
    // Legacy methods for backward compatibility (now use ContactProfileHelpers)
    func sentimentToEmoji(_ sentiment: String?) -> String {
        guard let sentiment = sentiment else { return "😊" }
        
        switch sentiment.lowercased() {
        case "positive", "happy", "joyful": return "😊"
        case "negative", "sad": return "😔"
        case "angry", "frustrated": return "😠"
        case "anxious", "worried": return "😰"
        case "calm", "peaceful": return "😌"
        case "excited": return "😃"
        case "confused": return "🤔"
        case "tired": return "😪"
        default: return "��"
        }
    }
    
    // MARK: - Instant Fallback Methods
    
    /// Remove fallback profile creation - only use real API data
    
    // MARK: - User Emotion Data Handling
    
    private func saveUserEmotionData(_ response: EmotionSnapshotResponse) {
        print("💾 Saving user emotion data to UserDefaults for inference")
        
        // Save the complete emotion analysis data for future inference
        let defaults = UserDefaults.standard
        
        // Save individual fields with proper keys
        defaults.set(response.behavior_factors, forKey: "UserEmotionBehaviorFactors")
        defaults.set(response.health_factors, forKey: "UserEmotionHealthFactors")
        defaults.set(response.emotion_id, forKey: "UserEmotionPredictedEmojiID")
        defaults.set(response.user_emotion_profile, forKey: "UserEmotionProfile")
        
        
        if let psychologicalAnalysis = response.personality_analysis {
            let regex = try! NSRegularExpression(pattern: "(\\*\\*[^\\*]+\\*\\*)", options: [])
            var updatedText = regex.stringByReplacingMatches(in: psychologicalAnalysis, options: [], range: NSRange(location: 0, length: psychologicalAnalysis.count), withTemplate: "$0\n")
            updatedText = updatedText.replacingOccurrences(of: "**", with: "")
            self.parsedPsychologicalAnalysis = updatedText
            
            defaults.set(updatedText, forKey: "PsychologicalAnalysis")
        }
        
        if let locationAnalysis = response.contextual_factors {
            let regex = try! NSRegularExpression(pattern: "(\\*\\*[^\\*]+\\*\\*)", options: [])
            var updatedText = regex.stringByReplacingMatches(in: locationAnalysis, options: [], range: NSRange(location: 0, length: locationAnalysis.count), withTemplate: "$0\n")
            updatedText = updatedText.replacingOccurrences(of: "**", with: "")
            self.parsedLocationAnalysis = updatedText
            defaults.set(updatedText, forKey: "LocationAnalysis")
        }
        
        // Save timestamp for data freshness tracking
        defaults.set(Date(), forKey: "UserEmotionDataTimestamp")
        
        // Save the username this analysis was for
        if let username = getCurrentUsername() {
            defaults.set(username, forKey: "UserEmotionAnalysisUsername")
        }
        
        // Update the current user mood in UI
        if let emojiId = response.emotion_id {
            let emoji = ContactProfileHelpers.emojiForID(emojiId)
            let emojiName = ContactProfileHelpers.emojiNameForID(emojiId)
            
            defaults.set(emoji, forKey: "CurrentUserMood")
            defaults.set(emojiName, forKey: "CurrentUserMoodText")
            
            print("💾 Updated user mood: \(emoji) (\(emojiName))")
            emojiLoaded.toggle()
        }
        
        // Synchronize to ensure data is saved immediately
        defaults.synchronize()
        
        print("💾 User emotion data saved successfully")
        print("💾 Behavior Factors: \(response.behavior_factors?.prefix(50) ?? "None")...")
        print("💾 Health Factors: \(response.health_factors?.prefix(50) ?? "None")...")
        print("💾 Predicted Emoji ID: \(response.emotion_id ?? 0)")
        print("💾 User Emotion Profile: \(response.user_emotion_profile?.prefix(50) ?? "None")...")
        
        
    }
    
    // Helper to get current username for saving analysis data
    private func getCurrentUsername() -> String? {
        // Try to get username from AuthManager or UserDefaults
        if let username = UserDefaults.standard.string(forKey: "username"), !username.isEmpty {
            return username
        }
        return nil
    }
    
    // Method to load saved emotion data on app startup
    func loadSavedUserEmotionData() {
        let defaults = UserDefaults.standard
        
        // Check if we have saved emotion data
        guard let timestamp = defaults.object(forKey: "UserEmotionDataTimestamp") as? Date else {
            print("💾 No saved user emotion data found")
            return
        }
        
        // Check if data is recent (within 24 hours)
        let hoursElapsed = Date().timeIntervalSince(timestamp) / 3600
        if hoursElapsed > 24 {
            print("💾 Saved user emotion data is older than 24 hours, will refresh")
            return
        }
        
        // Load the saved data
        let behaviorFactors = defaults.string(forKey: "UserEmotionBehaviorFactors")
        let healthFactors = defaults.string(forKey: "UserEmotionHealthFactors")
        let predictedEmojiId = defaults.object(forKey: "UserEmotionPredictedEmojiID") as? Int
        let userEmotionProfile = defaults.string(forKey: "UserEmotionProfile")
        let psychological_analysis = defaults.string(forKey: "PsychologicalAnalysis")
        let location_analysis = defaults.string(forKey: "LocationAnalysis")
        
        // Reconstruct the response object
        userEmotionAnalysis = EmotionSnapshotResponse(
            emotion_id: predictedEmojiId,
            behavior_factors: behaviorFactors,
            health_factors: healthFactors,
            user_emotion_profile: userEmotionProfile,
            social_factors: location_analysis,
            contextual_factors: psychological_analysis,
            confidence_score: nil,
            personality_analysis: nil,
            mood_prediction: nil,
            interaction_style: nil,
            emotional_triggers: nil,
            recommendations: nil
        )
        
        print("💾 Loaded saved user emotion data from \(timestamp)")
        print("💾 Data age: \(String(format: "%.1f", hoursElapsed)) hours")
        print("💾 Emoji ID: \(predictedEmojiId ?? 0)")
    }
    
    // Method to get complete user emotion data for inference
    func getUserEmotionDataForInference() -> [String: Any]? {
        guard let analysis = userEmotionAnalysis else {
            print("No user emotion analysis data available for inference")
            return nil
        }
        
        return [
            "behavior_factors": analysis.behavior_factors ?? "",
            "health_factors": analysis.health_factors ?? "",
            "predicted_emoji_id": analysis.emotion_id ?? 46,
            "user_emotion_profile": analysis.user_emotion_profile ?? "",
            "emoji": ContactProfileHelpers.emojiForID(analysis.emotion_id),
            "emoji_name": ContactProfileHelpers.emojiNameForID(analysis.emotion_id),
            "timestamp": UserDefaults.standard.object(forKey: "UserEmotionDataTimestamp") as? Date ?? Date()
        ]
    }
    
    // MARK: - Manual Mode Functions
    
    // Manual mode removed - only use real API data
    
    // Manual contact profile generation removed - only use real API data
} 
