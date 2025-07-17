//
//  SettingsView.swift
//  moodgpt
//
//  Created by Test on 5/27/25.
//

import SwiftUI
import SpotifyiOS

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var activityTracker: ActivityTrackingManager
    @State private var syncHealthData = false
    @State private var useCustomAPI = false
    @State private var enableNotifications = true
    @State private var friendMoodUpdates = true
    @State private var cityMoodChanges = true
    @State private var moodReminders = true
    @State private var shareLocation = true
    @State private var showOnMap = true
    @State private var privateAccount = false
    @State private var autoShareMood = false
    @State private var showingLogoutAlert = false
    @State private var showUserProfile = false
    @State private var showPhoneNumberInput = false

    

    
    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()
            
            // Emotion-based gradient overlay for multi-color theme
            if let gradient = themeManager.backgroundGradient {
                gradient
                    .ignoresSafeArea()
            }
            
            // Semi-transparent overlay for better readability in multi-color mode
            if themeManager.currentTheme == .multiColor {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
            }
            
            ScrollView {
                VStack(spacing: 0) {

                    
                    // Your Profile section - editable name and username at top
                    SettingsSectionHeader(title: "Your Profile")
                    
                    VStack(spacing: 15) {
                        // Profile picture and basic info
                        HStack {
                            Circle()
                                .fill(authManager.isGuestMode ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(authManager.isGuestMode ? "👤" : String(authManager.currentName.isEmpty ? authManager.currentUsername.prefix(1).uppercased() : authManager.currentName.prefix(1).uppercased()))
                                        .font(authManager.isGuestMode ? .title : .title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeManager.primaryTextColor)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(authManager.currentName.isEmpty ? "User" : authManager.currentName)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                Text(authManager.isGuestMode ? "Guest Account" : "@\(authManager.currentUsername)")
                                    .font(.bodySmall)
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showUserProfile = true
                            }) {
                                Text("Edit")
                                    .font(.buttonFont)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.cardBackgroundColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeManager.borderColor, lineWidth: 0.5)
                                )
                        )
                    }
                    .sheet(isPresented: $showUserProfile) {
                        ProfileEditView(authManager: authManager)
                            .environmentObject(themeManager)
                            .environmentObject(healthDataManager)
                    }
                    
                    // Your Experience section - most important user-facing features
                    SettingsSectionHeader(title: "Your Experience")
                    
                    // Theme Selection
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 15) {
                            Image(systemName: "paintbrush.fill")
                                .foregroundColor(themeManager.primaryTextColor)
                                .font(.bodyMedium)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("App Theme")
                                    .font(.bodyMedium)
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                Text("Choose your visual experience")
                                    .font(.captionLarge)
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        
                        // Modern Theme Picker with Preview
                        VStack(spacing: 0) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Button(action: {
                                    let oldTheme = themeManager.currentTheme.rawValue
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        themeManager.currentTheme = theme
                                    }
                                    // Track theme change
                                    activityTracker.trackThemeChange(oldTheme, theme.rawValue)
                                    
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                }) {
                                    HStack(spacing: 16) {
                                        // Theme preview circle
                                        ZStack {
                                            Circle()
                                                .fill(themePreviewBackground(for: theme))
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    Circle()
                                                        .stroke(themePreviewBorder(for: theme), lineWidth: 2)
                                                )
                                            
                                            Image(systemName: themeIconName(for: theme))
                                                .foregroundColor(themePreviewIconColor(for: theme))
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .scaleEffect(themeManager.currentTheme == theme ? 1.1 : 1.0)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(theme.rawValue)
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundColor(themeManager.currentTheme == theme ? themeSelectionColor(for: theme) : themeManager.primaryTextColor)
                                            
                                            Text(themeDescription(for: theme))
                                                .font(.system(size: 14))
                                                .foregroundColor(themeManager.secondaryTextColor)
                                        }
                                        
                                        Spacer()
                                        
                                        // Selection indicator
                                        if themeManager.currentTheme == theme {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(themeSelectionColor(for: theme))
                                                .font(.system(size: 20))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(themeManager.currentTheme == theme ? 
                                                  themeSelectionColor(for: theme).opacity(0.12) : 
                                                  Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(themeManager.currentTheme == theme ? 
                                                           themeSelectionColor(for: theme).opacity(0.3) : 
                                                           Color.clear, lineWidth: 1.5)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeManager.elevatedCardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(themeManager.borderColor, lineWidth: 0.5)
                            )
                            .shadow(color: themeManager.shadowColor, radius: 3, x: 0, y: 2)
                    )
                    
                    SettingsToggleRow(
                        icon: "bell.fill",
                        title: "Stay Connected",
                        subtitle: "Get notified when friends share their mood",
                        isOn: $enableNotifications,
                        onToggle: { newValue in
                            activityTracker.trackSettingsChange("notifications", oldValue: !newValue, newValue: newValue)
                        }
                    )
                    
                    SettingsToggleRow(
                        icon: "face.smiling",
                        title: "Floating Emojis",
                        subtitle: "Show animated emojis in the background",
                        isOn: $themeManager.showEmojisInBackground,
                        onToggle: { newValue in
                            activityTracker.trackSettingsChange("floating_emojis", oldValue: !newValue, newValue: newValue)
                        }
                    )
                    
                    SettingsToggleRow(
                        icon: "person.2.fill",
                        title: "Friend Updates",
                        subtitle: "See when your contacts check in",
                        isOn: $friendMoodUpdates,
                        onToggle: { newValue in
                            activityTracker.trackSettingsChange("friend_updates", oldValue: !newValue, newValue: newValue)
                        }
                    )
                    
                    SettingsToggleRow(
                        icon: "alarm.fill",
                        title: "Daily Check-in Reminders",
                        subtitle: "Gentle nudges to share how you're feeling",
                        isOn: $moodReminders,
                        onToggle: { newValue in
                            activityTracker.trackSettingsChange("mood_reminders", oldValue: !newValue, newValue: newValue)
                        }
                    )
                    
                    SettingsToggleRow(
                        icon: "building.2.fill",
                        title: "Area Mood Insights",
                        subtitle: "Discover how your neighborhood is feeling",
                        isOn: $cityMoodChanges,
                        onToggle: { newValue in
                            activityTracker.trackSettingsChange("area_mood_insights", oldValue: !newValue, newValue: newValue)
                        }
                    )
                    
                    // Your Privacy section
                    SettingsSectionHeader(title: "Your Privacy")
                    
                    SettingsToggleRow(
                        icon: "eye.fill",
                        title: "Share My Mood",
                        subtitle: "Let friends see how you're feeling",
                        isOn: $showOnMap,
                        onToggle: { newValue in
                            activityTracker.trackSettingsChange("share_mood", oldValue: !newValue, newValue: newValue)
                        }
                    )
                    
                    SettingsToggleRow(
                        icon: "location.fill",
                        title: "Location for Mood Map",
                        subtitle: "Help build the community mood map",
                        isOn: $shareLocation,
                        onToggle: { newValue in
                            activityTracker.trackSettingsChange("share_location", oldValue: !newValue, newValue: newValue)
                        }
                    )
                    
                    SettingsToggleRow(
                        icon: "lock.fill",
                        title: "Private Mode",
                        subtitle: "Only approved friends can see your mood",
                        isOn: $privateAccount,
                        onToggle: { newValue in
                            activityTracker.trackSettingsChange("private_mode", oldValue: !newValue, newValue: newValue)
                        }
                    )
                    
                    // Your Health & Data section
                    SettingsSectionHeader(title: "Your Health & Data")
                    
                    SettingsToggleRow(
                        icon: "heart.fill",
                        title: "Health App Integration",
                        subtitle: "Connect mood with your health metrics",
                        isOn: $syncHealthData,
                        onToggle: { newValue in
                            activityTracker.trackSettingsChange("health_integration", oldValue: !newValue, newValue: newValue)
                        }
                    )
                    
                    SettingsToggleRow(
                        icon: "square.and.arrow.up.fill",
                        title: "Quick Sharing",
                        subtitle: "Easily share to social platforms",
                        isOn: $autoShareMood,
                        onToggle: { newValue in
                            activityTracker.trackSettingsChange("auto_share", oldValue: !newValue, newValue: newValue)
                        }
                    )
                    
                    SettingsToggleRow(
                        icon: "network",
                        title: "Advanced Integrations",
                        subtitle: "Connect with other apps and services",
                        isOn: $useCustomAPI,
                        onToggle: { newValue in
                            activityTracker.trackSettingsChange("advanced_integrations", oldValue: !newValue, newValue: newValue)
                        }
                    )
                    
                    // Spotify Integration
                    SpotifyConnectionRow()
                    
                    // Analytics & Insights section
                    SettingsSectionHeader(title: "Analytics & Insights")
                    
                    NavigationLink(destination: AnalyticsDashboardView()) {
                        SettingsRowWithDescription(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Analytics Dashboard",
                            subtitle: "View your comprehensive mood and health insights"
                        )
                    }
                    
                    NavigationLink(destination: APITestView()) {
                        SettingsRowWithDescription(
                            icon: "wrench.and.screwdriver",
                            title: "API Testing",
                            subtitle: "Test and validate all integrated services"
                        )
                    }
                    
                    // Support & Help section
                    SettingsSectionHeader(title: "Support & Help")
                    
                    NavigationLink(destination: Text("Help Center")) {
                        SettingsRowWithDescription(
                            icon: "questionmark.circle.fill",
                            title: "Get Help",
                            subtitle: "FAQs, tutorials, and support"
                        )
                    }
                    
                    NavigationLink(destination: Text("Contact Support")) {
                        SettingsRowWithDescription(
                            icon: "envelope.fill",
                            title: "Contact Us",
                            subtitle: "Have questions? We're here to help"
                        )
                    }
                    
                    NavigationLink(destination: Text("Terms & Privacy")) {
                        SettingsRowWithDescription(
                            icon: "doc.text.fill",
                            title: "Privacy & Terms",
                            subtitle: "How we protect your data"
                        )
                    }
                    
                    NavigationLink(destination: Text("API Settings")) {
                        SettingsRowWithDescription(
                            icon: "gear",
                            title: "Advanced Settings",
                            subtitle: "API configuration and developer options"
                        )
                    }
                    
                    // Account Management section - moved to bottom
                    SettingsSectionHeader(title: "Account")
                    
                    // Phone Number Management
                    if !authManager.isGuestMode {
                        Button(action: {
                            showPhoneNumberInput = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "phone.fill")
                                    .font(.body)
                                    .frame(width: 24)
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Phone Number")
                                        .font(.body)
                                        .foregroundColor(themeManager.primaryTextColor)
                                    
                                    Text(authManager.hasPhoneNumber ? "Update your phone number" : "Add your phone number")
                                        .font(.caption)
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(themeManager.secondaryTextColor)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(themeManager.backgroundColor)
                        }
                    }
                    
                    // Guest mode create account button
                    if authManager.isGuestMode {
                        Button(action: {
                            authManager.logout() // This will take them back to onboarding
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.badge.plus")
                                    .font(.body)
                                    .frame(width: 24)
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Create Account")
                                        .font(.body)
                                        .foregroundColor(themeManager.primaryTextColor)
                                    
                                    Text("Save your data and sync across devices")
                                        .font(.caption)
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(themeManager.secondaryTextColor)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(themeManager.backgroundColor)
                        }
                    }
                    
                    // Sign out button - moved to bottom
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.body)
                                .frame(width: 24)
                                .foregroundColor(.red)
                            
                            Text(authManager.isGuestMode ? "Exit Guest Mode" : "Sign Out")
                                .font(.body)
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(themeManager.backgroundColor)
                    }
                    
                    // Version info
                    VStack(spacing: 4) {
                        Text("CheckIn")
                            .font(.footnote)
                            .foregroundColor(themeManager.secondaryTextColor)
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 100)
                }
            }
        }
        .alert(authManager.isGuestMode ? "Exit Guest Mode" : "Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button(authManager.isGuestMode ? "Exit Guest Mode" : "Sign Out", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text(authManager.isGuestMode ? 
                 "Are you sure you want to exit guest mode? You'll return to the welcome screen." :
                 "Are you sure you want to sign out? You'll need to enter your username again to log back in.")
        }
        .sheet(isPresented: $showPhoneNumberInput) {
            PhoneInputView(isPresented: $showPhoneNumberInput)
                .environmentObject(authManager)
        }
        .onAppear {
            // Check phone number status when settings loads
            if !authManager.isGuestMode {
                authManager.checkPhoneNumberExist()
            }
        }
    }
    

    
    // MARK: - Theme Helper Functions
    
    private func themeIconName(for theme: AppTheme) -> String {
        switch theme {
        case .dark:
            return "moon.fill"
        case .light:
            return "sun.max.fill"
        case .multiColor:
            return "paintpalette.fill"
        }
    }
    
    private func themeDescription(for theme: AppTheme) -> String {
        switch theme {
        case .dark:
            return "Elegant dark interface for better focus"
        case .light:
            return "Clean bright interface for daytime use"
        case .multiColor:
            return "Adaptive colors that reflect your emotions"
        }
    }
    
    private func themePreviewBackground(for theme: AppTheme) -> Color {
        switch theme {
        case .dark:
            return Color.black.opacity(0.2)
        case .light:
            return Color.white.opacity(0.2)
        case .multiColor:
            return Color.purple.opacity(0.2)
        }
    }
    
    private func themePreviewBorder(for theme: AppTheme) -> Color {
        switch theme {
        case .dark:
            return Color.white.opacity(0.3)
        case .light:
            return Color.black.opacity(0.3)
        case .multiColor:
            return Color.purple.opacity(0.3)
        }
    }
    
    private func themePreviewIconColor(for theme: AppTheme) -> Color {
        switch theme {
        case .dark:
            return Color.white
        case .light:
            return Color.black
        case .multiColor:
            return Color.purple
        }
    }
    
    private func themeSelectionColor(for theme: AppTheme) -> Color {
        switch theme {
        case .dark:
            return Color.white
        case .light:
            return Color.black
        case .multiColor:
            return Color.purple
        }
    }
}

