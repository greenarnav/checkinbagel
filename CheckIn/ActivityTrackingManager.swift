//
//  ActivityTrackingManager.swift
//  moodgpt
//
//  Created by Test on 6/1/25.
//

import Foundation
import SwiftUI
import UIKit
import Network

struct BehaviorActivity {
    let action: String
    let timestamp: String
    let tab: String
    let coordinates: CGPoint?
    let screenSize: CGSize?
    let duration: TimeInterval?
    let additionalData: [String: Any]
    
    init(action: String, tab: String = "", coordinates: CGPoint? = nil, screenSize: CGSize? = nil, duration: TimeInterval? = nil, additionalData: [String: Any] = [:]) {
        self.action = action
        self.timestamp = ISO8601DateFormatter().string(from: Date())
        self.tab = tab
        self.coordinates = coordinates
        self.screenSize = screenSize
        self.duration = duration
        self.additionalData = additionalData
    }
    
    func toAPIFormat() -> [String: Any] {
        var activity: [String: Any] = [
            "action": action,
            "timestamp": timestamp
        ]
        
        if !tab.isEmpty {
            activity["tab"] = tab
        }
        
        if let coords = coordinates, let screen = screenSize {
            activity["coordinates"] = [
                "x": coords.x,
                "y": coords.y,
                "screen_width": screen.width,
                "screen_height": screen.height,
                "relative_x": coords.x / screen.width,
                "relative_y": coords.y / screen.height
            ]
        }
        
        if let duration = duration {
            activity["duration_seconds"] = duration
        }
        
        // Merge additional data
        for (key, value) in additionalData {
            activity[key] = value
        }
        
        return activity
    }
}

class ActivityTrackingManager: ObservableObject {
    private let apiManager = APIManager.shared
    
    @Published var isTracking = false
    @Published var trackingStatus = "Not initialized"
    @Published var activitiesLogged = 0
    @Published var currentUserEmail: String = "" // Will be set from AuthManager
    
    // Behavior tracking state
    private var pendingActivities: [BehaviorActivity] = []
    private let maxBatchSize = 100
    private var sessionStartTime: Date?
    private var currentTab: String = ""
    private var tabStartTime: Date?
    private var tabTimings: [String: TimeInterval] = [:]
    private var lastInteractionTime: Date = Date()
    private var batchSendTimer: Timer?
    private var backgroundStartTime: Date?
    
    // Screen and interaction tracking
    private var currentScreenSize: CGSize = UIScreen.main.bounds.size
    private var currentScreen: String = ""
    private var screenStartTime: Date?
    
    init() {
        setupScreenSize()
    }
    
    deinit {
        endSession()
    }
    
    // MARK: - Setup and Configuration
    
    private func setupScreenSize() {
        currentScreenSize = UIScreen.main.bounds.size
    }
    
    func setUserEmail(_ email: String) {
        currentUserEmail = email.isEmpty ? "guest@guest.com" : email
    }
    
    // MARK: - Session Management
    
    func startSession() {
        sessionStartTime = Date()
        isTracking = true
        trackingStatus = "Active - Comprehensive tracking"
        
        logBehavior(
            action: "app_opened",
            additionalData: [
                "device_model": UIDevice.current.model,
                "system_version": UIDevice.current.systemVersion,
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
                "screen_size": "\(currentScreenSize.width)x\(currentScreenSize.height)"
            ]
        )
        
        setupBatchSending()
    }
    
    func endSession() {
        guard let startTime = sessionStartTime else { return }
        
        let sessionDuration = Date().timeIntervalSince(startTime)
        
        // Log tab exit if in a tab
        if !currentTab.isEmpty {
            exitTab(currentTab)
        }
        
        // Log screen exit if in a screen
        if !currentScreen.isEmpty {
            exitScreen(currentScreen)
        }
        
        logBehavior(
            action: "app_closed",
            duration: sessionDuration,
            additionalData: [
                "total_activities_logged": activitiesLogged,
                "tab_timings": tabTimings
            ]
        )
        
        // Force send all remaining activities
        sendAllPendingActivities()
        
        // Clean up
        batchSendTimer?.invalidate()
        batchSendTimer = nil
        
        isTracking = false
        trackingStatus = "Session ended"
    }
    
