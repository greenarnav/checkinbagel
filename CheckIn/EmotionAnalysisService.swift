//
//  EmotionAnalysisService.swift
//  moodgpt
//
//  Created by Test on 6/2/25.
//

import Foundation
import SwiftUI

// MARK: - API Response Models
struct EmotionSnapshotResponse: Codable, Equatable {
    let emotion_id: Int?
    let behavior_factors: String?
    let health_factors: String?
    let user_emotion_profile: String?
    let social_factors: String?
    let contextual_factors: String?
    let confidence_score: Double?
    let personality_analysis: String?
    let mood_prediction: String?
    let interaction_style: String?
    let emotional_triggers: String?
    let recommendations: [String]?
}

// MARK: - Contacts Emotion Response Models
struct ContactsEmotionResponse: Codable {
    let contacts: [String: ContactEmotionData]
}

struct ContactEmotionData: Codable {
    let city: String
    let emotion: ContactEmotionDetails
    let number: String
}

struct ContactEmotionDetails: Codable {
    let behaviorFactors: String
    let healthFactors: String
    let predictedEmojiId: Int
    let userEmotionProfile: String
    
    enum CodingKeys: String, CodingKey {
        case behaviorFactors = "behavior_factors"
        case healthFactors = "health_factors"
        case predictedEmojiId = "predicted_emoji_id"
        case userEmotionProfile = "user_emotion_profile"
    }
}

// Use existing EmotionContactsSentimentResponse from ContactProfileHelpers.swift
typealias EmotionContactsSentimentResponse = ContactsEmotionResponse

// MARK: - API Request Models
struct EmotionSnapshotRequest: Codable {
    let username: String
}

struct EmotionContactsSentimentRequest: Codable {
    let contacts: [String: String]
}

// MARK: - API Errors
enum EmotionAPIError: Error {
    case invalidURL
    case noData
    case networkError(Error)
    case httpError(code: Int)
    case decodingError(Error)
    case invalidResponse
    case serverError(String)
}

// MARK: - Simplified API Service
class EmotionAnalysisService: ObservableObject {
    
    // MARK: - Single Async/Await API Calls
    
    /// Analyze user emotion with simple async/await
    func analyzeUserEmotion(username: String) async throws -> EmotionSnapshotResponse {
        guard let url = URL(string: "https://emotion-snapshot.onrender.com/analyze_user") else {
            throw EmotionAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        let requestBody = EmotionSnapshotRequest(username: username)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmotionAPIError.networkError(URLError(.badServerResponse))
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw EmotionAPIError.httpError(code: httpResponse.statusCode)
        }
        
        guard !data.isEmpty else {
            throw EmotionAPIError.noData
        }
        
        do {
            return try JSONDecoder().decode(EmotionSnapshotResponse.self, from: data)
        } catch {
            throw EmotionAPIError.decodingError(error)
        }
    }
    
    /// Analyze single contact by phone number
    func analyzeContactByPhone(phone: String) async throws -> ContactEmotionData {
        guard let url = URL(string: "https://django-api-test-rubo.onrender.com/api/contacts/latest_emotion_by_phone") else {
            throw EmotionAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        let requestBody = ["phone": phone]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmotionAPIError.networkError(URLError(.badServerResponse))
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw EmotionAPIError.httpError(code: httpResponse.statusCode)
        }
        
        guard !data.isEmpty else {
            throw EmotionAPIError.noData
        }
        
        do {
            return try JSONDecoder().decode(ContactEmotionData.self, from: data)
        } catch {
            throw EmotionAPIError.decodingError(error)
        }
    }

    /// Analyze contacts sentiment with simple async/await (DEPRECATED - use analyzeContactByPhone for individual contacts)
    func analyzeContactsSentiment(contacts: [String: String]) async throws -> EmotionContactsSentimentResponse {
        // For backward compatibility, we'll analyze the first contact only
        // In practice, should use analyzeContactByPhone for individual contacts
        guard let (name, phone) = contacts.first else {
            throw EmotionAPIError.noData
        }
        
        let contactData = try await analyzeContactByPhone(phone: phone)
        let response = ContactsEmotionResponse(contacts: [name: contactData])
        return response
    }