// MARK: - Spotify Connection Row Component

struct SpotifyConnectionRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var spotifyConnected = false
    @State private var isConnecting = false
    
    var body: some View {
        Button(action: {
            connectSpotify()
        }) {
            HStack(spacing: 12) {
                Image(systemName: spotifyConnected ? "checkmark.circle.fill" : "music.note")
                    .font(.body)
                    .frame(width: 24)
                    .foregroundColor(spotifyConnected ? .green : themeManager.primaryTextColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spotify Integration")
                        .font(.body)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text(spotifyConnected ? "Connected - Syncing your music data" : isConnecting ? "Connecting..." : "Connect to sync your listening habits")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                if isConnecting {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if spotifyConnected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(themeManager.secondaryTextColor)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(themeManager.backgroundColor)
        }
        .disabled(isConnecting)
        .onAppear {
            // Check if already connected
            checkSpotifyConnection()
        }
    }
    
    private func connectSpotify() {
        isConnecting = true
        
        SpotifyAuthManager.shared.configureSpotify { result in
            DispatchQueue.main.async {
                isConnecting = false
                switch result {
                case .success(let isAuthenticated):
                    spotifyConnected = isAuthenticated
                    if isAuthenticated {
                        loadSpotifyRecentyPlayed()
                    }
                case .failure(let error):
                    print("Error authenticating: \(error)")
                    spotifyConnected = false
                }
            }
        }
    }
    
    private func loadSpotifyRecentyPlayed() {
        SpotifyAuthManager.shared.fetchSavedTracks { result in
            switch result {
            case .success(let tracks):
                print("Successfully fetched \(tracks.count) Spotify tracks")
                // Could save data here if needed
            case .failure(let error):
                print("Error fetching recently played tracks: \(error)")
            }
        }
    }
    
    private func checkSpotifyConnection() {
        // Check if user is already authenticated
        // This would depend on how SpotifyAuthManager tracks auth state
        spotifyConnected = false // Default to false, could be improved
    }
}

struct SettingsSectionHeader: View {
    let title: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.captionLarge)
                .fontWeight(.bold)
                .foregroundColor(themeManager.secondaryTextColor)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
}

struct SettingsRowSimple: View {
    let icon: String
    let title: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(themeManager.primaryTextColor)
                .font(.bodyMedium)
                .frame(width: 24)
            
            Text(title)
                .font(.bodyMedium)
                .foregroundColor(themeManager.primaryTextColor)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(themeManager.secondaryTextColor)
                .font(.captionLarge)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(themeManager.backgroundColor)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let onToggle: ((Bool) -> Void)?
    @EnvironmentObject var themeManager: ThemeManager
    
    init(icon: String, title: String, subtitle: String, isOn: Binding<Bool>, onToggle: ((Bool) -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.onToggle = onToggle
    }
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(themeManager.primaryTextColor)
                .font(.bodyMedium)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bodyMedium)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text(subtitle)
                    .font(.captionLarge)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { newValue in
                    let oldValue = isOn
                    isOn = newValue
                    onToggle?(newValue)
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: .green))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(themeManager.backgroundColor)
    }
}

