//
//  IntegratedDataManager.swift
//  moodgpt
//
//  Created by Test on 6/3/25.
//

import Foundation
import CoreLocation
import HealthKit

class IntegratedDataManager: NSObject, ObservableObject {
    
    static let shared = IntegratedDataManager()
    
    // MARK: - Dependencies
    private let apiManager = APIManager.shared
    private let healthKitManager = HealthKitManager()
    private let locationManager = CLLocationManager()
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var lastSyncDate: Date?
    @Published var healthData: SimpleHealthData?
    @Published var currentLocation: SimpleLocationCoordinate?
    @Published var userAnalysis: UserAnalysisResponse?
    @Published var contactsSentiment: [String: SimpleContactSentiment] = [:]
    @Published var errorMessage: String?
    @Published var syncStatus = "Ready to sync"
    
    // MARK: - Sync Configuration
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 300 // 5 minutes
    
    // MARK: - User Information
    var currentUsername: String {
        return AuthManager().currentUsername
    }
    
    var currentUserEmail: String {
        return "\(currentUsername)@checkin.app"
    }
    
    override init() {
        super.init()
        setupLocationManager()
        setupAutoSync()
        
        // Load last sync date
        if let lastSync = UserDefaults.standard.object(forKey: "LastSyncDate") as? Date {
            lastSyncDate = lastSync
        }
    }
    
    // MARK: - Location Setup
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Auto Sync Setup
    
    private func setupAutoSync() {
        // Start timer for periodic sync
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            self?.performFullSync()
        }
        
        // Perform initial sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.performFullSync()
        }
    }
    
    // MARK: - Full Data Sync
    
    func performFullSync() {
        guard !currentUsername.isEmpty else {
            syncStatus = "No user logged in"
            return
        }
        
        isLoading = true
        syncStatus = "Syncing data..."
        
        // Start location update
        requestLocationUpdate()
        
        // Collect health data and sync
        collectHealthData { [weak self] healthData in
            self?.healthData = healthData
            self?.syncHealthData(healthData)
        }
        
        // Sync location after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.syncLocationData()
        }
        
        // Get user analysis
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.fetchUserAnalysis()
        }
        
        // Update sync status
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.isLoading = false
            self.lastSyncDate = Date()
            self.syncStatus = "Last synced: \(self.formatSyncTime())"
            UserDefaults.standard.set(self.lastSyncDate, forKey: "LastSyncDate")
        }
    }
    
    // MARK: - Health Data Collection
    
    private func collectHealthData(completion: @escaping (SimpleHealthData) -> Void) {
        var healthData = SimpleHealthData(
            heart_rate: nil,
            steps: nil,
            sleep_hours: nil,
            calories_burned: nil,
            distance_miles: nil,
            active_minutes: nil
        )
        
        let group = DispatchGroup()
        
        // Get steps
        group.enter()
        healthKitManager.getTodayStepCount { steps in
            healthData = SimpleHealthData(
                heart_rate: healthData.heart_rate,
                steps: steps.map { Int($0) },
                sleep_hours: healthData.sleep_hours,
                calories_burned: healthData.calories_burned,
                distance_miles: healthData.distance_miles,
                active_minutes: healthData.active_minutes
            )
            group.leave()
        }
        
        // Get sleep
        group.enter()
        healthKitManager.getLastNightSleep { sleepDuration in
            let sleepHours = sleepDuration.map { $0 / 3600.0 }
            healthData = SimpleHealthData(
                heart_rate: healthData.heart_rate,
                steps: healthData.steps,
                sleep_hours: sleepHours,
                calories_burned: healthData.calories_burned,
                distance_miles: healthData.distance_miles,
                active_minutes: healthData.active_minutes
            )
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(healthData)
        }
    }
    
    // MARK: - Individual Sync Methods (Updated to use centralized APIManager)
    
    private func syncHealthData(_ healthData: SimpleHealthData) {
        // Convert to [String: Any] format
        let healthDict: [String: Any] = [
            "heart_rate": healthData.heart_rate as Any,
            "steps": healthData.steps as Any,
            "sleep_hours": healthData.sleep_hours as Any,
            "calories_burned": healthData.calories_burned as Any,
            "distance_miles": healthData.distance_miles as Any,
            "active_minutes": healthData.active_minutes as Any
        ]
        
        apiManager.sendHealthData(username: currentUsername, healthData: healthDict) { result in
            switch result {
            case .success(_):
                // Handle success silently
                break
            case .failure(_):
                // Handle error silently
                break
            }
        }
    }
    
    private func syncLocationData() {
        guard let location = currentLocation else { return }
        
                    apiManager.insertLocation(username: currentUsername, longitude: location.longitude, latitude: location.latitude) { result in
            switch result {
            case .success(_):
                // Handle success silently
                break
            case .failure(_):
                // Handle error silently
                break
            }
        }
    }
    
    // MARK: - User Analysis (Updated to use centralized APIManager)
    
    func fetchUserAnalysis() {
        apiManager.fetchUserAnalysis(for: currentUsername) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.userAnalysis = response
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Activity Logging (Updated to use centralized APIManager)
    
    func logScreenView(_ screenName: String) {
        let currentTime = ISO8601DateFormatter().string(from: Date())
        
        apiManager.logActivity(email: currentUserEmail, action: "screen_view_\(screenName)", time: currentTime) { result in
            switch result {
            case .success:
                // Handle success silently
                break
            case .failure:
                // Handle error silently
                break
            }
        }
    }
    
    func logButtonTap(_ buttonName: String, on screenName: String) {
        let currentTime = ISO8601DateFormatter().string(from: Date())
        
        apiManager.logActivity(email: currentUserEmail, action: "button_tap_\(buttonName)_on_\(screenName)", time: currentTime) { result in
            switch result {
            case .success:
                // Handle success silently
                break
            case .failure:
                // Handle error silently
                break
            }
        }
    }
    
    func logTimeSpent(on screenName: String, duration: TimeInterval) {
        let currentTime = ISO8601DateFormatter().string(from: Date())
        
        apiManager.logActivity(email: currentUserEmail, action: "time_spent_\(screenName)_\(Int(duration))s", time: currentTime) { result in
            switch result {
            case .success:
                // Handle success silently
                break
            case .failure:
                // Handle error silently
                break
            }
        }
    }
    
    // MARK: - Contacts Sentiment (Placeholder - not implemented yet)
    
    func fetchContactsSentiment(for contacts: [String: String]) {
        // Contacts sentiment analysis not yet implemented in centralized APIManager
        // Create placeholder data for now
        var sentimentData: [String: SimpleContactSentiment] = [:]
        for (contactName, _) in contacts {
            sentimentData[contactName] = SimpleContactSentiment(
                sentiment: "neutral",
                score: 0.5,
                emotion: "calm",
                recent_interactions: 0,
                mood_impact: "neutral"
            )
        }
        
        DispatchQueue.main.async {
            self.contactsSentiment = sentimentData
        }
    }
    
    // MARK: - Manual Refresh
    
    func refreshData() {
        performFullSync()
    }
    
    // MARK: - Location Request
    
    private func requestLocationUpdate() {
        if locationManager.authorizationStatus == .authorizedWhenInUse || 
           locationManager.authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
    
    // MARK: - Utility Methods
    
    private func formatSyncTime() -> String {
        guard let lastSync = lastSyncDate else { return "Never" }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: lastSync)
    }
    
    // MARK: - Cleanup
    
    deinit {
        syncTimer?.invalidate()
    }
}