    // MARK: - App Lifecycle Tracking
    
    func appDidEnterBackground() {
        backgroundStartTime = Date()
        logBehavior(
            action: "app_backgrounded",
            additionalData: [
                "current_tab": currentTab,
                "current_screen": currentScreen
            ]
        )
        
        // Send pending activities before going to background
        sendAllPendingActivities()
    }
    
    func appWillEnterForeground() {
        if let backgroundTime = backgroundStartTime {
            let backgroundDuration = Date().timeIntervalSince(backgroundTime)
            logBehavior(
                action: "app_foregrounded",
                duration: backgroundDuration,
                additionalData: [
                    "background_duration_seconds": backgroundDuration,
                    "current_tab": currentTab,
                    "current_screen": currentScreen
                ]
            )
        }
        backgroundStartTime = nil
    }
    
    // MARK: - Tab Tracking with Precise Timing
    
    func enterTab(_ tabName: String, tabIndex: Int) {
        // Exit previous tab if any
        if !currentTab.isEmpty && currentTab != tabName {
            exitTab(currentTab)
        }
        
        currentTab = tabName
        tabStartTime = Date()
        
        logBehavior(
            action: "tab_entered",
            tab: tabName,
            additionalData: [
                "tab_name": tabName,
                "tab_index": tabIndex,
                "previous_tab": currentTab.isEmpty ? "none" : currentTab
            ]
        )
    }
    
    func exitTab(_ tabName: String) {
        guard currentTab == tabName, let startTime = tabStartTime else { return }
        
        let timeSpent = Date().timeIntervalSince(startTime)
        tabTimings[tabName] = (tabTimings[tabName] ?? 0) + timeSpent
        
        logBehavior(
            action: "tab_exited",
            tab: tabName,
            duration: timeSpent,
            additionalData: [
                "tab_name": tabName,
                "time_spent_seconds": timeSpent,
                "total_time_in_tab": tabTimings[tabName] ?? 0
            ]
        )
        
        currentTab = ""
        tabStartTime = nil
    }
    
    // MARK: - Screen Tracking
    
    func enterScreen(_ screenName: String, details: [String: Any] = [:]) {
        // Exit previous screen if any
        if !currentScreen.isEmpty && currentScreen != screenName {
            exitScreen(currentScreen)
        }
        
        currentScreen = screenName
        screenStartTime = Date()
        
        var screenDetails = details
        screenDetails["screen_name"] = screenName
        screenDetails["current_tab"] = currentTab
        
        logBehavior(
            action: "screen_entered",
            tab: currentTab,
            additionalData: screenDetails
        )
    }
    
    func exitScreen(_ screenName: String) {
        guard currentScreen == screenName, let startTime = screenStartTime else { return }
        
        let timeSpent = Date().timeIntervalSince(startTime)
        
        logBehavior(
            action: "screen_exited",
            tab: currentTab,
            duration: timeSpent,
            additionalData: [
                "screen_name": screenName,
                "time_spent_seconds": timeSpent
            ]
        )
        
        currentScreen = ""
        screenStartTime = nil
    }
    
    // MARK: - Touch and Interaction Tracking
    
    func trackTouchEvent(at coordinates: CGPoint, action: String, elementType: String = "unknown", elementId: String? = nil) {
        var touchData: [String: Any] = [
            "element_type": elementType,
            "touch_pressure": "normal", // Could be enhanced with force touch
            "interaction_type": "touch"
        ]
        
        if let elementId = elementId {
            touchData["element_id"] = elementId
        }
        
        logBehavior(
            action: action,
            tab: currentTab,
            coordinates: coordinates,
            screenSize: currentScreenSize,
            additionalData: touchData
        )
    }
    
    func trackButtonClick(_ buttonName: String, buttonType: String = "button", coordinates: CGPoint? = nil, additionalData: [String: Any] = [:]) {
        var buttonData = additionalData
        buttonData["button_name"] = buttonName
        buttonData["button_type"] = buttonType
        buttonData["interaction_method"] = coordinates != nil ? "touch" : "programmatic"
        
        logBehavior(
            action: "button_clicked",
            tab: currentTab,
            coordinates: coordinates,
            screenSize: coordinates != nil ? currentScreenSize : nil,
            additionalData: buttonData
        )
    }
    