struct SettingsRowWithDescription: View {
    let icon: String
    let title: String
    let subtitle: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(themeManager.primaryTextColor)
                .font(.bodyMedium)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bodyMedium)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text(subtitle)
                    .font(.captionLarge)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(themeManager.secondaryTextColor)
                .font(.captionLarge)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(themeManager.backgroundColor)
    }
}

struct ProfileEditView: View {
    @ObservedObject var authManager: AuthManager
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var editedName: String = ""
    @State private var editedUsername: String = ""
    @State private var editedEmail: String = ""
    @State private var editedPhone: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(themeManager.primaryTextColor.opacity(0.8))
                            
                            Text("Edit Profile")
                                .font(.headingLarge)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.primaryTextColor)
                            
                            Text("Update your personal information")
                                .font(.bodyMedium)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 20) {
                            // Name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                TextField("Enter your full name", text: $editedName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.bodyMedium)
                            }
                            
                            // Username field
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Username")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(themeManager.primaryTextColor)
                                    
                                    Spacer()
                                    
                                    if !authManager.canChangeUsername() {
                                        Text("\(authManager.daysUntilUsernameChange()) days left")
                                            .font(.captionLarge)
                                            .foregroundColor(.orange)
                                    }
                                }
                                
                                TextField("Enter username", text: $editedUsername)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.bodyMedium)
                                    .disabled(!authManager.canChangeUsername())
                                    .opacity(authManager.canChangeUsername() ? 1.0 : 0.6)
                                
                                if !authManager.canChangeUsername() {
                                    Text("You can change your username every 14 days")
                                        .font(.captionLarge)
                                        .foregroundColor(.orange.opacity(0.8))
                                }
                            }
                            
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email Address")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                TextField("Enter your email", text: $editedEmail)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.bodyMedium)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            // Phone field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Phone Number")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                TextField("Enter your phone number", text: $editedPhone)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.bodyMedium)
                                    .keyboardType(.phonePad)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Save button
                        Button(action: saveProfile) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Profile")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 26)
                                    .fill(Color.blue)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Guest info
                        if authManager.isGuestMode {
                            VStack(spacing: 8) {
                                Text("Guest Account")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue.opacity(0.8))
                                
                                Text("Your changes are saved locally. Create a real account to sync across devices.")
                                    .font(.caption)
                                    .foregroundColor(themeManager.secondaryTextColor)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(themeManager.primaryTextColor)
                }
            }
        }
        .onAppear {
            editedName = authManager.currentName
            editedUsername = authManager.currentUsername
            editedEmail = healthDataManager.userEmail
            editedPhone = healthDataManager.userPhone
        }
        .alert("Profile Update", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveProfile() {
        // Update name
        authManager.updateName(editedName) { success, message in
            if !success {
                alertMessage = message
                showingAlert = true
                return
            }
            
            // Update username if changed and allowed
            if editedUsername != authManager.currentUsername && authManager.canChangeUsername() {
                authManager.updateUsername(editedUsername) { success, message in
                    if !success {
                        alertMessage = message
                        showingAlert = true
                        return
                    }
                    
                    // Update health data
                    updateHealthData()
                }
            } else {
                // Update health data
                updateHealthData()
            }
        }
    }
    
    private func updateHealthData() {
        healthDataManager.userName = editedName
        healthDataManager.userEmail = editedEmail
        healthDataManager.userPhone = editedPhone
        
        alertMessage = "Profile updated successfully!"
        showingAlert = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            presentationMode.wrappedValue.dismiss()
        }
    }
} 