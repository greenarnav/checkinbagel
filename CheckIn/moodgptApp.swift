//
//  moodgptApp.swift
//  moodgpt
//
//  Created by Test on 5/26/25.
//

import SwiftUI
import SpotifyiOS

@main
struct moodgptApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            AppCoordinatorWithAuth()
        }
    }
}

// MARK: - App Coordinator with Authentication
struct AppCoordinatorWithAuth: View {
    @State private var isLoading = false // Changed to false - no loading screen
    @State private var hasCompletedInitialLoad = false
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var authManager = AuthManager()
    @StateObject private var pinnedContactsManager = PinnedContactsManager()
    @StateObject private var emotionSnapshotService = EmotionSnapshotService()
    
    var body: some View {
        ZStack {
            // Ensure no white background flash
            Color.black
                .ignoresSafeArea()
                .zIndex(0)
            
            // Show main content immediately - no loading screen
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(pinnedContactsManager)
                    .environmentObject(authManager)
                    .environmentObject(themeManager)
                    .environmentObject(emotionSnapshotService)
                    .transition(.opacity)
            } else {
                AuthenticationView(authManager: authManager)
                    .environmentObject(authManager)
                    .environmentObject(themeManager)
                    .environmentObject(emotionSnapshotService)
                    .transition(.opacity)
            }
        }
        .onAppear {
            if !hasCompletedInitialLoad {
                // Request Spotify permissions during app launch
                SpotifyAuthManager.shared.configureSpotify { result in
                    switch result {
                    case .success(let isAuthenticated):
                        print("Spotify authentication status: \(isAuthenticated)")
                    case .failure(let error):
                        print("Error authenticating with Spotify: \(error)")
                    }
                }
                
                // Initialize managers in background
                initializeManagers()
                hasCompletedInitialLoad = true
            }
        }
    }
    
    private func initializeManagers() {
        // Pre-load all critical components in background
        Task {
            // Initialize all managers asynchronously
            let _ = ContactsManager()
            let _ = EmotionAnalysisManager.shared
            let _ = CelebrityDataManager.shared // This will load cached data immediately
        }
    }
}
