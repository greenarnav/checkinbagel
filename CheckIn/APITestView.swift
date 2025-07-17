//
//  APITestView.swift
//  moodgpt
//
//  Created by Test on 6/3/25.
//

import SwiftUI
import CoreLocation

struct APITestView: View {
    @ObservedObject var healthDataManager = HealthDataManager()
    @ObservedObject var authManager = AuthManager()
    @ObservedObject var activityManager = ActivityTrackingManager()
    @ObservedObject var locationManager = LocationTrackingManager()
    @ObservedObject var integratedDataManager = IntegratedDataManager.shared
    
    // Private API manager for testing
    private let apiManager = APIManager.shared
    
    @State private var apiResponse: String = "No response yet"
    @State private var isLoading = false
    @State private var userAnalysisData: UserAnalysisResponse?
    @State private var testResults: [String] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    
                    // Main API Test Buttons
                    apiTestSection
                    
                    // User Analysis Display
                    if let analysis = userAnalysisData {
                        userAnalysisSection(analysis: analysis)
                    }
                    
                    // Test Results
                    testResultsSection
                    
                    // API Response Display
                    responseSection
                }
                .padding()
            }
        }
        .navigationTitle("API Test Center")
        .onAppear {
            // Initialize with current auth username
            if !authManager.currentUsername.isEmpty {
                healthDataManager.setUsername(authManager.currentUsername)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("API Test Center")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Test all API endpoints with real data")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Current User:")
                    .fontWeight(.medium)
                Text(authManager.currentUsername.isEmpty ? "Not logged in" : authManager.currentUsername)
                    .foregroundColor(authManager.currentUsername.isEmpty ? .red : .green)
            }
            .padding(.vertical, 5)
        }
    }
    
    private var apiTestSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("API Tests")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                
                // Home Page API Test
                apiTestButton(
                    title: "Home Page API",
                    subtitle: "User Analysis",
                    color: .blue,
                    systemImage: "house.fill"
                ) {
                    testHomePageAPI()
                }
                
                // Combined Test
                apiTestButton(
                    title: "Complete Flow",
                    subtitle: "Health + Analysis",
                    color: .green,
                    systemImage: "arrow.triangle.2.circlepath"
                ) {
                    testCompleteFlow()
                }
                
                // Auth Tests
                apiTestButton(
                    title: "Auth Test",
                    subtitle: "Login/Register",
                    color: .orange,
                    systemImage: "person.badge.key.fill"
                ) {
                    testAuthAPI()
                }
                
                // Health Data Test
                apiTestButton(
                    title: "Health Data",
                    subtitle: "Send Health Info",
                    color: .red,
                    systemImage: "heart.fill"
                ) {
                    testHealthDataAPI()
                }
                
                // Location Test
                apiTestButton(
                    title: "Location API",
                    subtitle: "Send Location",
                    color: .purple,
                    systemImage: "location.fill"
                ) {
                    testLocationAPI()
                }
                
                // Contact APIs Test
                apiTestButton(
                    title: "Contact APIs",
                    subtitle: "Phone & Contacts",
                    color: .teal,
                    systemImage: "phone.fill"
                ) {
                    testContactAPIs()
                }
                
                // Logger APIs Test
                apiTestButton(
                    title: "Logger APIs",
                    subtitle: "Activity & Data",
                    color: .mint,
                    systemImage: "doc.text.fill"
                ) {
                    testLoggerAPIs()
                }
                
                // Follower APIs Test
                apiTestButton(
                    title: "Follower APIs",
                    subtitle: "Follow & Unfollow",
                    color: .purple,
                    systemImage: "person.2.fill"
                ) {
                    testFollowerAPIs()
                }
                
                // Celebrity APIs Test
                apiTestButton(
                    title: "Celebrity APIs",
                    subtitle: "List & Scoop",
                    color: .pink,
                    systemImage: "star.fill"
                ) {
                    testCelebrityAPIs()
                }
                
                // All APIs Test
                apiTestButton(
                    title: "Test All APIs",
                    subtitle: "Comprehensive",
                    color: .indigo,
                    systemImage: "checkmark.circle.fill"
                ) {
                    testAllAPIs()
                }
            }
        }
    }
    
    private func apiTestButton(
        title: String,
        subtitle: String,
        color: Color,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .disabled(isLoading)
    }
    
    private func userAnalysisSection(analysis: UserAnalysisResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest User Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Emoji ID:")
                        .fontWeight(.medium)
                    Text("\(analysis.emojiId)")
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Zinger Caption:")
                        .fontWeight(.medium)
                    Text(analysis.zingerCaption)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Social Vibe:")
                        .fontWeight(.medium)
                    Text(analysis.socialVibe)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mental Pulse:")
                        .fontWeight(.medium)
                    Text(analysis.mentalPulse)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Scoop:")
                        .fontWeight(.medium)
                    Text(analysis.aiScoop)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if !analysis.crispAnalyticsPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analytics Points:")
                            .fontWeight(.medium)
                        ForEach(analysis.crispAnalyticsPoints, id: \.self) { point in
                            Text("• \(point)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    private var testResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Results")
                .font(.headline)
                .fontWeight(.semibold)
            
            if testResults.isEmpty {
                Text("No tests run yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(testResults.indices, id: \.self) { index in
                            Text(testResults[index])
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(testResults[index].contains("✅") ? Color.green.opacity(0.1) : 
                                              testResults[index].contains("❌") ? Color.red.opacity(0.1) : Color(.systemGray6))
                                )
                        }
                    }
                }
                .frame(maxHeight: 200)
                
                Button("Clear Results") {
                    testResults.removeAll()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
    }
    
    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("API Response")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView {
                Text(apiResponse)
                    .font(.caption)
                    .monospaced()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            }
            .frame(maxHeight: 200)
            
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Running API test...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - API Test Methods (Updated for Completion Handlers)
    
    private func testHomePageAPI() {
        guard !authManager.currentUsername.isEmpty else {
            addTestResult("❌ Home Page API: No username available")
            return
        }
        
        setLoadingState(true, message: "Testing Home Page API...")
        addTestResult("🔄 Testing Home Page API...")
        
        apiManager.fetchUserAnalysis(for: authManager.currentUsername) { [self] result in
            DispatchQueue.main.async {
                setLoadingState(false, message: "Home Page API test completed")
                
                switch result {
                case .success(let analysis):
                    userAnalysisData = analysis
                    addTestResult("✅ Home Page API: Success - Emoji ID: \(analysis.emojiId)")
                    addTestResult("📝 Zinger: \(analysis.zingerCaption)")
                case .failure(let error):
                    addTestResult("❌ Home Page API: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func testAuthAPI() {
        setLoadingState(true, message: "Testing Authentication API...")
        addTestResult("🔄 Testing Auth API...")
        
        // Test social auth first (most likely to succeed)
        apiManager.socialAuth(username: authManager.currentUsername.isEmpty ? "testuser@example.com" : authManager.currentUsername) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        addTestResult("✅ Social Auth: Success - \(response.message ?? "Login successful")")
                    } else {
                        addTestResult("❌ Social Auth: Failed - \(response.message ?? "Unknown error")")
                    }
                case .failure(let error):
                    addTestResult("❌ Social Auth: \(error.localizedDescription)")
                }
                
                // Test register API
                testRegisterAPI()
            }
        }
    }
    
    private func testRegisterAPI() {
        let testUsername = "testuser\(Int.random(in: 1000...9999))@example.com"
        
        apiManager.register(username: testUsername, password: "testpass123") { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        addTestResult("✅ Register: Success - \(response.message ?? "Registration successful")")
                    } else {
                        addTestResult("❌ Register: Failed - \(response.message ?? "Unknown error")")
                    }
                case .failure(let error):
                    addTestResult("❌ Register: \(error.localizedDescription)")
                }
                
                setLoadingState(false, message: "Authentication tests completed")
            }
        }
    }
    
    private func testHealthDataAPI() {
        guard !authManager.currentUsername.isEmpty else {
            addTestResult("❌ Health Data API: No username available")
            return
        }
        
        setLoadingState(true, message: "Testing Health Data API...")
        addTestResult("🔄 Testing Health Data API...")
        
        let sampleHealthData: [String: Any] = [
            "heart_rate": 75,
            "steps": 8500,
            "sleep_hours": 7.5,
            "weight": 70.0,
            "blood_pressure": "120/80"
        ]
        
        apiManager.sendHealthData(username: authManager.currentUsername, healthData: sampleHealthData) { [self] result in
            DispatchQueue.main.async {
                setLoadingState(false, message: "Health Data API test completed")
                
                switch result {
                case .success(let response):
                    addTestResult("✅ Health Data: Success - \(response.message)")
                case .failure(let error):
                    addTestResult("❌ Health Data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func testLocationAPI() {
        guard !authManager.currentUsername.isEmpty else {
            addTestResult("❌ Location API: No username available")
            return
        }
        
        setLoadingState(true, message: "Testing Location API...")
        addTestResult("🔄 Testing Location API...")
        
        // Test with NYC coordinates
        apiManager.insertLocation(username: authManager.currentUsername, longitude: -73.9851, latitude: 40.7589) { [self] result in
            DispatchQueue.main.async {
                setLoadingState(false, message: "Location API test completed")
                
                switch result {
                case .success(let response):
                    addTestResult("✅ Location: Success - \(response.message)")
                case .failure(let error):
                    addTestResult("❌ Location: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func testCompleteFlow() {
        guard !authManager.currentUsername.isEmpty else {
            addTestResult("❌ Complete Flow: No username available")
            return
        }
        
        setLoadingState(true, message: "Testing Complete Flow...")
        addTestResult("🔄 Testing Complete Flow (Health + Analysis)...")
        
        let sampleHealthData: [String: Any] = [
            "heart_rate": 72,
            "steps": 10000,
            "sleep_hours": 8.0,
            "active_calories": 450
        ]
        
        apiManager.sendHealthDataAndFetchAnalysis(username: authManager.currentUsername, healthData: sampleHealthData) { [self] result in
            DispatchQueue.main.async {
                setLoadingState(false, message: "Complete flow test completed")
                
                switch result {
                case .success(let analysis):
                    userAnalysisData = analysis
                    addTestResult("✅ Complete Flow: Success - Health data sent and analysis received")
                    addTestResult("📊 Analysis: Emoji ID \(analysis.emojiId), Caption: \(analysis.zingerCaption)")
                case .failure(let error):
                    addTestResult("❌ Complete Flow: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func testContactAPIs() {
        guard !authManager.currentUsername.isEmpty else {
            addTestResult("❌ Contact APIs: No username available")
            return
        }
        
        setLoadingState(true, message: "Testing Contact APIs...")
        addTestResult("🔄 Testing Contact APIs...")
        
        // Test Check Phone API
        apiManager.checkPhone(username: authManager.currentUsername) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.exists {
                        addTestResult("✅ Check Phone: Phone exists - \(response.phno ?? "No number")")
                    } else {
                        addTestResult("📱 Check Phone: No phone number found")
                    }
                case .failure(let error):
                    addTestResult("❌ Check Phone: \(error.localizedDescription)")
                }
                
                // Test Update Phone API
                testUpdatePhoneAPI()
            }
        }
    }
    
    private func testUpdatePhoneAPI() {
        let testPhoneNumber = "9876543210"
        
        apiManager.updatePhone(username: authManager.currentUsername, phone: testPhoneNumber) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        addTestResult("✅ Update Phone: Success - \(response.message)")
                    } else {
                        addTestResult("❌ Update Phone: Failed - \(response.message)")
                    }
                case .failure(let error):
                    addTestResult("❌ Update Phone: \(error.localizedDescription)")
                }
                
                // Test Add Contacts API
                testAddContactsAPI()
            }
        }
    }
    
    private func testAddContactsAPI() {
        let testContacts = ["friend1@example.com", "friend2@example.com", "friend3@example.com"]
        
        apiManager.addContacts(username: authManager.currentUsername, contacts: testContacts) { [self] result in
            DispatchQueue.main.async {
                setLoadingState(false, message: "Contact APIs test completed")
                
                switch result {
                case .success(let response):
                    addTestResult("✅ Add Contacts: Success - \(response.message)")
                case .failure(let error):
                    addTestResult("❌ Add Contacts: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func testLoggerAPIs() {
        guard !authManager.currentUsername.isEmpty else {
            addTestResult("❌ Logger APIs: No username available")
            return
        }
        
        setLoadingState(true, message: "Testing Logger APIs...")
        addTestResult("🔄 Testing Logger APIs...")
        
        // Test Log Activity API
        let currentTime = ISO8601DateFormatter().string(from: Date())
        apiManager.logActivity(email: authManager.currentUsername, action: "api_test", time: currentTime) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    addTestResult("✅ Log Activity: Success - \(response.message)")
                case .failure(let error):
                    addTestResult("❌ Log Activity: \(error.localizedDescription)")
                }
                
                // Test Insert Health API
                testInsertHealthAPI()
            }
        }
    }
    
    private func testInsertHealthAPI() {
        let testHealthData: [String: Any] = [
            "heart_rate": 75,
            "steps": 8500,
            "active_calories": 320,
            "sleep_hours": 7.5
        ]
        
        apiManager.insertHealth(username: authManager.currentUsername, healthData: testHealthData) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    addTestResult("✅ Insert Health: Success - \(response.message)")
                case .failure(let error):
                    addTestResult("❌ Insert Health: \(error.localizedDescription)")
                }
                
                // Test Insert Location API
                testInsertLocationAPI()
            }
        }
    }
    
    private func testInsertLocationAPI() {
        // Test with NYC coordinates
        apiManager.insertLocation(username: authManager.currentUsername, longitude: -73.9851, latitude: 40.7589) { [self] result in
            DispatchQueue.main.async {
                setLoadingState(false, message: "Logger APIs test completed")
                
                switch result {
                case .success(let response):
                    addTestResult("✅ Insert Location: Success - \(response.message)")
                case .failure(let error):
                    addTestResult("❌ Insert Location: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func testFollowerAPIs() {
        guard !authManager.currentUsername.isEmpty else {
            addTestResult("❌ Follower APIs: No username available")
            return
        }
        
        setLoadingState(true, message: "Testing Follower APIs...")
        addTestResult("🔄 Testing Follower APIs...")
        
        // Test Follow API
        let testUser = "9876543210"
        apiManager.followUser(user: testUser, follower: authManager.currentUsername) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    addTestResult("✅ Follow User: Success - \(response.message)")
                case .failure(let error):
                    addTestResult("❌ Follow User: \(error.localizedDescription)")
                }
                
                // Test Get Followers API
                testGetFollowersAPI()
            }
        }
    }
    
    private func testGetFollowersAPI() {
        apiManager.getFollowers(user: authManager.currentUsername) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    addTestResult("✅ Get Followers: Success - User: \(response.user), Followers: \(response.followers.count)")
                    if !response.followers.isEmpty {
                        addTestResult("📋 Followers list: \(response.followers.joined(separator: ", "))")
                    }
                case .failure(let error):
                    addTestResult("❌ Get Followers: \(error.localizedDescription)")
                }
                
                // Test Unfollow API
                testUnfollowAPI()
            }
        }
    }
    
    private func testUnfollowAPI() {
        let testUser = "9876543210"
        apiManager.unfollowUser(user: testUser, follower: authManager.currentUsername) { [self] result in
            DispatchQueue.main.async {
                setLoadingState(false, message: "Follower APIs test completed")
                
                switch result {
                case .success(let response):
                    addTestResult("✅ Unfollow User: Success - \(response.message)")
                case .failure(let error):
                    addTestResult("❌ Unfollow User: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func testCelebrityAPIs() {
        setLoadingState(true, message: "Testing Celebrity APIs...")
        addTestResult("🔄 Testing Celebrity APIs...")
        
        // Test Celebrity List API first
        apiManager.fetchCelebrityList { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let count = response.celebrities.count
                    addTestResult("✅ Celebrity List: Success - \(count) celebrities loaded")
                    
                    if count > 0 {
                        let firstCelebrity = response.celebrities[0]
                        addTestResult("👑 First celebrity: \(firstCelebrity.name) (ID: \(firstCelebrity.id))")
                        
                        // Test Celebrity Scoop API with the first celebrity
                        testCelebrityScoopAPI(celebrityName: firstCelebrity.name)
                    } else {
                        setLoadingState(false, message: "Celebrity APIs test completed")
                        addTestResult("⚠️ No celebrities found to test scoop API")
                    }
                    
                case .failure(let error):
                    addTestResult("❌ Celebrity List: \(error.localizedDescription)")
                    setLoadingState(false, message: "Celebrity APIs test completed")
                }
            }
        }
    }
    
    private func testCelebrityScoopAPI(celebrityName: String) {
        addTestResult("🔄 Testing Celebrity Scoop for \(celebrityName)...")
        
        apiManager.fetchCelebrityScoop(celebrityName: celebrityName) { [self] result in
            DispatchQueue.main.async {
                setLoadingState(false, message: "Celebrity APIs test completed")
                
                switch result {
                case .success(let response):
                    addTestResult("✅ Celebrity Scoop: Success for \(response.name)")
                    let scoopPreview = String(response.scoop.prefix(100)) + (response.scoop.count > 100 ? "..." : "")
                    addTestResult("📰 Scoop preview: \(scoopPreview)")
                    addTestResult("⏰ Timestamp: \(response.timestamp)")
                    
                case .failure(let error):
                    addTestResult("❌ Celebrity Scoop: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func testAllAPIs() {
        guard !authManager.currentUsername.isEmpty else {
            addTestResult("❌ Cannot test all APIs: No username available")
            return
        }
        
        addTestResult("🚀 Starting comprehensive API test suite...")
        
        // Test APIs sequentially to avoid overwhelming the server
        testAuthAPI()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.testHealthDataAPI()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.testLocationAPI()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            self.testContactAPIs()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            self.testLoggerAPIs()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.testFollowerAPIs()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
            self.testCelebrityAPIs()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 14) {
            self.testHomePageAPI()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 16) {
            self.addTestResult("🏁 Comprehensive API test suite completed")
        }
    }
    
    // MARK: - Helper Methods
    
    private func setLoadingState(_ loading: Bool, message: String) {
        isLoading = loading
        apiResponse = message
    }
    
    private func addTestResult(_ result: String) {
        let timestamp = DateFormatter()
        timestamp.timeStyle = .medium
        let timestampedResult = "[\(timestamp.string(from: Date()))] \(result)"
        testResults.append(timestampedResult)
    }
}

#Preview {
    APITestView()
} 