//
//  ContactsView.swift
//  moodgpt
//
//  Created by Test on 5/27/25.
//

import SwiftUI
import HealthKit
import Combine

// Extracted components now in separate files:
// - Follower.swift
// - ContactTabType.swift 
// - FollowerListRow.swift
// - DeviceContactListRow.swift
// - GroupedContactListRow.swift
// - NewPageView.swift
// - TimeAgo.swift

struct ContactsView: View {
    @State private var currentTime = Date()
    @EnvironmentObject var pinnedContactsManager: PinnedContactsManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var activityTracker = ActivityTrackingManager()
    @StateObject private var apiManager = APIManager.shared
    @StateObject private var followingSyncManager = FollowingSyncManager.shared
    @State private var showingContactsList = false
    @State private var contactPermissionManager = ContactsManager()
    @StateObject private var healthDataManager = HealthDataManager()
    @StateObject private var dataManager = IntegratedDataManager.shared
    @StateObject private var emotionManager = EmotionAnalysisManager.shared
    @State private var showEnergySelector = false
    
    // Contact Tab Management
    @State private var selectedContactTab: ContactTabType = .following
    @State private var followers: [Follower] = []
    @State private var isLoadingFollowers = false
    
    // API management
    @State private var cancellables = Set<AnyCancellable>()
    
    private var sequentialAnalysisManager = SequentialContactAnalysisService.shared
    @State private var lastContactListHash: Int = 0
    @State private var hasCalledAPIThisSession = false
    @State private var currentUserMood = "neutral-face" {
        didSet {
            let validatedMood = EmojiMapper.hasGifFile(for: currentUserMood) ? currentUserMood : "neutral-face"
            UserDefaults.standard.set(validatedMood, forKey: "CurrentUserMood")
        }
    }
    @State private var currentUserMoodText = "Neutral" {
        didSet {
            UserDefaults.standard.set(currentUserMoodText, forKey: "CurrentUserMoodText")
        }
    }
    @State private var selectedContactForProfile: Contact? = nil
    @State private var showPrivacyInfo = false
    
    // Contact management states
    @State private var searchText = ""
    @State private var selectedMoodFilter = "All"
    @State private var showSearchBar = false
    @State private var useGroupedView = true
    @StateObject private var contactsManager = ContactsManager()
    @State private var showNewPage = false
    
