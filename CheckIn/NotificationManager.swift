//
//  NotificationManager.swift
//  moodgpt
//
//  Created by Test on 6/1/25.
//

import Foundation
import SwiftUI
import UserNotifications
import UIKit
import BackgroundTasks

// MARK: - Notification Data Models
struct AppNotification: Codable, Identifiable {
    let id: Int
    let notification: String
    let seen: Int
    let timestamp: String
    let username: String
    
    var isRead: Bool {
        return seen == 1
    }
    
    var formattedDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, dd MMM yyyy HH:mm:ss z"
        return formatter.date(from: timestamp)
    }
    
    var timeAgo: String {
        guard let date = formattedDate else { return "Unknown" }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    private let baseAPIURL = "https://notification-inky.vercel.app/fetch"
    @Published var currentUsername: String = "" // Will be set from AuthManager
    private let backgroundTaskIdentifier = "com.checkin.notification-fetch"
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var lastFetchTime: Date?
    @Published var fetchStatus = "Not fetched"
    @Published var hasNewNotifications = false
    @Published var backgroundRefreshStatus = "Unknown"
    
    private var fetchTimer: Timer?
    private var activityTracker: ActivityTrackingManager?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    // Computed property for API URL with actual username
    private var apiURL: String {
        let username = currentUsername.isEmpty ? "guest" : currentUsername
        return "\(baseAPIURL)/\(username)"
    }
    
    init() {
        setupNotificationPermissions()
        setupBackgroundRefresh()
        setupPeriodicFetch()
        setupBackgroundObservers()
        print("NotificationManager initialized with background support")
    }
    
    // Method to set the actual username from AuthManager
    func setUsername(_ username: String) {
        currentUsername = username
        print("NotificationManager username updated to: \(username)")
        
        // Refresh notifications with new username
        fetchNotifications()
    }
    
    func setActivityTracker(_ tracker: ActivityTrackingManager) {
        self.activityTracker = tracker
    }
    
    // MARK: - Background App Refresh Setup
    private func setupBackgroundRefresh() {
        // Register background task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundNotificationFetch(task: task as! BGAppRefreshTask)
        }
        
        // Check background refresh status
        checkBackgroundRefreshStatus()
    }
    
    func checkBackgroundRefreshStatus() {
        switch UIApplication.shared.backgroundRefreshStatus {
        case .available:
            backgroundRefreshStatus = "Available"
        case .denied:
            backgroundRefreshStatus = "Denied by user"
        case .restricted:
            backgroundRefreshStatus = "Restricted by system"
        @unknown default:
            backgroundRefreshStatus = "Unknown"
        }
        
        activityTracker?.logBehavior(
            action: "background_refresh_status_checked",
            additionalData: [
                "status": backgroundRefreshStatus,
                "last_check": Date().timeIntervalSince1970
            ]
        )
    }
    
    private func scheduleBackgroundNotificationFetch() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background notification fetch scheduled")
            activityTracker?.logBehavior(
                action: "background_fetch_scheduled",
                additionalData: [
                    "next_fetch": request.earliestBeginDate?.timeIntervalSince1970 ?? 0
                ]
            )
        } catch {
            print("Failed to schedule background fetch: \(error)")
            activityTracker?.logBehavior(
                action: "background_fetch_schedule_failed",
                additionalData: [
                    "error": error.localizedDescription
                ]
            )
        }
    }
    
    private func handleBackgroundNotificationFetch(task: BGAppRefreshTask) {
        print("Background notification fetch triggered")
        
        // Schedule the next background fetch
        scheduleBackgroundNotificationFetch()
        
        // Set expiration handler
        task.expirationHandler = {
            print("⏰ Background fetch expired")
            self.activityTracker?.logBehavior(action: "background_fetch_expired", additionalData: [:])
            task.setTaskCompleted(success: false)
        }
        
        // Perform background fetch
        fetchNotificationsInBackground { success in
            print("Background fetch completed: \(success)")
            self.activityTracker?.logBehavior(
                action: "background_fetch_completed",
                additionalData: [
                    "success": success,
                    "notifications_count": self.notifications.count
                ]
            )
            task.setTaskCompleted(success: success)
        }
    }
    
    // MARK: - Background Observers
    private func setupBackgroundObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleAppDidEnterBackground()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleAppWillEnterForeground()
        }
    }
    
    private func handleAppDidEnterBackground() {
        print("App entered background - starting background task")
        
        // Start background task for final fetch
        beginBackgroundTask()
        
        // Schedule background refresh
        scheduleBackgroundNotificationFetch()
        
        // Do a final fetch before app goes to sleep
        fetchNotificationsInBackground { success in
            self.endBackgroundTask()
        }
        
        // Schedule a local notification for testing
        scheduleTestLocalNotification()
    }
    
    private func handleAppWillEnterForeground() {
        print("App entering foreground - resuming normal operation")
        
        // Cancel any pending background tasks
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
        
        // Resume normal fetching
        setupPeriodicFetch()
        
        // Fetch immediately when returning to foreground
        fetchNotifications()
    }
    
    private func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "NotificationFetch") {
            // Called when the task is about to expire
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    // MARK: - Notification Permissions
    private func setupNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permissions granted")
                    self.activityTracker?.logBehavior(action: "notification_permission_granted", additionalData: [:])
                } else {
                    print("Notification permissions denied")
                    self.activityTracker?.logBehavior(
                        action: "notification_permission_denied",
                        additionalData: [
                            "error": error?.localizedDescription ?? "Unknown error"
                        ]
                    )
                }
            }
        }
    }
    
    // MARK: - Periodic Fetching
    private func setupPeriodicFetch() {
        // Cancel existing timer
        fetchTimer?.invalidate()
        
        // Fetch notifications every 30 seconds when app is active
        fetchTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.fetchNotifications()
        }
        
        // Initial fetch
        fetchNotifications()
    }
    
    // MARK: - API Integration
    func fetchNotifications() {
        fetchNotificationsInBackground { _ in }
    }
    
    private func fetchNotificationsInBackground(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: apiURL) else {
            print("Invalid notification API URL")
            completion(false)
            return
        }
        
        isLoading = true
        fetchStatus = "Fetching..."
        
        activityTracker?.logBehavior(
            action: "notification_fetch_started",
            additionalData: [
                "api_url": apiURL,
                "username": currentUsername,
                "last_fetch": lastFetchTime?.timeIntervalSince1970 ?? 0,
                "is_background": UIApplication.shared.applicationState != .active
            ]
        )
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.lastFetchTime = Date()
                
                if let error = error {
                    print("Notification fetch error: \(error.localizedDescription)")
                    self?.fetchStatus = "Error: \(error.localizedDescription)"
                    self?.activityTracker?.logBehavior(
                        action: "notification_fetch_error",
                        additionalData: [
                            "error": error.localizedDescription
                        ]
                    )
                    completion(false)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.fetchStatus = "Invalid response"
                    completion(false)
                    return
                }
                
                print("📥 Notification API Response: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    self?.fetchStatus = "API Error: \(httpResponse.statusCode)"
                    self?.activityTracker?.logBehavior(
                        action: "notification_fetch_api_error",
                        additionalData: [
                            "status_code": httpResponse.statusCode
                        ]
                    )
                    completion(false)
                    return
                }
                
                guard let data = data else {
                    self?.fetchStatus = "No data received"
                    completion(false)
                    return
                }
                
                self?.parseNotifications(data)
                completion(true)
            }
        }.resume()
    }
    
    private func parseNotifications(_ data: Data) {
        do {
            let fetchedNotifications = try JSONDecoder().decode([AppNotification].self, from: data)
            
            let previousUnreadCount = unreadCount
            let newNotifications = fetchedNotifications.filter { notification in
                !self.notifications.contains { $0.id == notification.id }
            }
            
            // Update notifications list
            self.notifications = fetchedNotifications.sorted { $0.id > $1.id } // Latest first
            self.unreadCount = fetchedNotifications.filter { !$0.isRead }.count
            self.fetchStatus = "\(fetchedNotifications.count) notifications"
            
            // Check for new notifications
            if !newNotifications.isEmpty {
                self.hasNewNotifications = true
                self.showLocalNotifications(for: newNotifications)
            }
            
            // Log activity
            activityTracker?.logBehavior(
                action: "notification_fetch_success",
                additionalData: [
                    "total_notifications": fetchedNotifications.count,
                    "unread_count": unreadCount,
                    "new_notifications": newNotifications.count,
                    "previous_unread": previousUnreadCount,
                    "app_state": UIApplication.shared.applicationState.rawValue
                ]
            )
            
            print("Fetched \(fetchedNotifications.count) notifications, \(unreadCount) unread, \(newNotifications.count) new")
            
        } catch {
            print("Failed to parse notifications: \(error)")
            fetchStatus = "Parse error: \(error.localizedDescription)"
            activityTracker?.logBehavior(
                action: "notification_parse_error",
                additionalData: [
                    "error": error.localizedDescription,
                    "raw_data_length": data.count
                ]
            )
        }
    }
    
    // MARK: - Local Notifications
    private func showLocalNotifications(for notifications: [AppNotification]) {
        for notification in notifications.prefix(3) { // Limit to 3 to avoid spam
            let content = UNMutableNotificationContent()
            content.title = "CheckIn"
            content.body = notification.notification
            content.sound = .default
            content.badge = NSNumber(value: unreadCount)
            content.userInfo = ["notification_id": notification.id]
            
            let request = UNNotificationRequest(
                identifier: "notification_\(notification.id)",
                content: content,
                trigger: nil // Show immediately
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to show local notification: \(error)")
                } else {
                    print("Local notification shown for: \(notification.notification)")
                }
            }
        }
    }
    
    private func scheduleTestLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "CheckIn Background Test"
        content.body = "Background notification fetch is working!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false) // 1 minute
        
        let request = UNNotificationRequest(
            identifier: "background_test",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule test notification: \(error)")
            } else {
                print("Test notification scheduled for 1 minute")
            }
        }
    }
    
    // MARK: - Notification Actions
    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            // Note: In a real app, you'd call an API to mark as read
            // For now, just update locally
            print("📖 Marked notification \(notification.id) as read")
            
            activityTracker?.logBehavior(
                action: "notification_marked_read",
                additionalData: [
                    "notification_id": notification.id,
                    "notification_text": notification.notification,
                    "username": notification.username,
                    "time_to_read": Date().timeIntervalSince(notification.formattedDate ?? Date())
                ]
            )
        }
    }
    
    func markAllAsRead() {
        let unreadNotifications = notifications.filter { !$0.isRead }
        
        for notification in unreadNotifications {
            markAsRead(notification)
        }
        
        unreadCount = 0
        
        activityTracker?.logBehavior(
            action: "notification_mark_all_read",
            additionalData: [
                "total_marked": unreadNotifications.count
            ]
        )
    }
    
    func clearNotification(_ notification: AppNotification) {
        notifications.removeAll { $0.id == notification.id }
        if !notification.isRead {
            unreadCount = max(0, unreadCount - 1)
        }
        
        activityTracker?.logBehavior(
            action: "notification_cleared",
            additionalData: [
                "notification_id": notification.id,
                "notification_text": notification.notification,
                "was_read": notification.isRead
            ]
        )
    }
    
    func clearAllNotifications() {
        let clearedCount = notifications.count
        notifications.removeAll()
        unreadCount = 0
        
        activityTracker?.logBehavior(
            action: "notification_clear_all",
            additionalData: [
                "total_cleared": clearedCount
            ]
        )
    }
    
    // MARK: - Manual Actions
    func refreshNotifications() {
        activityTracker?.logBehavior(action: "notification_manual_refresh", additionalData: [:])
        fetchNotifications()
    }
    
    func acknowledgeNewNotifications() {
        hasNewNotifications = false
        activityTracker?.logBehavior(action: "notification_new_acknowledged", additionalData: [:])
    }
    
    func checkAndLogBackgroundStatus() {
        checkBackgroundRefreshStatus()
        
        activityTracker?.logBehavior(
            action: "background_refresh_status_checked",
            additionalData: [
                "status": backgroundRefreshStatus,
                "last_check": Date().timeIntervalSince1970
            ]
        )
    }
    
    func scheduleBackgroundFetch() {
        scheduleBackgroundNotificationFetch()
    }
    
    func requestNotificationPermission() {
        setupNotificationPermissions()
    }
    
    func sendTestBackgroundNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Background Notification"
        content.body = "This is a test notification sent manually from settings."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "manual_test_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send test notification: \(error)")
            } else {
                print("Test notification sent successfully")
            }
        }
        
        activityTracker?.logBehavior(action: "manual_test_notification_sent", additionalData: [:])
    }
    
    deinit {
        fetchTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
} 