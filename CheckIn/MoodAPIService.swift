//
//  MoodAPIService.swift
//  moodgpt
//
//  Created by Test on 6/1/25.
//

import Foundation

// All API models are now managed by the centralized APIManager
// This file contains only the MoodAPIService wrapper class

// MARK: - Mood API Service (Centralized)
// This service is now a lightweight wrapper around the centralized APIManager
class MoodAPIService: ObservableObject {
    private let apiManager = APIManager.shared
    
    init() {
        // No longer needs its own configuration - uses centralized APIManager
    }
    
    /// Fetch user mood using centralized APIManager
    func fetchUserMood(userId: String, completion: @escaping (Result<MoodResponse, APIError>) -> Void) {
        apiManager.fetchUserMood(userId: userId, completion: completion)
    }
    
    /// Update user mood using centralized APIManager
    func updateUserMood(userId: String, mood: MoodUpdateRequest, completion: @escaping (Result<MoodUpdateResponse, APIError>) -> Void) {
        apiManager.updateUserMood(userId: userId, mood: mood, completion: completion)
    }
    
    /// Fetch city mood using centralized APIManager
    func fetchCityMood(city: String, completion: @escaping (Result<CityMoodResponse, APIError>) -> Void) {
        apiManager.fetchCityMood(city: city, completion: completion)
    }
    
    /// Fetch contacts moods using centralized APIManager
    func fetchContactsMoods(contactIds: [String], completion: @escaping (Result<[ContactMoodResponse], APIError>) -> Void) {
        apiManager.fetchContactsMoods(contactIds: contactIds, completion: completion)
    }
    
    /// Analyze emotional pattern using centralized APIManager
    func analyzeEmotionalPattern(userId: String, timeRange: TimeRange, completion: @escaping (Result<EmotionalPatternResponse, APIError>) -> Void) {
        apiManager.analyzeEmotionalPattern(userId: userId, timeRange: timeRange, completion: completion)
    }
}

// MARK: - Usage Examples (Updated to use centralized APIManager)
extension MoodAPIService {
    
    /// Example usage for UI components
    @MainActor
    func loadUserMoodData(userId: String) {
        fetchUserMood(userId: userId) { result in
            switch result {
            case .success(let moodResponse):
                // Update UI with mood data
                print("User mood: \(moodResponse.mood) (confidence: \(moodResponse.confidence))")
            case .failure(let error):
                print("Failed to load mood: \(error.localizedDescription)")
            }
        }
    }
    
    /// Example batch operation
    func loadMultipleContactsMoods(contactIds: [String], completion: @escaping ([ContactMoodResponse]) -> Void) {
        fetchContactsMoods(contactIds: contactIds) { result in
            switch result {
            case .success(let moods):
                completion(moods)
            case .failure(let error):
                print("Failed to load contacts moods: \(error.localizedDescription)")
                completion([])
            }
        }
    }
} 