    // Minimal timer for time updates only
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    var filteredContacts: [DeviceContact] {
        let contacts = contactsManager.allContacts
        
        if searchText.isEmpty {
            return contacts
        } else {
            return contacts.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) || 
                $0.initials.localizedCaseInsensitiveContains(searchText) 
            }
        }
    }
    
    var filteredGroupedContacts: [GroupedContact] {
        let contacts = contactsManager.groupedContacts
        
        if searchText.isEmpty {
            return contacts
        } else {
            return contacts.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) || 
                $0.initials.localizedCaseInsensitiveContains(searchText) ||
                $0.phoneNumbers.contains { $0.contains(searchText) }
            }
        }
    }
    
    var filteredFollowers: [Follower] {
        if searchText.isEmpty {
            return followers
        } else {
            return followers.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) || 
                $0.initials.localizedCaseInsensitiveContains(searchText) 
            }
        }
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            if showingContactsList {
                contactsListView
            } else {
                dashboardView
            }
            
            // Privacy info popup
            if showPrivacyInfo {
                PrivacyInfoPopup(isPresented: $showPrivacyInfo)
                    .zIndex(999)
            }
        }
        .trackScreenAuto(ContactsView.self)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            onViewAppear()
            
            // Debug: Print sync status
            print("📱 Following Sync Status: \(followingSyncManager.syncStatus)")
            if let lastSync = followingSyncManager.lastSyncTime {
                print("📱 Last sync: \(lastSync)")
            }
        }
        .onDisappear {
            dataManager.trackViewDisappearance("Contacts")
        }
        .sheet(isPresented: $showEnergySelector) {
            CompactEnergySelector(isPresented: $showEnergySelector)
        }
        .sheet(item: $selectedContactForProfile) { contact in
            ContactProfileView(contact: contact)
        }
        .sheet(isPresented: $showNewPage) {
            NewPageView()
        }
        .onChange(of: emotionManager.userEmotionAnalysis) { oldValue, newValue in
            updateUserMoodFromAPI()
        }
        .onChange(of: sequentialAnalysisManager.contactEmotions) { oldValue, newValue in
            print("Contact emotions updated: \(newValue.count) analyzed")
        }
        .onChange(of: pinnedContactsManager.pinnedContacts) { oldValue, newValue in
            sequentialAnalysisManager.updateSelectedContacts(newValue)
        }
        .onChange(of: selectedContactTab) { oldValue, newValue in
            if newValue == .followers && followers.isEmpty {
                loadFollowersFromAPI()
            }
        }
        .onChange(of: authManager.currentUsername) { oldValue, newValue in
            // Sync following list when user changes
            if !newValue.isEmpty && newValue != oldValue {
                followingSyncManager.syncFollowingList(
                    username: newValue,
                    pinnedContactsManager: pinnedContactsManager
                )
            }
        }
    }
    
    // MARK: - Dashboard View (Main Content)
    
    private var dashboardView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                contactsSection
                bottomSpacing
            }
        }
    }
    
    // MARK: - Contacts List View (Hidden Management)
    
    private var contactsListView: some View {
        VStack(spacing: 0) {
            // Header with back button and search
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingContactsList = false
                        searchText = ""
                        showSearchBar = false
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back to Contacts")
                    }
                    .foregroundColor(themeManager.primaryTextColor)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            useGroupedView.toggle()
                        }
                    }) {
                        Image(systemName: useGroupedView ? "person.2.fill" : "person.fill")
                            .foregroundColor(useGroupedView ? .blue : themeManager.secondaryTextColor)
                            .font(.title3)
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSearchBar.toggle()
                            if !showSearchBar {
                                searchText = ""
                            }
                        }
                    }) {
                        Image(systemName: showSearchBar ? "xmark" : "magnifyingglass")
                            .foregroundColor(themeManager.primaryTextColor)
                            .font(.title3)
                    }
                    
                    Button(action: {
                        showNewPage = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Search bar (only shown when search button is tapped)
            if showSearchBar {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    TextField("Search all contacts", text: $searchText)
                        .foregroundColor(themeManager.primaryTextColor)
                        .autocapitalization(.none)
                        .keyboardType(.default)
                        .submitLabel(.search)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                }
                .padding(8)
                .background(themeManager.cardBackgroundColor.opacity(0.8))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Main content area with improved error handling
            if contactsManager.isLoading {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.primaryTextColor))
                        .scaleEffect(1.2)
                    Text("Loading Contacts...")
                        .foregroundColor(themeManager.primaryTextColor)
                        .font(.headline)
                }
                Spacer()
            } else if let errorMessage = contactsManager.permissionError {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text("Contacts Access Needed")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text(errorMessage)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Grant Permission in Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .font(.headline)
                }
                Spacer()
            } else if contactsManager.allContacts.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text("No Contacts Found")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("Make sure you have contacts saved on your device")
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Refresh Contacts") {
                        contactsManager.refreshContactsIfPermitted()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .font(.headline)
                }
                Spacer()
            } else {
                // Contacts list with safety checks
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if useGroupedView {
                            // Grouped contacts view
                            ForEach(filteredGroupedContacts.indices, id: \.self) { index in
                                if index < filteredGroupedContacts.count {
                                    let contact = filteredGroupedContacts[index]
                                    GroupedContactListRow(
                                        contact: .constant(contact),
                                        onToggleFavorites: { phoneNumber in
                                            handleGroupedContactToggle(phoneNumber, contactName: contact.name)
                                        },
                                        isPinned: { phoneNumber in
                                            isPhoneNumberPinned(phoneNumber)
                                        },
                                        onEditName: {
                                            handleGroupedContactNameEdit()
                                        },
                                        onSplitContact: {
                                            handleSplitContact(contact)
                                        },
                                        onMergeContact: {
                                            handleMergeContact(contact)
                                        },
                                        contactHasSimilarContacts: { name in
                                            checkForSimilarContacts(name)
                                        }
                                    )
                                    .environmentObject(themeManager)
                                }
                            }
                        } else {
                            // Individual contacts view
                            ForEach(filteredContacts.indices, id: \.self) { index in
                                if index < filteredContacts.count {
                                    let contact = filteredContacts[index]
                                    DeviceContactListRow(
                                        contact: contact,
                                        onToggleFavorites: {
                                            handleContactToggle(contact)
                                        },
                                        isPinned: pinnedContactsManager.pinnedContacts.contains { $0.phoneNumber == contact.phoneNumber }
                                    )
                                    .environmentObject(themeManager)
                                }
                            }
                        }
                        
                        // Bottom padding for better scrolling
                        Color.clear
                            .frame(height: 100)
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                contactsManager.refreshContactsIfPermitted()
                
                // Fetch header stats for all contacts after they're loaded
                if !contactsManager.allContacts.isEmpty {
                    let pinnedContacts = contactsManager.allContacts.map { deviceContact in
                        Contact(
                            name: deviceContact.name,
                            location: "Unknown",
                            mood: "neutral-face",
                            moodText: "Neutral",
                            phoneNumber: deviceContact.phoneNumber
                        )
                    }
                    contactsManager.fetchHeaderStats(for: Array(pinnedContacts.prefix(20))) // Limit to first 20 for performance
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        ZStack {
            // Smart base background - comfortable for all themes
            if themeManager.currentTheme == .light {
                Color(red: 0.96, green: 0.96, blue: 0.98)
                    .ignoresSafeArea()
            } else {
                // Solid dark base for dark themes to prevent white lines
                Color.black
                    .ignoresSafeArea()
            }
            
            // Base background
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            // Emotion-based gradient overlay for multi-color theme
            if let gradient = themeManager.backgroundGradient {
                gradient
                    .ignoresSafeArea()
            }
            
            // Semi-transparent overlay for better readability in multi-color mode
            if themeManager.currentTheme == .multiColor {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
            }
            
            // Floating emojis background - only if enabled
            if themeManager.showEmojisInBackground {
                FloatingEmojisBackground()
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            headerTitle
            Spacer()
            userEmotionButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
    }
    
    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("CheckIn")
                .font(.brandTitle)
                .fontWeight(.heavy)
                .foregroundStyle(titleGradient)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
            
            HStack(spacing: 4) {
                Text(greetingText)
                    .font(.captionLarge)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Text(displayName)
                    .font(.headingSmall)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.primaryTextColor)
            }
        }
    }
    
    private var titleGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                themeManager.primaryTextColor,
                themeManager.primaryTextColor.opacity(0.9),
                Color.purple.opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var displayName: String {
        if !healthDataManager.userName.isEmpty {
            return healthDataManager.userName
        } else if !authManager.currentName.isEmpty {
            return authManager.currentName
        } else {
            return authManager.currentUsername
        }
    }
    
    private var userEmotionButton: some View {
        NavigationLink(destination: PersonalEmotionDetailView(currentMood: currentUserMood, moodText: currentUserMoodText)) {
            ZStack {
                Circle()
                    .stroke(Color.purple.opacity(0.8), lineWidth: 3)
                    .frame(width: 86, height: 86)
                
                Circle()
                    .fill(themeManager.cardBackgroundColor.opacity(0.5))
                    .frame(width: 80, height: 80)
                
                AnimatedEmoji(currentUserMood, size: 78, fallback: currentUserMood)
            }
        }
    }
    
    private var contactsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Contacts")
                    .font(.headingMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.primaryTextColor)

                Spacer()
                
                // Sync status indicator
                if followingSyncManager.isSyncing {
                    HStack(spacing: 4) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.8)
                        Text("Syncing...")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                } else if let error = followingSyncManager.syncError {
                    Image(systemName: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .help(error)
                } else if followingSyncManager.lastSyncTime != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .opacity(0.8)
                }

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(selectedContactTab == .following ? "\(pinnedContactsManager.pinnedContacts.count)/12" : "\(followers.count)")
                            .font(.captionMedium)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                showPrivacyInfo = true
                            }
                        }) {
                            Image(systemName: "info.circle")
                                .font(.captionLarge)
                                .foregroundColor(.blue.opacity(0.8))
                        }
                    }
                    
                    if selectedContactTab == .following {
                        HStack(spacing: 8) {
                        Button(action: {
                            withAnimation {
                                showingContactsList = true
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.captionLarge)
                                Text("Manage Contacts")
                                    .font(.captionMedium)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(0.15))
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .disabled(pinnedContactsManager.pinnedContacts.count >= 12)
                            
                            // Manual sync button
                            Button(action: {
                                followingSyncManager.syncFollowingList(
                                    username: authManager.currentUsername,
                                    pinnedContactsManager: pinnedContactsManager
                                )
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.captionLarge)
                                    .foregroundColor(.blue)
                                    .padding(4)
                                    .background(
                                        Circle()
                                            .fill(Color.blue.opacity(0.15))
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .disabled(followingSyncManager.isSyncing || authManager.currentUsername.isEmpty)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // Contact Tab Slider
            contactTabSlider
                .padding(.horizontal, 24)

            // Content based on selected tab
            if selectedContactTab == .following {
                if pinnedContactsManager.pinnedContacts.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 32))
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Text("No contacts selected yet")
                            .font(.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Text("Use the button above to select contacts for emotion analysis")
                            .font(.captionLarge)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            if contactsManager.allContacts.isEmpty && !contactsManager.isLoading {
                                contactsManager.refreshContactsIfPermitted()
                            }
                            
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingContactsList = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.plus")
                                Text("Add Contacts")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.8))
                            )
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.cardBackgroundColor.opacity(0.5))
                            .stroke(themeManager.borderColor, lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                } else {
                    // Display all pinned contacts
                    VStack(spacing: 10) {
                        ForEach(pinnedContactsManager.pinnedContacts) { pinnedContact in
                            let analyzedContact = sequentialAnalysisManager.contactEmotions.first { $0.phoneNumber == pinnedContact.phoneNumber }
                                    VStack(spacing: 8) {
                                        // Contact info row (tappable)
                                NavigationLink(destination: ContactDetailWebPage(contactNumber: pinnedContact.phoneNumber, contactName: pinnedContact.name)) {
                                            HStack(spacing: 12) {
                                        AnimatedEmoji(analyzedContact?.emoji ?? pinnedContact.mood, size: 52, fallback: "neutral-face")
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                            Text(pinnedContact.name)
                                                        .font(.body)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(themeManager.primaryTextColor)
                                                        .lineLimit(1)
                                                    
                                            if let analyzed = analyzedContact {
                                                Text(getConsistentLocation(for: analyzed))
                                                        .font(.captionMedium)
                                                        .foregroundColor(themeManager.secondaryTextColor)
                                                        .lineLimit(1)
                                            }
                                                    
                                                    // Display header stats if available
                                            if let headerStats = contactsManager.getHeaderStats(for: pinnedContact.phoneNumber),
                                                       let data = headerStats.data {
                                                        HStack(spacing: 8) {
                                                            if let energy = data.energy {
                                                                Text("⚡ \(energy)")
                                                                    .font(.caption)
                                                                    .foregroundColor(.orange)
                                                            }
                                                            if let sleepHours = data.sleepHours {
                                                                Text("😴 \(sleepHours, specifier: "%.1f")h")
                                                                    .font(.caption)
                                                                    .foregroundColor(.blue)
                                                            }
                                                            if let heartRate = data.heartRate {
                                                                Text("❤️ \(heartRate)")
                                                                    .font(.caption)
                                                                    .foregroundColor(.red)
                                                            }
                                                            if let steps = data.steps {
                                                                Text("👟 \(steps)")
                                                                    .font(.caption)
                                                                    .foregroundColor(.green)
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                VStack(alignment: .trailing, spacing: 2) {
                                            if let analyzed = analyzedContact {
                                                if timeAgoText(analyzed.lastUpdated) == "now" {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .font(.captionLarge)
                                                            .foregroundColor(.green)
                                                    } else {
                                                        Image(systemName: "chevron.right")
                                                            .font(.captionLarge)
                                                            .foregroundColor(themeManager.secondaryTextColor)
                                                    }
                                                    
                                                Text("Updated \(timeAgoText(analyzed.lastUpdated))")
                                                        .font(.captionSmall)
                                                        .foregroundColor(themeManager.secondaryTextColor)
                                            } else {
                                                Image(systemName: "chevron.right")
                                                    .font(.captionLarge)
                                                    .foregroundColor(themeManager.secondaryTextColor)
                                            }
                                                }
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(themeManager.cardBackgroundColor)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(themeManager.borderColor, lineWidth: 1)
                                            )
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                }
            } else {
                // Followers Tab Content
                if isLoadingFollowers {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager.primaryTextColor))
                            .scaleEffect(1.2)
                        Text("Loading Followers...")
                            .foregroundColor(themeManager.primaryTextColor)
                            .font(.headline)
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                } else if followers.isEmpty {
                    // Show empty state when not loading and no followers
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 32))
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Text("No followers yet")
                            .font(.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Text("When people follow you, they'll appear here")
                            .font(.captionLarge)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        // Add retry button in case of API failure
                        Button("Refresh") {
                            loadFollowersFromAPI()
                        }
                        .font(.captionLarge)
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.cardBackgroundColor.opacity(0.5))
                            .stroke(themeManager.borderColor, lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                } else {
                    // Show followers list
                    VStack(spacing: 10) {
                        ForEach(filteredFollowers) { follower in
                            FollowerListRow(
                                follower: follower,
                                onFollowBack: {
                                    handleFollowBack(follower)
                                }
                            )
                            .environmentObject(themeManager)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private var bottomSpacing: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 100)
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
    
    // MARK: - Helper Functions
    
    private func onViewAppear() {
        currentTime = Date()
        
        // Initial data loading
        dataManager.trackViewAppearance("Contacts")
        
        // Load contacts if not already loaded
        if contactsManager.allContacts.isEmpty {
            contactsManager.refreshContactsIfPermitted()
        }
        
        // Fetch header stats for pinned contacts
        if !pinnedContactsManager.pinnedContacts.isEmpty {
            contactsManager.fetchHeaderStats(for: pinnedContactsManager.pinnedContacts)
        }
        
        // Load user mood from UserDefaults
        if let savedMood = UserDefaults.standard.string(forKey: "CurrentUserMood") {
            currentUserMood = savedMood
        }
        if let savedMoodText = UserDefaults.standard.string(forKey: "CurrentUserMoodText") {
            currentUserMoodText = savedMoodText
        }
        
        // Load followers if needed
        if selectedContactTab == .followers && followers.isEmpty {
            loadFollowersFromAPI()
        }
        
        // Sync following list if needed
        if !authManager.currentUsername.isEmpty && followingSyncManager.shouldSync() {
            followingSyncManager.syncFollowingList(
                username: authManager.currentUsername,
                pinnedContactsManager: pinnedContactsManager
            )
        }
        
        // Monitor for updated contacts to fetch header stats
        if !pinnedContactsManager.pinnedContacts.isEmpty {
            let contactsHash = pinnedContactsManager.pinnedContacts.map { $0.phoneNumber }.joined().hash
            if contactsHash != lastContactListHash {
                lastContactListHash = contactsHash
                contactsManager.fetchHeaderStats(for: pinnedContactsManager.pinnedContacts)
            }
        }
        
        // Load emotion analysis for pinned contacts
        loadEmotionAnalysis()
    }
    
    private func calculateContactsHash() -> Int {
        let contactNames = pinnedContactsManager.pinnedContacts.map { $0.name }.sorted()
        return contactNames.joined().hash
    }
    
    private func loadEmotionAnalysis() {
        let username = !authManager.currentUsername.isEmpty ? authManager.currentUsername : "dummy"
        
        Task {
            await emotionManager.analyzeUserEmotion(username: username)
        }
        
        if !pinnedContactsManager.pinnedContacts.isEmpty {
            sequentialAnalysisManager.startSequentialAnalysis(for: pinnedContactsManager.pinnedContacts)
        }
    }
    
    private func updateUserMoodFromAPI() {
        let newMood = emotionManager.getUserEmoji()
        let newMoodText = emotionManager.getUserMoodText()
        
        if emotionManager.hasUserEmotionData() || emotionManager.hasAPIError() || !emotionManager.isLoadingUserEmotion {
            currentUserMood = newMood
            currentUserMoodText = newMoodText
        }
    }
    
    private func syncContactsForEmotionAnalysis() {
        sequentialAnalysisManager.updateSelectedContacts(pinnedContactsManager.pinnedContacts)
        
        if !pinnedContactsManager.pinnedContacts.isEmpty {
            sequentialAnalysisManager.startSequentialAnalysis(for: pinnedContactsManager.pinnedContacts)
        }
    }
    
    private func timeAgoText(_ date: Date) -> String {
        return TimeAgo.text(from: date)
    }
    
    private func handleContactToggle(_ contact: DeviceContact) {
        let isCurrentlyPinned = pinnedContactsManager.pinnedContacts.contains { $0.phoneNumber == contact.phoneNumber }
        let currentUsername = authManager.currentUsername
        
        if isCurrentlyPinned {
                                apiManager.unfollowUserWithCleanedPhone(phoneNumber: contact.phoneNumber, followerUsername: currentUsername)
            
            pinnedContactsManager.unpinContactByPhone(contact.phoneNumber)
            activityTracker.trackContactInteraction(contact.name, actionType: "contact_removed")
        } else {
            if pinnedContactsManager.pinnedContacts.count < 12 {
                                    apiManager.followUserWithCleanedPhone(phoneNumber: contact.phoneNumber, followerUsername: currentUsername)
                
                let newContact = Contact(
                    name: contact.name,
                    location: "Unknown",
                    mood: "slightly-happy",
                    moodText: "Neutral",
                    phoneNumber: contact.phoneNumber
                )
                pinnedContactsManager.pinContact(newContact)
                activityTracker.trackContactInteraction(contact.name, actionType: "contact_added")
            }
        }
        
        let currentContacts = pinnedContactsManager.pinnedContacts.map { $0.name }
        activityTracker.trackContactSelection(currentContacts)
    }
    
    // MARK: - Grouped Contact Handling
    
    private func handleGroupedContactToggle(_ phoneNumber: String, contactName: String) {
        let isCurrentlyPinned = pinnedContactsManager.pinnedContacts.contains { $0.phoneNumber == phoneNumber }
        let currentUsername = authManager.currentUsername
        
        if isCurrentlyPinned {
            apiManager.unfollowUserWithCleanedPhone(phoneNumber: phoneNumber, followerUsername: currentUsername)
            
            pinnedContactsManager.unpinContactByPhone(phoneNumber)
            activityTracker.trackContactInteraction(contactName, actionType: "contact_removed")
        } else {
            if pinnedContactsManager.pinnedContacts.count < 12 {
                apiManager.followUserWithCleanedPhone(phoneNumber: phoneNumber, followerUsername: currentUsername)
                
                let newContact = Contact(
                    name: contactName,
                    location: "Unknown",
                    mood: "slightly-happy",
                    moodText: "Neutral",
                    phoneNumber: phoneNumber
                )
                pinnedContactsManager.pinContact(newContact)
                activityTracker.trackContactInteraction(contactName, actionType: "contact_added")
            }
        }
        
        let currentContacts = pinnedContactsManager.pinnedContacts.map { $0.name }
        activityTracker.trackContactSelection(currentContacts)
    }
    
    private func isPhoneNumberPinned(_ phoneNumber: String) -> Bool {
        return pinnedContactsManager.pinnedContacts.contains { $0.phoneNumber == phoneNumber }
    }
    
    private func handleGroupedContactNameEdit() {
        contactsManager.groupedContacts = contactsManager.groupedContacts.sorted { $0.name < $1.name }
    }
    
    private func handleSplitContact(_ contact: GroupedContact) {
        contactsManager.splitContactIntoSeparateContacts(contactId: contact.id)
    }
    
    private func handleMergeContact(_ contact: GroupedContact) {
        contactsManager.mergeSimilarContacts(baseName: contact.name)
    }
    
    private func checkForSimilarContacts(_ name: String) -> Bool {
        let baseName = name.components(separatedBy: " (").first ?? name
        return contactsManager.groupedContacts.contains { otherContact in
            let otherBaseName = otherContact.name.components(separatedBy: " (").first ?? otherContact.name
            return otherBaseName == baseName && otherContact.name != name
        }
    }
    
    private func getConsistentLocation(for contact: SequentialContactEmotion) -> String {
        if !contact.isApiUser {
            return "Not a user"
        }
        
        let location = getCityFromPhoneNumber(contact.phoneNumber)
        return location.isEmpty ? contact.city : location
    }
    
    private func getCityFromPhoneNumber(_ phoneNumber: String) -> String {
        let digits = phoneNumber.filter { $0.isNumber }
        guard digits.count >= 3 else { return "" }
        
        let areaCode = String(digits.prefix(3))
        return getLocationFromAreaCode(areaCode)
    }
    
    private func getLocationFromAreaCode(_ areaCode: String) -> String {
        let areaCodeMap: [String: String] = [
            "201": "Jersey City, NJ", "202": "Washington, DC", "212": "New York, NY",
            "213": "Los Angeles, CA", "214": "Dallas, TX", "215": "Philadelphia, PA",
            "305": "Miami, FL", "312": "Chicago, IL", "415": "San Francisco, CA",
            "617": "Boston, MA", "713": "Houston, TX", "818": "Los Angeles, CA"
            // Add more area codes as needed
        ]
        
        return areaCodeMap[areaCode] ?? ""
    }
    
    private var contactTabSlider: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(ContactTabType.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedContactTab = tab
                        }
                    }) {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedContactTab == tab ? Color.white.opacity(0.2) : Color.clear)
                            )
                    }
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
            
            Spacer()
        }
    }
    
    // MARK: - API Functions
    
    private func loadFollowersFromAPI() {
        guard !isLoadingFollowers else { return }
        
        let currentUsername = authManager.currentUsername
        guard !currentUsername.isEmpty else {
            print("⚠️ Cannot load followers: no current username")
            return
        }
        
        print("📡 Loading followers for username: '\(currentUsername)'")
        isLoadingFollowers = true
        
        // Call the proper getFollowers API method
        apiManager.getFollowers(user: currentUsername) { result in
            DispatchQueue.main.async {
                self.isLoadingFollowers = false
                
                switch result {
                case .success(let response):
                    print("✅ Followers API success: User=\(response.user), Followers=\(response.followers)")
                    
                    // Convert follower usernames to Follower objects
                    let followerObjects = response.followers.map { followerUsername in
                        Follower(
                            name: followerUsername,
                            phoneNumber: self.generateMockPhoneNumber(for: followerUsername),
                            profileImageUrl: nil,
                            isFollowingBack: false, // We can enhance this later by checking if we follow them back
                            followedSince: Date() // Default to current date, could be enhanced with real data
                        )
                    }
                    
                    self.followers = followerObjects
                    print("📱 Updated followers list with \(followerObjects.count) followers")
                    
                case .failure(let error):
                    print("❌ Failed to load followers: \(error.localizedDescription)")
                    self.followers = []
                    
                    // Show error to user if needed
                    // Could add an @State error message property to display in UI
                }
            }
        }
    }
    
    private func generateMockPhoneNumber(for username: String) -> String {
        let hash = abs(username.hashValue)
        let areaCode = 555
        let number = hash % 10000
        return "+1-\(areaCode)-\(String(format: "%04d", number))"
    }
    
    private func handleFollowBack(_ follower: Follower) {
        if let index = followers.firstIndex(where: { $0.id == follower.id }) {
            let newFollowStatus = !follower.isFollowingBack
            let currentUsername = authManager.currentUsername
            
            followers[index] = Follower(
                name: follower.name,
                phoneNumber: follower.phoneNumber,
                profileImageUrl: follower.profileImageUrl,
                isFollowingBack: newFollowStatus,
                followedSince: follower.followedSince
            )
            
            if newFollowStatus {
                apiManager.followUserWithCleanedPhone(phoneNumber: follower.phoneNumber, followerUsername: currentUsername)
                
                let isAlreadyFollowing = pinnedContactsManager.pinnedContacts.contains { $0.name == follower.name }
                if !isAlreadyFollowing && pinnedContactsManager.pinnedContacts.count < 12 {
                    let newContact = Contact(
                        name: follower.name,
                        location: "Unknown",
                        mood: "slightly-happy",
                        moodText: "Neutral",
                        phoneNumber: follower.phoneNumber
                    )
                    pinnedContactsManager.pinContact(newContact)
                    activityTracker.trackContactInteraction(follower.name, actionType: "contact_added")
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    ContactsView()
        .environmentObject(ThemeManager())
        .environmentObject(PinnedContactsManager())
        .environmentObject(AuthManager())
}
#endif 