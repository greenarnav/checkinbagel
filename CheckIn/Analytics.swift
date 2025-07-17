//
//  Analytics.swift
//  CheckIn
//
//  Created by Session Recorder on 2025-07-05.
//

import Foundation
import CoreData
import Combine
import SwiftUI

// MARK: - Session Recorder Analytics System

final class Analytics: ObservableObject {
    static let shared = Analytics()
    
    // MARK: - Core Data Stack
    private let container: NSPersistentContainer
    private var dailyUploadCancellable: AnyCancellable?
    private var loginStateCancellable: AnyCancellable?
    private var backgroundTaskCancellable: AnyCancellable?
    
    // MARK: - State Management
    @Published private(set) var isUserLoggedIn = false
    @Published private(set) var pendingEventsCount = 0
    @Published private(set) var totalEventsCount = 0
    @Published private(set) var lastUploadDate: Date?
    
    private var currentScreenName = ""
    private var screenStartTime: Date?
    private var currentTabName = ""
    
    // MARK: - Configuration
    private let batchUploadThreshold = 2000
    private let maxRetainedDays = 30 // Delete events older than 30 days
    private let apiBaseURL = "https://user-login-register-d6yw.onrender.com"
    
    // MARK: - Initialization
    
    private init() {
        container = NSPersistentContainer(name: "AnalyticsModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error)")
            }
            print("📊 Analytics Core Data stack loaded successfully")
        }
        
        // Enable automatic merging of changes
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        updateEventCounts()
        observeLoginState()
        scheduleDailyUpload()
        observeAppLifecycle()
        
        // Log app launch immediately
        logAppLaunch()
        
        print("📊 Session Recorder Analytics initialized - capturing all interactions from launch")
    }
    
    // MARK: - Event Logging Interface
    
    /// Log any analytics event with type and payload
    func log(type: String, payload: [String: Any] = [:]) {
        container.performBackgroundTask { [weak self] context in
            _ = AnalyticsEvent.create(type: type, payload: payload, in: context)
            
            do {
                try context.save()
                
                DispatchQueue.main.async {
                    self?.updateEventCounts()
                }
                
                print("📊 Event logged: \(type)")
            } catch {
                print("📊 Failed to save analytics event: \(error)")
            }
        }
    }
    
    // MARK: - Specific Event Types
    
    func logTabSwitch(from fromTab: String, to toTab: String, tabIndex: Int) {
        let payload = EventPayloadBuilder.tabSwitch(from: fromTab, to: toTab, tabIndex: tabIndex)
        log(type: AnalyticsEventType.tabSwitch, payload: payload)
        
        // Update current tab for context
        currentTabName = toTab
    }
    
    func logButtonTap(buttonName: String, screenName: String? = nil, coordinates: CGPoint? = nil) {
        let screen = screenName ?? currentScreenName
        let payload = EventPayloadBuilder.buttonTap(buttonName: buttonName, screenName: screen, coordinates: coordinates)
        log(type: AnalyticsEventType.buttonTap, payload: payload)
    }
    
    func logSwipeGesture(direction: String, startPoint: CGPoint, endPoint: CGPoint, screenName: String? = nil) {
        let screen = screenName ?? currentScreenName
        let payload = EventPayloadBuilder.swipeGesture(direction: direction, startPoint: startPoint, endPoint: endPoint, screenName: screen)
        log(type: AnalyticsEventType.swipeGesture, payload: payload)
    }
    
    func logLongPress(elementName: String? = nil, coordinates: CGPoint? = nil) {
        var payload: [String: Any] = [
            "screen_name": currentScreenName,
            "tab_name": currentTabName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let elementName = elementName {
            payload["element_name"] = elementName
        }
        
        if let coordinates = coordinates {
            payload["coordinates"] = [
                "x": coordinates.x,
                "y": coordinates.y
            ]
        }
        
        log(type: AnalyticsEventType.longPress, payload: payload)
    }
    
    func logTextInput(fieldName: String, fieldType: String = "textfield", textLength: Int? = nil) {
        var payload: [String: Any] = [
            "field_name": fieldName,
            "field_type": fieldType,
            "screen_name": currentScreenName,
            "tab_name": currentTabName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let textLength = textLength {
            payload["text_length"] = textLength
        }
        
        log(type: AnalyticsEventType.textInput, payload: payload)
    }
    
    func logScreenEnter(screenName: String) {
        // Log exit for previous screen if any
        if !currentScreenName.isEmpty {
            logScreenExit(currentScreenName)
        }
        
        currentScreenName = screenName
        screenStartTime = Date()
        
        let payload = EventPayloadBuilder.screenView(screenName: screenName)
        log(type: AnalyticsEventType.screenView, payload: payload)
    }
    
    func logScreenExit(_ screenName: String) {
        guard currentScreenName == screenName,
              let startTime = screenStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        let payload = EventPayloadBuilder.screenView(screenName: screenName, duration: duration)
        log(type: "screen_exit", payload: payload)
        
        currentScreenName = ""
        screenStartTime = nil
    }
    
    func logUserLogin(username: String, loginMethod: String = "standard") {
        let payload: [String: Any] = [
            "username": username,
            "login_method": loginMethod,
            "timestamp": Date().timeIntervalSince1970
        ]
        log(type: AnalyticsEventType.userLogin, payload: payload)
        
        // Update login state
        isUserLoggedIn = true
        
        // Trigger immediate upload of pending events
        uploadPendingEvents()
    }
    
    func logUserLogout() {
        log(type: AnalyticsEventType.userLogout)
        isUserLoggedIn = false
    }
    
    // MARK: - App Lifecycle Events
    
    private func logAppLaunch() {
        let payload = EventPayloadBuilder.appLifecycle(state: "launch")
        log(type: AnalyticsEventType.appLaunch, payload: payload)
    }
    
    func logAppBackground() {
        let payload = EventPayloadBuilder.appLifecycle(state: "background")
        log(type: AnalyticsEventType.appBackground, payload: payload)
        
        // Check if we should upload due to large number of events
        if pendingEventsCount > batchUploadThreshold && isUserLoggedIn {
            uploadPendingEvents()
        }
    }
    
    func logAppForeground() {
        let payload = EventPayloadBuilder.appLifecycle(state: "foreground")
        log(type: AnalyticsEventType.appForeground, payload: payload)
    }
    
    // MARK: - Login State Observation
    
    private func observeLoginState() {
        // Observe login state from UserDefaults or AuthManager
        loginStateCancellable = NotificationCenter.default
            .publisher(for: .init("UserLoginStateChanged"))
            .sink { [weak self] notification in
                if let isLoggedIn = notification.object as? Bool {
                    self?.isUserLoggedIn = isLoggedIn
                    
                    if isLoggedIn {
                        self?.uploadPendingEvents()
                    }
                }
            }
        
        // Check initial login state
        checkInitialLoginState()
    }
    
    private func checkInitialLoginState() {
        // Check if user is already logged in
        if UserDefaults.standard.string(forKey: "LoggedInUsername") != nil ||
           UserDefaults.standard.string(forKey: "GuestUsername") != nil {
            isUserLoggedIn = true
        }
    }
    
    // MARK: - Scheduled Upload System
    
    private func scheduleDailyUpload() {
        // Schedule upload every 24 hours
        dailyUploadCancellable = Timer.publish(every: 24 * 60 * 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                if self?.isUserLoggedIn == true {
                    self?.uploadPendingEvents()
                }
            }
    }
    
    // MARK: - Upload Logic
    
    func uploadPendingEvents() {
        guard isUserLoggedIn else {
            print("📊 Skipping upload - user not logged in")
            return
        }
        
        container.performBackgroundTask { [weak self] context in
            let unsentEvents = AnalyticsEvent.fetchUnsent(in: context)
            
            guard !unsentEvents.isEmpty else {
                print("📊 No pending events to upload")
                return
            }
            
            print("📊 Starting upload of \(unsentEvents.count) analytics events")
            
            self?.uploadEvents(unsentEvents, context: context)
        }
    }
    
    private func uploadEvents(_ events: [AnalyticsEvent], context: NSManagedObjectContext) {
        // Convert events to upload format
        let eventData = events.compactMap { event -> [String: Any]? in
            var data: [String: Any] = [
                "type": event.type ?? "unknown",
                "timestamp": event.timestamp?.timeIntervalSince1970 ?? 0
            ]
            
            if let payload = event.decodedPayload {
                data["payload"] = payload
            }
            
            return data
        }
        
        let uploadPayload: [String: Any] = [
            "events": eventData,
            "batch_id": UUID().uuidString,
            "upload_timestamp": Date().timeIntervalSince1970,
            "device_info": [
                "model": UIDevice.current.model,
                "system_version": UIDevice.current.systemVersion,
                "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            ]
        ]
        
        // Upload to API
        uploadToAPI(uploadPayload) { [weak self] success in
            if success {
                AnalyticsEvent.markAsSent(events, in: context)
                
                DispatchQueue.main.async {
                    self?.lastUploadDate = Date()
                    self?.updateEventCounts()
                }
                
                print("📊 Successfully uploaded \(events.count) analytics events")
            } else {
                print("📊 Failed to upload analytics events - will retry later")
            }
        }
    }
    
    private func uploadToAPI(_ payload: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(apiBaseURL)/analytics/batch_upload") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("📊 Failed to encode upload payload: \(error)")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("📊 Upload network error: \(error)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let success = (200...299).contains(httpResponse.statusCode)
                print("📊 Upload response: \(httpResponse.statusCode)")
                completion(success)
            } else {
                completion(false)
            }
        }.resume()
    }
    
    // MARK: - App Lifecycle Observation
    
    private func observeAppLifecycle() {
        backgroundTaskCancellable = NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.logAppBackground()
            }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logAppForeground()
        }
    }
    
    // MARK: - Data Management
    
    private func updateEventCounts() {
        container.performBackgroundTask { [weak self] context in
            let pendingCount = AnalyticsEvent.count(sent: false, in: context)
            let totalCount = AnalyticsEvent.count(in: context)
            
            DispatchQueue.main.async {
                self?.pendingEventsCount = pendingCount
                self?.totalEventsCount = totalCount
            }
        }
    }
    
    func cleanupOldEvents() {
        container.performBackgroundTask { [weak self] context in
            AnalyticsEvent.deleteOldSentEvents(olderThan: self?.maxRetainedDays ?? 30, in: context)
            
            DispatchQueue.main.async {
                self?.updateEventCounts()
            }
        }
    }
    
    // MARK: - Debug and Testing
    
    func getEventCounts() -> (pending: Int, total: Int) {
        return (pendingEventsCount, totalEventsCount)
    }
    
    func forceUpload() {
        uploadPendingEvents()
    }
    
    func resetAnalytics() {
        container.performBackgroundTask { context in
            let request: NSFetchRequest<NSFetchRequestResult> = AnalyticsEvent.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            
            do {
                try context.execute(deleteRequest)
                try context.save()
                print("📊 Analytics data reset")
            } catch {
                print("📊 Failed to reset analytics: \(error)")
            }
        }
    }
} 