//
//  LocationTrackingManager.swift
//  moodgpt
//
//  Created by Test on 5/27/25.
//

import Foundation
import CoreLocation
import Combine

class LocationTrackingManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private var timer: Timer?
    private let apiManager = APIManager.shared
    
    @Published var isTracking = false
    @Published var lastKnownLocation: CLLocation?
    @Published var trackingStatus = "Not tracking"
    @Published var currentUsername: String = "" // Will be set from AuthManager
    @Published var isAutoLoggingEnabled = true
    @Published var lastAutoLogTime: Date?
    
    // Track if we've sent the initial location after app start
    private var hasInitialLocationBeenSent = false
    private let autoLogInterval: TimeInterval = 60
    
    override init() {
        super.init()
        setupLocationManager()
        
        // Load auto logging settings
//        isAutoLoggingEnabled = UserDefaults.standard.bool(forKey: "AutoLocationLoggingEnabled")
        if let lastLogTime = UserDefaults.standard.object(forKey: "LastAutoLocationLogTime") as? Date {
            lastAutoLogTime = lastLogTime
        }
    }
    
    deinit {
        stopTracking()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Only update if moved 10 meters
    }
    
    // Update username from authentication system
    func setUsername(_ username: String) {
        currentUsername = username.isEmpty ? "guest" : username
    }
    
    // Enable or disable auto location logging
    func enableAutoLogging(_ enabled: Bool) {
        isAutoLoggingEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "AutoLocationLoggingEnabled")
        
        if enabled && isTracking {
            startLocationTimer()
        } else {
            stopLocationTimer()
        }
    }
    
    // MARK: - Public Methods
    func startTracking() {
        guard !isTracking else {
            return
        }
        
        // Reset initial location flag when starting fresh
        hasInitialLocationBeenSent = false
        
        // Request location permissions
        requestLocationPermission()
        
        // Start location updates
        locationManager.startUpdatingLocation()
        
        // Start timer for API calls every 5 minutes if auto logging is enabled
        if isAutoLoggingEnabled {
            startLocationTimer()
        }
        
        isTracking = true
        trackingStatus = "Tracking active - waiting for location..."
    }
    
    func stopTracking() {
        stopLocationTimer()
        locationManager.stopUpdatingLocation()
        
        isTracking = false
        trackingStatus = "Tracking stopped"
    }
    
    // MARK: - Location Permission
    private func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            trackingStatus = "Location permission denied"
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            break
        }
    }
    
    // MARK: - Timer Management
    private func startLocationTimer() {
        // Stop any existing timer
        stopLocationTimer()
        
        // Set up timer to send every 5 minutes (300 seconds)
        timer = Timer.scheduledTimer(withTimeInterval: autoLogInterval, repeats: true) { [weak self] _ in
            self?.performAutoLocationLog()
        }
    }
    
    private func stopLocationTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func performAutoLocationLog() {
        guard isAutoLoggingEnabled else {
            return
        }
        
        lastAutoLogTime = Date()
        UserDefaults.standard.set(lastAutoLogTime, forKey: "LastAutoLocationLogTime")
        
        sendCurrentLocationToAPI()
    }
    
    // MARK: - API Communication
    private func sendCurrentLocationToAPI() {
        guard let location = lastKnownLocation else {
            trackingStatus = "No location available - getting location..."
            return
        }
        
        let actualUsername = currentUsername.isEmpty ? "guest" : currentUsername
        
        trackingStatus = "Sending to location API..."
        
        apiManager.insertLocation(
            username: actualUsername,
            longitude: location.coordinate.longitude,
            latitude: location.coordinate.latitude
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleLocationAPIResponse(result: result)
            }
        }
    }
    
    private func handleLocationAPIResponse(result: Result<InsertLocationResponse, APIError>) {
        switch result {
        case .success(let response):
            trackingStatus = "Location sent successfully: \(response.message)"
        case .failure(let error):
            trackingStatus = "Location error: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Manual Location Update (for testing)
    func sendTestLocation() {
        // Use test coordinates matching the API example
        let testLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        lastKnownLocation = testLocation
        
        let actualUsername = currentUsername.isEmpty ? "guest" : currentUsername
        
        apiManager.insertLocation(
            username: actualUsername,
            longitude: testLocation.coordinate.longitude,
            latitude: testLocation.coordinate.latitude
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleLocationAPIResponse(result: result)
            }
        }
    }
    
    // MARK: - Manual Location Log
    func logLocationNow() {
        guard lastKnownLocation != nil else {
            trackingStatus = "No location available"
            return
        }
        
        sendCurrentLocationToAPI()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationTrackingManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        lastKnownLocation = location
        
        // If this is the first location after starting tracking, send it immediately
        if isTracking && !hasInitialLocationBeenSent {
            hasInitialLocationBeenSent = true
            sendCurrentLocationToAPI()
        }
        
        // Update status to show we have location data
        if isTracking {
            let autoStatus = isAutoLoggingEnabled ? "sending every 5 minutes" : "manual only"
            trackingStatus = "Location active - \(autoStatus)"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        trackingStatus = "Location error: \(error.localizedDescription)"
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            trackingStatus = "Permission granted - getting location..."
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            trackingStatus = "Location permission denied"
            stopTracking()
        case .notDetermined:
            trackingStatus = "Requesting location permission..."
        @unknown default:
            trackingStatus = "Unknown permission status"
        }
    }
}

// MARK: - Data Models
// LocationAPIData is now handled by the centralized APIManager