    func trackSwipeGesture(direction: String, startPoint: CGPoint, endPoint: CGPoint, velocity: Double = 0) {
        let distance = sqrt(pow(endPoint.x - startPoint.x, 2) + pow(endPoint.y - startPoint.y, 2))
        
        logBehavior(
            action: "swipe_gesture",
            tab: currentTab,
            coordinates: startPoint,
            screenSize: currentScreenSize,
            additionalData: [
                "direction": direction,
                "start_point": ["x": startPoint.x, "y": startPoint.y],
                "end_point": ["x": endPoint.x, "y": endPoint.y],
                "distance": distance,
                "velocity": velocity
            ]
        )
    }
    
    func trackScrollBehavior(direction: String, distance: Double, startPoint: CGPoint, velocity: Double = 0) {
        logBehavior(
            action: "scroll_gesture",
            tab: currentTab,
            coordinates: startPoint,
            screenSize: currentScreenSize,
            additionalData: [
                "direction": direction,
                "distance": distance,
                "velocity": velocity,
                "scroll_type": "continuous"
            ]
        )
    }
    
    func trackTextInput(fieldName: String, fieldType: String, coordinates: CGPoint? = nil, textLength: Int? = nil) {
        var inputData: [String: Any] = [
            "field_name": fieldName,
            "field_type": fieldType,
            "input_method": "keyboard"
        ]
        
        if let textLength = textLength {
            inputData["text_length"] = textLength
        }
        
        logBehavior(
            action: "text_input",
            tab: currentTab,
            coordinates: coordinates,
            screenSize: coordinates != nil ? currentScreenSize : nil,
            additionalData: inputData
        )
    }
    
    // MARK: - Navigation Tracking
    
    func trackNavigationFlow(fromScreen: String, toScreen: String, navigationMethod: String, coordinates: CGPoint? = nil) {
        logBehavior(
            action: "navigation",
            tab: currentTab,
            coordinates: coordinates,
            screenSize: coordinates != nil ? currentScreenSize : nil,
            additionalData: [
                "from_screen": fromScreen,
                "to_screen": toScreen,
                "navigation_method": navigationMethod
            ]
        )
    }
    
    // MARK: - Enhanced User Behavior Tracking
    
    func trackCelebrityViewing(_ celebrityName: String, category: String, timeSpent: TimeInterval? = nil, coordinates: CGPoint? = nil) {
        var celebrityData: [String: Any] = [
            "celebrity_name": celebrityName,
            "celebrity_category": category,
            "action_type": "celebrity_view"
        ]
        
        if let timeSpent = timeSpent {
            celebrityData["time_spent_viewing"] = timeSpent
        }
        
        logBehavior(
            action: "celebrity_viewed",
            tab: currentTab,
            coordinates: coordinates,
            screenSize: coordinates != nil ? currentScreenSize : nil,
            additionalData: celebrityData
        )
        
        
    }
    
    func trackSettingsChange(_ settingName: String, oldValue: Any?, newValue: Any, settingType: String = "toggle") {
        let settingsData: [String: Any] = [
            "setting_name": settingName,
            "setting_type": settingType,
            "old_value": oldValue ?? "unknown",
            "new_value": newValue,
            "action_type": "setting_change"
        ]
        
        logBehavior(
            action: "settings_changed",
            tab: currentTab,
            additionalData: settingsData
        )
        

    }
    
    func trackContactInteraction(_ contactName: String, contactId: String? = nil, actionType: String, timeSpent: TimeInterval? = nil) {
        var contactData: [String: Any] = [
            "contact_name": contactName,
            "action_type": actionType,
            "interaction_type": "contact_interaction"
        ]
        
        if let contactId = contactId {
            contactData["contact_id"] = contactId
        }
        
        if let timeSpent = timeSpent {
            contactData["time_spent"] = timeSpent
        }
        
        logBehavior(
            action: "contact_interaction",
            tab: currentTab,
            additionalData: contactData
        )
        

    }
    
    func trackContactSelection(_ contacts: [String], selectionMethod: String = "manual") {
        let selectionData: [String: Any] = [
            "selected_contacts": contacts,
            "contact_count": contacts.count,
            "selection_method": selectionMethod,
            "action_type": "contact_selection"
        ]
        
        logBehavior(
            action: "contacts_selected",
            tab: currentTab,
            additionalData: selectionData
        )
        

    }
    