// MARK: - Simple Data Models (Local to IntegratedDataManager)

struct SimpleHealthData {
    let heart_rate: Int?
    let steps: Int?
    let sleep_hours: Double?
    let calories_burned: Int?
    let distance_miles: Double?
    let active_minutes: Int?
}

struct SimpleLocationCoordinate {
    let latitude: Double
    let longitude: Double
    let timestamp: Date?
    let accuracy: Double?
}

struct SimpleContactSentiment {
    let sentiment: String?
    let score: Double?
    let emotion: String?
    let recent_interactions: Int?
    let mood_impact: String?
}

// MARK: - CLLocationManagerDelegate

extension IntegratedDataManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = SimpleLocationCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: Date(),
            accuracy: location.horizontalAccuracy
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location access failed: \(error.localizedDescription)"
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            requestLocationUpdate()
        case .denied, .restricted:
            errorMessage = "Location access denied"
        default:
            break
        }
    }
}

// MARK: - Screen Tracking Helper

extension IntegratedDataManager {
    
    /// Call this method when a view appears
    func trackViewAppearance(_ viewName: String) {
        logScreenView(viewName)
        
        // Store view appearance time for duration tracking
        UserDefaults.standard.set(Date(), forKey: "ViewAppearanceTime_\(viewName)")
    }
    
    /// Call this method when a view disappears
    func trackViewDisappearance(_ viewName: String) {
        // Calculate time spent on view
        if let appearanceTime = UserDefaults.standard.object(forKey: "ViewAppearanceTime_\(viewName)") as? Date {
            let duration = Date().timeIntervalSince(appearanceTime)
            if duration > 1.0 { // Only log if spent more than 1 second
                logTimeSpent(on: viewName, duration: duration)
            }
            UserDefaults.standard.removeObject(forKey: "ViewAppearanceTime_\(viewName)")
        }
    }
} 