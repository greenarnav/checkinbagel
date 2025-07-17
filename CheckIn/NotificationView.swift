//
//  NotificationView.swift
//  moodgpt
//
//  Created by Test on 5/29/25.
//

import SwiftUI

struct NotificationView: View {
    @StateObject private var notificationManager = NotificationManager()
    @State private var showingSettings = false
    @State private var isRefreshing = false
    
    @EnvironmentObject var activityTracker: ActivityTrackingManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Status Header
                    StatusHeaderView()
                    
                    // Notifications List
                    if notificationManager.notifications.isEmpty {
                        EmptyStateView()
                    } else {
                        NotificationListView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Notifications")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if notificationManager.unreadCount > 0 {
                            Text("(\(notificationManager.unreadCount))")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Refresh", action: refreshNotifications)
                        Button("Mark All Read", action: markAllAsRead)
                        Button("Clear All", action: clearAll)
                        Divider()
                        Button("Settings") { showingSettings = true }
                        Button("Test Notification", action: sendTestNotification)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            notificationManager.setActivityTracker(activityTracker)
            activityTracker.enterScreen("notifications")
            notificationManager.fetchNotifications()
        }
        .onDisappear {
            activityTracker.exitScreen("notifications")
        }
        .sheet(isPresented: $showingSettings) {
            NotificationSettingsView()
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func StatusHeaderView() -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Background Refresh")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(notificationManager.backgroundRefreshStatus)
                        .font(.caption2)
                        .foregroundColor(backgroundRefreshColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Last Fetch")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(lastFetchText)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            HStack {
                Text("Status: \(notificationManager.fetchStatus)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    @ViewBuilder
    private func EmptyStateView() -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bell.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Notifications")
                .font(.title2)
                .foregroundColor(.white)
            
            Text("You're all caught up!")
                .font(.body)
                .foregroundColor(.gray)
            
            Button("Test Fetch") {
                notificationManager.fetchNotifications()
                activityTracker.trackButtonClick("test_fetch_notifications")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func NotificationListView() -> some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(notificationManager.notifications) { notification in
                    NotificationRowView(
                        notification: notification,
                        onMarkRead: { notificationManager.markAsRead(notification) },
                        onDelete: { notificationManager.clearNotification(notification) }
                    )
                    .onTapGesture {
                        activityTracker.trackButtonClick("notification_\(notification.id)")
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func refreshNotifications() {
        isRefreshing = true
        activityTracker.trackButtonClick("refresh_notifications")
        
        notificationManager.refreshNotifications()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isRefreshing = false
        }
    }
    
    private func markAllAsRead() {
        activityTracker.trackButtonClick("mark_all_read")
        notificationManager.markAllAsRead()
    }
    
    private func clearAll() {
        activityTracker.trackButtonClick("clear_all_notifications")
        notificationManager.clearAllNotifications()
    }
    
    private func sendTestNotification() {
        activityTracker.trackButtonClick("send_test_notification")
        notificationManager.sendTestBackgroundNotification()
    }
    
    // MARK: - Computed Properties
    
    private var backgroundRefreshColor: Color {
        switch notificationManager.backgroundRefreshStatus {
        case "Available": return .green
        case "Denied by user": return .red
        case "Restricted by system": return .orange
        default: return .gray
        }
    }
    
    private var lastFetchText: String {
        if let lastFetch = notificationManager.lastFetchTime {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return formatter.localizedString(for: lastFetch, relativeTo: Date())
        } else {
            return "Never"
        }
    }
}

// MARK: - Notification Row View

struct NotificationRowView: View {
    let notification: AppNotification
    let onMarkRead: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Read/Unread indicator
            Circle()
                .fill(notification.isRead ? Color.clear : Color.blue)
                .frame(width: 8, height: 8)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("from \(notification.username)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(notification.timeAgo)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(notification.notification)
                    .font(.body)
                    .foregroundColor(.white)
                    .fontWeight(notification.isRead ? .regular : .semibold)
                    .lineLimit(nil)
            }
        }
        .padding()
        .background(notification.isRead ? Color.black : Color.gray.opacity(0.1))
        .contextMenu {
            if !notification.isRead {
                Button("Mark as Read") {
                    onMarkRead()
                }
            }
            
            Button("Delete") {
                onDelete()
            }
        }
    }
}

// MARK: - Settings View

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some View {
        NavigationView {
            List {
                Section("Background Refresh") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Status: \(notificationManager.backgroundRefreshStatus)")
                            .font(.body)
                        
                        Text("Background refresh allows the app to fetch new notifications when not active.")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if notificationManager.backgroundRefreshStatus != "Available" {
                            Button("Open Settings") {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                Section("Actions") {
                    Button("Check Background Status") {
                        notificationManager.checkAndLogBackgroundStatus()
                    }
                    
                    Button("Schedule Background Fetch") {
                        notificationManager.scheduleBackgroundFetch()
                    }
                    
                    Button("Request Notification Permission") {
                        notificationManager.requestNotificationPermission()
                    }
                }
                
                Section("Test") {
                    Button("Send Test Notification") {
                        notificationManager.sendTestBackgroundNotification()
                    }
                    
                    Button("Fetch Notifications") {
                        notificationManager.fetchNotifications()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            notificationManager.checkBackgroundRefreshStatus()
        }
    }
}

#Preview {
    NotificationView()
        .preferredColorScheme(.dark)
        .environmentObject(ActivityTrackingManager())
} 