    func trackThemeChange(_ oldTheme: String, _ newTheme: String, trigger: String = "user_action") {
        let themeData: [String: Any] = [
            "old_theme": oldTheme,
            "new_theme": newTheme,
            "trigger": trigger,
            "action_type": "theme_change"
        ]
        
        logBehavior(
            action: "theme_changed",
            tab: currentTab,
            additionalData: themeData
        )
        

    }
    
    // MARK: - Custom Event Tracking
    
    func trackCustomEvent(_ eventName: String, coordinates: CGPoint? = nil, data: [String: Any] = [:]) {
        logBehavior(
            action: eventName,
            tab: currentTab,
            coordinates: coordinates,
            screenSize: coordinates != nil ? currentScreenSize : nil,
            additionalData: data
        )
    }
    
    // MARK: - Core Logging Method
    
    func logBehavior(action: String, tab: String? = nil, coordinates: CGPoint? = nil, screenSize: CGSize? = nil, duration: TimeInterval? = nil, additionalData: [String: Any] = [:]) {
        guard isTracking else { return }
        
        let currentTab = tab ?? self.currentTab
        let currentScreenSize = screenSize ?? self.currentScreenSize
        
        let activity = BehaviorActivity(
            action: action,
            tab: currentTab,
            coordinates: coordinates,
            screenSize: coordinates != nil ? currentScreenSize : nil,
            duration: duration,
            additionalData: additionalData
        )
        
        pendingActivities.append(activity)
        lastInteractionTime = Date()
        
        DispatchQueue.main.async {
            self.activitiesLogged += 1
            self.trackingStatus = "Active - \(self.activitiesLogged) activities logged"
        }
        
        // Send batch if limit reached
        if pendingActivities.count >= maxBatchSize {
            sendActivityBatch()
        }
        

    }
    
    // MARK: - API Communication
    
    private func setupBatchSending() {
        // Send activities every 2 minutes for real-time behavior tracking
        batchSendTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { _ in
            self.sendActivityBatch()
        }
    }
    
    private func sendActivityBatch() {
        guard !pendingActivities.isEmpty else { return }
        
        let activitiesToSend = Array(pendingActivities.prefix(maxBatchSize))
        
        // Send asynchronously
        DispatchQueue.global(qos: .background).async {
            self.sendActivitiesToNewAPI(activitiesToSend)
        }
        
        // Clear sent activities
        if pendingActivities.count <= maxBatchSize {
            pendingActivities.removeAll()
        } else {
            pendingActivities.removeFirst(maxBatchSize)
        }
    }
    
    func sendAllPendingActivities() {
        guard !pendingActivities.isEmpty else { return }
        

        
        // Send all remaining activities
        DispatchQueue.global(qos: .background).async {
            self.sendActivitiesToNewAPI(self.pendingActivities)
        }
        
        pendingActivities.removeAll()
    }
    
    private func sendActivitiesToNewAPI(_ activities: [BehaviorActivity]) {
        // Send each activity individually using centralized APIManager
        let currentTime = ISO8601DateFormatter().string(from: Date())
        
        for activity in activities {
            let actionString = "\(activity.action)_\(activity.tab ?? "unknown")"
            
            apiManager.logActivity(email: currentUserEmail, action: actionString, time: currentTime) { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleLogActivityResponse(result: result, activity: activity)
                }
            }
        }
    }
    
    private func handleLogActivityResponse(result: Result<LogActivityResponse, APIError>, activity: BehaviorActivity) {
        switch result {
        case .success(let response):
            // Activity logged successfully
            trackingStatus = "Activity logged - \(activitiesLogged) total: \(response.message)"
        case .failure(let error):
            // Network or API error
            trackingStatus = "Activity logging error - \(error.localizedDescription)"
        }
    }
    
    // MARK: - Test Methods
    
    func sendTestActivity() {
        logBehavior(
            action: "test_activity",
            coordinates: CGPoint(x: 100, y: 200),
            additionalData: [
                "test_type": "manual_test",
                "test_timestamp": Date().timeIntervalSince1970
            ]
        )
        
        // Force send immediately for testing
        sendActivityBatch()
    }
} 