    /// Submit header stats (health data) to Django API
    func submitHeaderStats(username: String, mood: String, energy: Int, sleepHours: Double, heartRate: Int? = nil, steps: Int? = nil) async throws {
        guard let url = URL(string: "https://django-api-test-rubo.onrender.com/api/submit_header_stats/") else {
            throw EmotionAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        var data: [String: Any] = [
            "mood": mood,
            "energy": energy,
            "sleep_hours": sleepHours
        ]
        
        // Add optional health metrics if available
        if let heartRate = heartRate {
            data["heart_rate"] = heartRate
        }
        if let steps = steps {
            data["steps"] = steps
        }
        
        let requestBody: [String: Any] = [
            "username": username,
            "data": data
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmotionAPIError.networkError(URLError(.badServerResponse))
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw EmotionAPIError.httpError(code: httpResponse.statusCode)
        }
    }

    /// Get latest header stats for a contact by phone number
    func getLatestHeaderStats(for phoneNumber: String) async throws -> ContactHeaderStats {
        guard let url = URL(string: "https://django-api-test-rubo.onrender.com/api/get_latest_header_stats/") else {
            throw EmotionAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        let requestBody = ["user": phoneNumber]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmotionAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Header stats API failed with status: \(httpResponse.statusCode)")
            throw EmotionAPIError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        do {
            let headerStats = try JSONDecoder().decode(ContactHeaderStats.self, from: data)
            print("✅ Header stats fetched successfully for: \(phoneNumber)")
            return headerStats
        } catch {
            print("❌ Failed to decode header stats response: \(error)")
            throw EmotionAPIError.decodingError(error)
        }
    }
}

// MARK: - Home Page Emotion Snapshot Response Models
struct HomeEmotionSnapshotResponse: Codable {
    let ai_scoop: String
    let crisp_analytics_points: [String]
    let emoji_id: Int
    let zinger_caption: String
    let mental_pulse: String?
    let social_vibe: String?
}

// MARK: - Simplified Timeline API Model
struct EmotionalTimelineAPIEntry: Codable {
    let timestamp: Double
    let emoji_id: Int
    let description: String
    let ai_scoop: String
    let social_vibe: String
    let zinger_caption: String
    let additionalData: [String: Any]?
    
    init(timestamp: Double, emoji_id: Int, description: String, ai_scoop: String, social_vibe: String, zinger_caption: String, additionalData: [String: Any]? = nil) {
        self.timestamp = timestamp
        self.emoji_id = emoji_id
        self.description = description
        self.ai_scoop = ai_scoop
        self.social_vibe = social_vibe
        self.zinger_caption = zinger_caption
        self.additionalData = additionalData
    }
    
    private enum CodingKeys: String, CodingKey {
        case timestamp, emoji_id, description, ai_scoop, social_vibe, zinger_caption
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Double.self, forKey: .timestamp)
        emoji_id = try container.decode(Int.self, forKey: .emoji_id)
        description = try container.decode(String.self, forKey: .description)
        ai_scoop = try container.decode(String.self, forKey: .ai_scoop)
        social_vibe = try container.decode(String.self, forKey: .social_vibe)
        zinger_caption = try container.decode(String.self, forKey: .zinger_caption)
        additionalData = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(emoji_id, forKey: .emoji_id)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(ai_scoop, forKey: .ai_scoop)
        try container.encodeIfPresent(social_vibe, forKey: .social_vibe)
        try container.encodeIfPresent(zinger_caption, forKey: .zinger_caption)
    }
}

// MARK: - Simplified Emotion Snapshot Service
class EmotionSnapshotService: ObservableObject {
    @Published var isLoading = false
    @Published var currentSnapshot: [String: Any]?  // Store raw JSON for analyze_user
    @Published var emotionalTimeline: [String: Any]?  // Store raw JSON for get_last_emotional_data
    @Published var predictionData: [String: Any]?  // Store raw JSON for predict_emotion
    @Published var errorMessage: String?
    
    private let baseURL = "https://emotion-snapshot.onrender.com"
    private let timelineBaseURL = "https://django-api-test-rubo.onrender.com"
    private let predictionBaseURL = "https://django-api-test-rubo.onrender.com"
    private let cacheManager = CacheManager.shared
    
    // Load cached data on init
    init() {
        // TEMPORARY FIX: Clear all cached data and force fresh API calls
        // This will prevent showing old hardcoded timeline data
        print("🗑️ CLEARING ALL CACHED DATA - forcing fresh API calls")
        clearAllCachedData()
        // Commented out cached data loading until API issue is resolved
        // loadCachedData()
    }
    
