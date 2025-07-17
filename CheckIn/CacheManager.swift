//
//  CacheManager.swift
//  CheckIn
//
//  Cache manager for storing API responses locally
//

import Foundation

// MARK: - Cache Manager
class CacheManager {
    static let shared = CacheManager()
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    // Cache keys
    private enum CacheKey: String {
        case userAnalysis = "cached_user_analysis"
        case celebrityList = "cached_celebrity_list"
        case contactsSentiment = "cached_contacts_sentiment"
        case homeTimeline = "cached_home_timeline"
        case emotionSnapshot = "cached_emotion_snapshot"
    }
    
    private init() {
        // Get documents directory for larger data
        documentsDirectory = fileManager.urls(for: .documentDirectory, 
                                            in: .userDomainMask).first!
    }
    
    // MARK: - User Analysis Cache
    
    func cacheUserAnalysis(_ analysis: UserAnalysisResponse, for username: String) {
        let key = "\(CacheKey.userAnalysis.rawValue)_\(username)"
        
        if let encoded = try? JSONEncoder().encode(analysis) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    func getCachedUserAnalysis(for username: String) -> UserAnalysisResponse? {
        let key = "\(CacheKey.userAnalysis.rawValue)_\(username)"
        
        guard let data = userDefaults.data(forKey: key),
              let analysis = try? JSONDecoder().decode(UserAnalysisResponse.self, from: data) else {
            return nil
        }
        
        return analysis
    }
    
    // MARK: - Celebrity Cache
    
    func cacheCelebrityList(_ celebrities: [Celebrity]) {
        let fileURL = documentsDirectory.appendingPathComponent("celebrity_cache.json")
        
        if let encoded = try? JSONEncoder().encode(celebrities) {
            try? encoded.write(to: fileURL)
        }
    }
    
    func getCachedCelebrityList() -> [Celebrity]? {
        let fileURL = documentsDirectory.appendingPathComponent("celebrity_cache.json")
        
        guard let data = try? Data(contentsOf: fileURL),
              let celebrities = try? JSONDecoder().decode([Celebrity].self, from: data) else {
            return nil
        }
        
        return celebrities
    }
    
    // MARK: - Home Timeline Cache
    
    func cacheHomeTimeline(_ timeline: [(String, String, String, Bool)], for username: String) {
        let key = "\(CacheKey.homeTimeline.rawValue)_\(username)"
        
        // Convert tuples to a codable structure
        let timelineData = timeline.map { TimelineItem(time: $0.0, emoji: $0.1, mood: $0.2, isPrediction: $0.3) }
        
        if let encoded = try? JSONEncoder().encode(timelineData) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    func getCachedHomeTimeline(for username: String) -> [(String, String, String, Bool)]? {
        let key = "\(CacheKey.homeTimeline.rawValue)_\(username)"
        
        guard let data = userDefaults.data(forKey: key),
              let timelineData = try? JSONDecoder().decode([TimelineItem].self, from: data) else {
            return nil
        }
        
        return timelineData.map { ($0.time, $0.emoji, $0.mood, $0.isPrediction) }
    }
    
    // MARK: - Contacts Sentiment Cache
    
    func cacheContactsSentiment(_ sentiment: [String: Any], for username: String) {
        let key = "\(CacheKey.contactsSentiment.rawValue)_\(username)"
        
        if let data = try? JSONSerialization.data(withJSONObject: sentiment, options: []) {
            userDefaults.set(data, forKey: key)
        }
    }
    
    func getCachedContactsSentiment(for username: String) -> [String: Any]? {
        let key = "\(CacheKey.contactsSentiment.rawValue)_\(username)"
        
        guard let data = userDefaults.data(forKey: key),
              let sentiment = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        
        return sentiment
    }
    
    // MARK: - Emotion Snapshot Cache
    
    func cacheEmotionSnapshot(_ snapshot: EmotionSnapshot, for username: String) {
        let key = "\(CacheKey.emotionSnapshot.rawValue)_\(username)"
        
        if let encoded = try? JSONEncoder().encode(snapshot) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    func getCachedEmotionSnapshot(for username: String) -> EmotionSnapshot? {
        let key = "\(CacheKey.emotionSnapshot.rawValue)_\(username)"
        
        guard let data = userDefaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(EmotionSnapshot.self, from: data) else {
            return nil
        }
        
        return snapshot
    }
    
    // MARK: - Clear User Cache (for logout)
    
    func clearUserCache(for username: String) {
        let keys = [
            "\(CacheKey.userAnalysis.rawValue)_\(username)",
            "\(CacheKey.homeTimeline.rawValue)_\(username)",
            "\(CacheKey.contactsSentiment.rawValue)_\(username)",
            "\(CacheKey.emotionSnapshot.rawValue)_\(username)"
        ]
        
        keys.forEach { userDefaults.removeObject(forKey: $0) }
    }
}

// MARK: - Helper Models

private struct TimelineItem: Codable {
    let time: String
    let emoji: String
    let mood: String
    let isPrediction: Bool
}

// MARK: - EmotionSnapshot for Caching
struct EmotionSnapshot: Codable {
    let aiScoop: String
    let mentalPulse: String
    let socialVibe: String
    let timestamp: Date
} 