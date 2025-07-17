//
//  ContentView.swift
//  moodgpt
//
//  Created by Test on 5/26/25.
//

import SwiftUI
import MapKit
import WebKit
import CoreLocation

// MARK: - Main Content View
struct ContentView: View {
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var chatIsShowing = false
    @State private var showContactsTab = false  // Controls contacts tab visibility

    
    // Navigation path states for each tab that needs navigation
    @State private var homeNavigationPath = NavigationPath()
    @State private var contactsNavigationPath = NavigationPath()
    @State private var publicNavigationPath = NavigationPath()
    @State private var calendarNavigationPath = NavigationPath()
    
    @StateObject private var locationTracker = LocationTrackingManager()
    @StateObject private var healthDataManager = HealthDataManager()
    @StateObject private var activityTracker = ActivityTrackingManager()
    @StateObject private var notificationManager = NotificationManager()
    @EnvironmentObject var authManager: AuthManager
    
    // Session Recorder Integration
    private let analytics = Analytics.shared
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Home Tab with its own NavigationStack
                NavigationStack(path: $homeNavigationPath) {
                    HomeView()
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar(.hidden, for: .navigationBar)
                }
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
                
                // Maps Tab (no navigation needed)
                MapView()
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "map.fill" : "map")
                        Text("Maps")
                    }
                    .tag(1)
                
                // Contacts Tab with its own NavigationStack
                NavigationStack(path: $contactsNavigationPath) {
                    ContactsView()
                        .environment(\.chatIsShowing, $chatIsShowing)
                        .navigationBarTitleDisplayMode(.inline)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .toolbar(.hidden, for: .navigationBar)
                }
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "person.2.fill" : "person.2")
                    Text("Contacts")
                }
                .tag(2)
                
                // Public Tab with its own NavigationStack
                NavigationStack(path: $publicNavigationPath) {
                    CelebritiesView()
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar(.hidden, for: .navigationBar)
                }
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "star.fill" : "star")
                    Text("Public")
                }
                .tag(3)
                
                // Calendar Tab with its own NavigationStack
                NavigationStack(path: $calendarNavigationPath) {
                    CalendarTabView()
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar(.hidden, for: .navigationBar)
                }
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.crop.circle.fill" : "person.crop.circle")
                    Text("Profile")
                }
                .tag(4)
            }
            .accentColor(.blue)
            .environmentObject(authManager)
            .environmentObject(locationTracker)
            .environmentObject(healthDataManager)
            .environmentObject(activityTracker)
            .environmentObject(notificationManager)
            // TEMPORARILY DISABLED: Session Recorder Integration to test tab functionality
            // .trackTabView(selectedTab: $selectedTab, tabNames: ["Home", "Maps", "Contacts", "Public", "Profile"])
            // .recordSession(screenName: "MainTabView")
            .onChange(of: selectedTab) { oldValue, newValue in
                print("✅ TAB SELECTION CHANGED: \(oldValue) → \(newValue)")
                handleTabChange(from: oldValue, to: newValue)
                // Clear all navigation paths when switching tabs to prevent cross-contamination
                clearNavigationPathsExceptCurrent(newValue)
            }
            .onChange(of: authManager.currentUsername) { oldValue, newValue in
                updateDataManagerUsers()
                
                // Track authentication state changes
                if !newValue.isEmpty && oldValue.isEmpty {
                    // User logged in
                    AuthenticationTracker.trackLogin(username: newValue)
                } else if newValue.isEmpty && !oldValue.isEmpty {
                    // User logged out
                    AuthenticationTracker.trackLogout()
                }
            }
            .onAppear {
                print("🔵 ContentView appeared with selectedTab: \(selectedTab)")
                updateDataManagerUsers()
                startServicesInBackground()
                
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                
                // Force tab bar to be interactive
                DispatchQueue.main.async {
                    UITabBar.appearance().isUserInteractionEnabled = true
                    print("🔵 Tab bar interaction enabled")
                }
            }
            .onDisappear {
                stopAllServices()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                handleAppWillResignActive()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                handleAppDidBecomeActive()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                handleAppWillTerminate()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                handleAppDidEnterBackground()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                handleAppWillEnterForeground()
            }

            // Chat overlay (only when showing) - FIXED to not block tab bar
            if chatIsShowing {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Main overlay area (excluding tab bar)
                        Color.black.opacity(0.3)
                            .frame(height: geometry.size.height - 100) // Leave space for tab bar
                            .onTapGesture {
                                print("🔥 Chat overlay tapped - dismissing")
                                chatIsShowing = false
                            }
                        
                        // Clear area for tab bar
                        Color.clear
                            .frame(height: 100)
                            .allowsHitTesting(false) // Allow touches to pass through to tab bar
                    }
                }
                .ignoresSafeArea(.container, edges: .top) // Only ignore top safe area
            }
        }
    }
    
    // MARK: - Data Manager Integration
    
    private func updateDataManagerUsers() {
        // Update username for health data API calls
        healthDataManager.setUsername(authManager.currentUsername)
        healthDataManager.setUserName(authManager.currentName)
        
        // Update username for location tracking API calls
        locationTracker.setUsername(authManager.currentUsername)
        
        // Update username for notification API calls
        notificationManager.setUsername(authManager.currentUsername)
        
        // Update user email for behavior tracking API calls  
        let userEmail = authManager.currentUsername.contains("@") ? authManager.currentUsername : "\(authManager.currentUsername)@example.com"
        activityTracker.setUserEmail(userEmail)
        
        // ENHANCED: Trigger immediate health data refresh when username changes
        if healthDataManager.isAuthorized && !authManager.currentUsername.isEmpty {
            print("🍎 Username updated - refreshing Apple Health data for new user")
            DispatchQueue.global(qos: .background).async {
                self.healthDataManager.fetchEssentialHealthData()
            }
        }
    }
    
    // MARK: - Manual Health Data Refresh
    func refreshHealthDataManually() {
        if healthDataManager.isAuthorized {
            print("🍎 Manual Apple Health data refresh triggered")
            DispatchQueue.global(qos: .background).async {
                self.healthDataManager.fetchEssentialHealthData()
            }
        } else {
            print("⚠️ Apple Health not authorized - requesting permissions")
            healthDataManager.requestPermissionsAndFetchData()
        }
    }
    
    // MARK: - Service Management
    private func startServicesInBackground() {
        activityTracker.startSession()
        previousTab = selectedTab
        
        // Load saved emotion data on app startup
        EmotionAnalysisManager.shared.loadSavedUserEmotionData()
        
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                self.locationTracker.startTracking()
            }
            
            // ENHANCED: More aggressive health data fetching on startup
            DispatchQueue.main.async {
                // First, request permissions and fetch data immediately
                self.healthDataManager.requestPermissionsAndFetchData()
                
                // Also trigger an immediate refresh after a short delay to ensure fresh data
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self.healthDataManager.isAuthorized {
                        print("🍎 Performing immediate Apple Health data refresh on startup")
                        DispatchQueue.global(qos: .background).async {
                            self.healthDataManager.fetchEssentialHealthData()
                        }
                    }
                }
            }
            
            // Set up periodic health data refresh (every 5 minutes for fresh data)
            DispatchQueue.main.async {
                Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
                    if self.healthDataManager.isAuthorized {
                        print("🔄 Periodic Apple Health data refresh")
                        DispatchQueue.global(qos: .background).async {
                            self.healthDataManager.fetchEssentialHealthData()
                        }
                    }
                }
            }
            
            // ENHANCED: Additional refresh when app becomes active again
            DispatchQueue.main.async {
                Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                    if self.healthDataManager.isAuthorized && UIApplication.shared.applicationState == .active {
                        print("🍎 Active state Apple Health refresh")
                        DispatchQueue.global(qos: .background).async {
                            self.healthDataManager.fetchEssentialHealthData()
                        }
                    }
                }
            }
        }
        
        handleTabChange(from: -1, to: selectedTab)
    }
    
    private func stopAllServices() {
        locationTracker.stopTracking()
        healthDataManager.stopAutoHealthLogging()
        activityTracker.endSession()
    }
    
    // MARK: - Tab Change Tracking
    private func handleTabChange(from oldTab: Int, to newTab: Int) {
        let tabNames = ["Home", "Maps", "Contacts", "Public", "Profile"]
        
        // Enhanced Debug: Print detailed tab change information
        print("🚀 TAB CHANGE HANDLER CALLED")
        print("   From: \(oldTab) (\(oldTab >= 0 && oldTab < tabNames.count ? tabNames[oldTab] : "Invalid"))")
        print("   To: \(newTab) (\(newTab >= 0 && newTab < tabNames.count ? tabNames[newTab] : "Invalid"))")
        print("   Current selectedTab state: \(selectedTab)")
        
        if oldTab == newTab {
            print("   ↩️ Same tab tapped - popping to root")
            popToRootForCurrentTab()
            return
        }
        
        previousTab = newTab
        
        if newTab >= 0 && newTab < tabNames.count {
            print("   ✅ Valid tab - entering: \(tabNames[newTab])")
            activityTracker.enterTab(tabNames[newTab], tabIndex: newTab)
        } else {
            print("   ❌ Invalid tab index: \(newTab)")
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        print("   📳 Haptic feedback triggered")
    }
    
    private func popToRootForCurrentTab() {
        print("Popping to root for tab: \(selectedTab)")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            switch selectedTab {
            case 0: homeNavigationPath = NavigationPath()
            case 2: contactsNavigationPath = NavigationPath()
            case 3: publicNavigationPath = NavigationPath()
            case 4: calendarNavigationPath = NavigationPath()
            default: break
            }
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Navigation Path Management (Fix for contacts tab bug)
    private func clearNavigationPathsExceptCurrent(_ currentTab: Int) {
        // Clear all navigation paths except the current tab to prevent view contamination
        withAnimation(.easeInOut(duration: 0.2)) {
            if currentTab != 0 { homeNavigationPath = NavigationPath() }
            if currentTab != 2 { contactsNavigationPath = NavigationPath() }
            if currentTab != 3 { publicNavigationPath = NavigationPath() }
            if currentTab != 4 { calendarNavigationPath = NavigationPath() }
        }
    }
    
    // MARK: - App Lifecycle Tracking
    private func handleAppWillResignActive() {
        activityTracker.logBehavior(
            action: "app_will_resign_active",
            additionalData: [
                "current_tab": selectedTab,
                "chat_is_showing": chatIsShowing,
                "tab_name": getTabName(selectedTab)
            ]
        )
    }
    
    private func handleAppDidBecomeActive() {
        // Refresh tab bar appearance to ensure it stays visible
        
        activityTracker.logBehavior(
            action: "app_did_become_active", 
            additionalData: [
                "current_tab": selectedTab,
                "chat_is_showing": chatIsShowing,
                "tab_name": getTabName(selectedTab)
            ]
        )
        
        // ENHANCED: Refresh Apple Health data when app becomes active
        if healthDataManager.isAuthorized {
            print("🍎 App became active - refreshing Apple Health data")
            DispatchQueue.global(qos: .background).async {
                self.healthDataManager.fetchEssentialHealthData()
            }
        }
    }
    
    private func handleAppWillTerminate() {
        activityTracker.logBehavior(
            action: "app_will_terminate",
            additionalData: [
                "final_tab": selectedTab,
                "chat_is_showing": chatIsShowing,
                "tab_name": getTabName(selectedTab)
            ]
        )
        
        activityTracker.sendAllPendingActivities()
    }
    
    private func handleAppDidEnterBackground() {
        activityTracker.appDidEnterBackground()
        analytics.logAppBackground()
    }
    
    private func handleAppWillEnterForeground() {
        activityTracker.appWillEnterForeground()
        analytics.logAppForeground()
    }
    
    private func getTabName(_ index: Int) -> String {
        let tabNames = ["Home", "Maps", "Contacts", "Public", "Profile"]
        return index >= 0 && index < tabNames.count ? tabNames[index] : "Unknown"
    }
}

#Preview {
    ContentView()
        .environmentObject(PinnedContactsManager())
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
        .preferredColorScheme(.dark)
}