    /// Clear all cached data to force fresh API calls
    private func clearAllCachedData() {
        currentSnapshot = nil
        emotionalTimeline = nil
        predictionData = nil
        errorMessage = nil
        
        // Clear all UserDefaults cache for timeline data
        let userDefaults = UserDefaults.standard
        
        // Remove all cached timeline and emotion data
        let keysToRemove = [
            "cached_home_timeline",
            "cached_emotion_snapshot", 
            "cached_user_analysis",
            "UserEmotionDataTimestamp",
            "CurrentUserMood",
            "CurrentUserMoodText",
            "PsychologicalAnalysis",
            "LocationAnalysis"
        ]
        
        for key in keysToRemove {
            userDefaults.removeObject(forKey: key)
        }
        
        // Also clear username-specific caches
        let potentialUsernames = ["testuser", "guest", "guestuser"]
        for username in potentialUsernames {
            userDefaults.removeObject(forKey: "cached_home_timeline_\(username)")
            userDefaults.removeObject(forKey: "cached_emotion_snapshot_\(username)")
            userDefaults.removeObject(forKey: "cached_user_analysis_\(username)")
        }
        
        print("🗑️ Cleared all cached timeline and emotion data")
    }
    
    /// Load cached data immediately when service is created
    private func loadCachedData() {
        // Get current username
        let username = getCurrentUsername()
        guard !username.isEmpty else { return }
        
        // Load cached user analysis and convert to raw format
        if let cachedAnalysis = cacheManager.getCachedUserAnalysis(for: username) {
            self.currentSnapshot = [
                "ai_scoop": cachedAnalysis.aiScoop,
                "crisp_analytics_points": cachedAnalysis.crispAnalyticsPoints,
                "emoji_id": cachedAnalysis.emojiId,
                "zinger_caption": cachedAnalysis.zingerCaption,
                "mental_pulse": cachedAnalysis.mentalPulse,
                "social_vibe": cachedAnalysis.socialVibe
            ]
        }
        
        // For cached data, create simplified structures
        // (Full API integration will override these)
    }
    
    private func getCurrentUsername() -> String {
        // Try to get logged in username first
        if let loggedInUsername = UserDefaults.standard.string(forKey: "LoggedInUsername"), !loggedInUsername.isEmpty {
            return loggedInUsername
        }
        
        // Try to get guest username
        if let guestUsername = UserDefaults.standard.string(forKey: "GuestUsername"), !guestUsername.isEmpty {
            return guestUsername
        }
        
        // FIXED: Also check stored username for compatibility
        if let storedUsername = UserDefaults.standard.string(forKey: "username"), !storedUsername.isEmpty {
            return storedUsername
        }
        
        // Return empty if none found - AuthManager username should be passed as parameter instead
        return ""
    }
    
