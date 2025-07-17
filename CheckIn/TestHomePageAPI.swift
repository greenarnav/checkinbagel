//
//  TestHomePageAPI.swift
//  moodgpt
//
//  Created by Test on 6/3/25.
//

import Foundation

/// Test class to verify our home page API integration
class TestHomePageAPI {
    
    /// Test the complete flow: set username, send health data, get analysis
    static func testCompleteFlow() {
        let healthDataManager = HealthDataManager()
        
        // Step 1: Set username (simulating login)
        healthDataManager.setUsername("testuser123")
        
        // Step 2: Send some test health data
        healthDataManager.sendTestHealthData()
        
        // Step 3: Fetch user analysis (home page API)
        healthDataManager.fetchUserAnalysis()
        
        // Step 4: Test combined operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            healthDataManager.sendHealthDataAndFetchAnalysis()
        }
        
        print("✅ Test initiated - check the API responses!")
    }
    
    /// Test just the home page API (user analysis)
    static func testHomePageAPIOnly() {
        let apiManager = APIManager.shared
        
        // Test the home page API directly
        apiManager.fetchUserAnalysis(for: "testuser123") { result in
            switch result {
            case .success(let analysis):
                print("✅ Home Page API Success!")
                print("📱 Emoji ID: \(analysis.emojiId)")
                print("💬 Zinger Caption: \(analysis.zingerCaption)")
                print("🌟 Social Vibe: \(analysis.socialVibe)")
                print("🧠 Mental Pulse: \(analysis.mentalPulse)")
                print("🤖 AI Scoop: \(analysis.aiScoop)")
                print("📊 Analytics Points: \(analysis.crispAnalyticsPoints)")
            case .failure(let error):
                print("❌ Home Page API Error: \(error)")
            }
        }
    }
} 