    /// Simple async user analysis
    @MainActor
    func analyzeUser(username: String) async {
        guard !username.isEmpty else {
            errorMessage = "Username is required"
            print("❌ analyzeUser: Username is empty!")
            return
        }
        
        print("📡 ANALYZE_USER API DEBUG: Starting API call")
        print("   - URL: \(baseURL)/analyze_user")
        print("   - Username: '\(username)'")
        print("   - Method: POST")
        
        // Don't show loading if we have cached data
        if currentSnapshot == nil {
            isLoading = true
        }
        errorMessage = nil
        
        do {
            guard let url = URL(string: "\(baseURL)/analyze_user") else {
                throw EmotionAPIError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody = ["username": username]
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            print("📡 ANALYZE_USER API DEBUG: Sending request...")
            print("   - Request body: \(requestBody)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EmotionAPIError.networkError(URLError(.badServerResponse))
            }
            
            print("📡 ANALYZE_USER API DEBUG: Response received")
            print("   - HTTP Status: \(httpResponse.statusCode)")
            print("   - Response size: \(data.count) bytes")
            
            guard 200...299 ~= httpResponse.statusCode else {
                print("❌ ANALYZE_USER API DEBUG: HTTP Error \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("   - Error response: \(errorString)")
                }
                throw EmotionAPIError.httpError(code: httpResponse.statusCode)
            }
            
            guard !data.isEmpty else {
                print("❌ ANALYZE_USER API DEBUG: Empty response data")
                throw EmotionAPIError.noData
            }
            
            // Store raw JSON response
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("✅ ANALYZE_USER API DEBUG: Successfully parsed JSON response")
                print("   - Top-level keys: \(jsonObject.keys.sorted())")
                print("   - emoji_id: \(jsonObject["emoji_id"] ?? "nil")")
                print("   - zinger_caption: \(jsonObject["zinger_caption"] ?? "nil")")
                print("   - ai_scoop length: \((jsonObject["ai_scoop"] as? String)?.count ?? 0) chars")
                
                currentSnapshot = jsonObject
                print("✅ ANALYZE_USER API DEBUG: Stored in currentSnapshot")
                
                // Cache the response in the expected format
                if let emojiId = jsonObject["emoji_id"] as? Int,
                   let zingerCaption = jsonObject["zinger_caption"] as? String,
                   let aiScoop = jsonObject["ai_scoop"] as? String,
                   let socialVibe = jsonObject["social_vibe"] as? String,
                   let mentalPulse = jsonObject["mental_pulse"] as? String,
                   let crispAnalyticsPoints = jsonObject["crisp_analytics_points"] as? [String] {
                    
                    print("✅ ANALYZE_USER API DEBUG: All required fields present, caching...")
                    
                    let cacheData = UserAnalysisResponse(
                        emojiId: emojiId,
                        zingerCaption: zingerCaption,
                        socialVibe: socialVibe,
                        mentalPulse: mentalPulse,
                        aiScoop: aiScoop,
                        crispAnalyticsPoints: crispAnalyticsPoints
                    )
                    cacheManager.cacheUserAnalysis(cacheData, for: username)
                    print("✅ ANALYZE_USER API DEBUG: Successfully cached for username: '\(username)'")
                } else {
                    print("⚠️ ANALYZE_USER API DEBUG: Missing some required fields, not caching")
                    print("   - emojiId: \(jsonObject["emoji_id"] != nil)")
                    print("   - zingerCaption: \(jsonObject["zinger_caption"] != nil)")
                    print("   - aiScoop: \(jsonObject["ai_scoop"] != nil)")
                    print("   - socialVibe: \(jsonObject["social_vibe"] != nil)")
                    print("   - mentalPulse: \(jsonObject["mental_pulse"] != nil)")
                    print("   - crispAnalyticsPoints: \(jsonObject["crisp_analytics_points"] != nil)")
                }
            } else {
                print("❌ ANALYZE_USER API DEBUG: Failed to parse JSON")
                if let rawString = String(data: data, encoding: .utf8) {
                    print("   - Raw response: \(rawString.prefix(200))...")
                }
            }
            
        } catch {
            errorMessage = "Failed to analyze user: \(error.localizedDescription)"
            print("❌ ANALYZE_USER API DEBUG: Error occurred: \(error)")
        }
        
        isLoading = false
        print("📡 ANALYZE_USER API DEBUG: Method completed")
    }
    
    /// Simple async timeline fetch
    @MainActor
    func fetchEmotionalTimeline(username: String) async {
        guard !username.isEmpty else {
            errorMessage = "Username is required"
            print("❌ fetchEmotionalTimeline: Username is empty")
            return
        }
        
        print("📡 fetchEmotionalTimeline: Starting API call for username: '\(username)'")
        
        // Don't show loading if we have cached data
        if emotionalTimeline == nil {
            isLoading = true
        }
        errorMessage = nil
        
        do {
            guard let url = URL(string: "\(timelineBaseURL)/api/emotional_timeline/get_last_emotional_data") else {
                throw EmotionAPIError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody = ["username": username]
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            print("📡 fetchEmotionalTimeline: Sending request to: \(url)")
            print("📡 fetchEmotionalTimeline: Request body: \(requestBody)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EmotionAPIError.invalidResponse
            }
            
            print("📡 fetchEmotionalTimeline: HTTP Status: \(httpResponse.statusCode)")
            print("📡 fetchEmotionalTimeline: Response size: \(data.count) bytes")
            
            if httpResponse.statusCode == 200 {
                // Parse as raw JSON dictionary
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("✅ fetchEmotionalTimeline: Successfully parsed JSON")
                    print("📡 fetchEmotionalTimeline: Top-level keys: \(jsonObject.keys.sorted())")
                    
                    if let predictions = jsonObject["predictions"] as? [String: [String: Any]] {
                        print("✅ fetchEmotionalTimeline: Found \(predictions.count) predictions (BACKDATE DATA)")
                        
                        // Log each prediction for debugging
                        let sortedPredictions = predictions.sorted { $0.key < $1.key }
                        for (index, (timestamp, data)) in sortedPredictions.enumerated() {
                            print("📡 fetchEmotionalTimeline: Backdate #\(index + 1)")
                            print("   - Timestamp: '\(timestamp)'")
                            print("   - emoji_id: \(data["emoji_id"] ?? "nil")")
                            print("   - zinger_caption: \(data["zinger_caption"] ?? "nil")")
                        }
                        
                        // Store the raw JSON response
                        emotionalTimeline = jsonObject
                        print("✅ fetchEmotionalTimeline: Stored \(predictions.count) backdate entries in emotionalTimeline")
                    } else {
                        print("❌ fetchEmotionalTimeline: No predictions found in response")
                        print("📡 fetchEmotionalTimeline: Full response: \(jsonObject)")
                    }
                } else {
                    print("❌ fetchEmotionalTimeline: Failed to parse JSON")
                    if let rawString = String(data: data, encoding: .utf8) {
                        print("📡 fetchEmotionalTimeline: Raw response: \(rawString)")
                    }
                }
            } else {
                print("❌ fetchEmotionalTimeline: HTTP Error \(httpResponse.statusCode)")
                if let rawString = String(data: data, encoding: .utf8) {
                    print("📡 fetchEmotionalTimeline: Error response: \(rawString)")
                }
                throw EmotionAPIError.serverError("HTTP \(httpResponse.statusCode)")
            }
        } catch {
            print("❌ fetchEmotionalTimeline: Error: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Simple async predictions fetch
    @MainActor
    func fetchPredictions(username: String) async {
        guard !username.isEmpty else {
            errorMessage = "Username is required"
            return
        }
        
        // Don't show loading if we have cached data
        if predictionData == nil {
            isLoading = true
        }
        errorMessage = nil
        
        do {
            guard let url = URL(string: "\(predictionBaseURL)/api/emotional_timeline/predict_emotion") else {
                throw EmotionAPIError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody = ["username": username]
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw EmotionAPIError.httpError(code: (response as? HTTPURLResponse)?.statusCode ?? 0)
            }
            
            // Store raw JSON response
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                predictionData = jsonObject
                print("✅ Stored raw predict_emotion response with keys: \(jsonObject.keys)")
                
                // Cache emotion snapshot from predictions if available
                if let predictions = jsonObject["predictions"] as? [String: [String: Any]],
                   let firstPrediction = predictions.values.first,
                   let aiScoop = firstPrediction["ai_scoop"] as? String,
                   let mentalPulse = firstPrediction["mental_pulse"] as? String,
                   let socialVibe = firstPrediction["social_vibe"] as? String {
                    
                    let snapshot = EmotionSnapshot(
                        aiScoop: aiScoop,
                        mentalPulse: mentalPulse,
                        socialVibe: socialVibe,
                        timestamp: Date()
                    )
                    cacheManager.cacheEmotionSnapshot(snapshot, for: username)
                }
            }
            
        } catch {
            errorMessage = "Failed to fetch predictions: \(error.localizedDescription)"
            print("❌ predict_emotion API failed: \(error)")
        }
        
        isLoading = false
    }
    
    /// Force refresh all API data with enhanced debugging
    @MainActor
    func forceRefreshAllData(username: String) async {
        print("🔄 FORCE REFRESH: Starting complete API refresh for username: '\(username)'")
        
        // Clear any existing data first
        currentSnapshot = nil
        emotionalTimeline = nil
        predictionData = nil
        errorMessage = nil
        
        guard !username.isEmpty else {
            print("❌ FORCE REFRESH: Username is empty!")
            return
        }
        
        isLoading = true
        
        // Call all 3 APIs sequentially with enhanced debugging
        print("📡 FORCE REFRESH: [1/3] Calling analyze_user API...")
        await analyzeUser(username: username)
        
        print("📡 FORCE REFRESH: [2/3] Calling get_last_emotional_data API...")
        await fetchEmotionalTimeline(username: username)
        
        print("📡 FORCE REFRESH: [3/3] Calling predict_emotion API...")
        await fetchPredictions(username: username)
        
        // Final debug summary
        print("🔄 FORCE REFRESH: Complete! Final state:")
        print("   - currentSnapshot: \(currentSnapshot != nil)")
        print("   - emotionalTimeline: \(emotionalTimeline != nil)")  
        print("   - predictionData: \(predictionData != nil)")
        
        if let timeline = emotionalTimeline,
           let predictions = timeline["predictions"] as? [String: [String: Any]] {
            print("   - Historical data count: \(predictions.count)")
            for (timestamp, _) in predictions.sorted(by: { $0.key < $1.key }) {
                print("     - Timestamp: \(timestamp)")
            }
        }
        
        isLoading = false
    }
    
    private func formatAPITimeString(_ timestamp: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let date = formatter.date(from: timestamp) {
            formatter.dateFormat = "h:mm a"  // Fixed: Added :mm to show minutes
            return formatter.string(from: date)
        }
        
        return "Now"
    }
} 
