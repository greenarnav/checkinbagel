//
//  CelebritiesView.swift
//  moodgpt
//
//  Created by Test on 6/5/25.
//

import SwiftUI

struct CelebritiesView: View {
    @StateObject private var celebrityManager = CelebrityManager()
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var activityTracker = ActivityTrackingManager()
    @State private var showingSearchBar = false
    @State private var selectedCelebrity: Celebrity?
    @State private var celebrityViewStartTime: Date?
    
    var body: some View {
        ZStack {
            // Base background
            themeManager.backgroundColor.ignoresSafeArea()
            
            if let gradient = themeManager.backgroundGradient {
                gradient
                    .ignoresSafeArea()
            }
            
            // Semi-transparent overlay for better readability in multi-color mode
            if themeManager.currentTheme == .multiColor {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                headerSection
                suggestedCelebritiesBar
                categoryFilters
                
                // Scrollable content
                ScrollView {
                    LazyVStack(spacing: 8) {
                        // Loading state
                        if celebrityManager.isLoading {
                            VStack {
                                Spacer()
                                // Simple circle loading animation like home page
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager.primaryTextColor))
                                    .scaleEffect(2.0)
                                Spacer()
                            }
                            .frame(height: 300)
                        }
                        // Error state
                        else if let errorMessage = celebrityManager.errorMessage {
                            VStack(spacing: 20) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.red.opacity(0.8))
                                
                                Text("Failed to Load")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                Text(errorMessage)
                                    .font(.body)
                                    .foregroundColor(themeManager.secondaryTextColor)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                
                                Button(action: {
                                    celebrityManager.refreshData()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Retry")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color.blue.opacity(0.8))
                                    )
                                }
                                .padding(.top, 10)
                            }
                            .padding(.top, 80)
                        }
                        // Empty state when no celebrities are loaded
                        else if celebrityManager.allCelebrities.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(themeManager.primaryTextColor.opacity(0.6))
                                
                                Text("No Celebrity Data")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                Text("No celebrity emotion data is currently available. Please check back later.")
                                    .font(.body)
                                    .foregroundColor(themeManager.secondaryTextColor)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                
                                Button(action: {
                                    celebrityManager.refreshData()
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Refresh")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 25)
                                            .fill(Color.green.opacity(0.8))
                                    )
                                }
                                .padding(.top, 10)
                            }
                            .padding(.top, 80)
                        } else {
                            // Show celebrities when data is available
                            ForEach(celebrityManager.paginatedCelebrities) { celebrity in
                                CelebrityRowView(celebrity: celebrity) {
                                    selectedCelebrity = celebrity
                                    celebrityViewStartTime = Date()
                                    // Track celebrity selection
                                    activityTracker.trackCelebrityViewing(
                                        celebrity.name,
                                        category: celebrity.category.rawValue
                                    )
                                }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            }
                            
                            // Load more button
                            if celebrityManager.hasMorePages {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        celebrityManager.loadNextPage()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.down.circle.fill")
                                        Text("Load More")
                                            .font(.buttonFont)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(themeManager.cardBackgroundColor)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .padding(.top, 12)
                            }
                            
                            // Removed irrelevant "Showing x of x" text for cleaner UI
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 80) // Reduced padding at bottom for tab bar
                }
            }
        }
        .trackScreenAuto(CelebritiesView.self)
        .onAppear {
            celebrityManager.resetPagination()
        }
        .onChange(of: celebrityManager.searchText) { oldValue, newValue in
            celebrityManager.resetPagination()
        }
        .onChange(of: celebrityManager.selectedCategory) { oldValue, newValue in
            celebrityManager.resetPagination()
        }
        .fullScreenCover(item: $selectedCelebrity) { celebrity in
            SwipeableCelebrityDetailView(
                selectedCelebrity: celebrity,
                allCelebrities: celebrityManager.allCelebrities,
                onDismiss: {
                    // Track time spent viewing celebrity
                    if let startTime = celebrityViewStartTime {
                        let timeSpent = Date().timeIntervalSince(startTime)
                        activityTracker.trackCelebrityViewing(
                            celebrity.name,
                            category: celebrity.category.rawValue,
                            timeSpent: timeSpent
                        )
                    }
                    selectedCelebrity = nil
                    celebrityViewStartTime = nil
                }
            )
            .environmentObject(themeManager)
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Title and search
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Public")
                        .font(.brandTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text("Celebrity Emotions")
                        .font(.captionLarge)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingSearchBar.toggle()
                    }
                    
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }) {
                    Image(systemName: showingSearchBar ? "xmark.circle.fill" : "magnifyingglass.circle.fill")
                        .font(.headingMedium)
                        .foregroundColor(themeManager.primaryTextColor)
                }
            }
            .padding(.horizontal, 24)
            
            // Search bar
            if showingSearchBar {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    TextField("Search celebrities...", text: $celebrityManager.searchText)
                        .font(.bodyMedium)
                        .foregroundColor(themeManager.primaryTextColor)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocapitalization(.words)
                    
                    if !celebrityManager.searchText.isEmpty {
                        Button(action: {
                            celebrityManager.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.cardBackgroundColor)
                        .stroke(themeManager.borderColor, lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.top, 12)
    }
    
    // MARK: - Suggested Celebrities Bar (Emoji Only)
    private var suggestedCelebritiesBar: some View {
        Group {
            // Only show trending section if we have celebrities
            if !celebrityManager.allCelebrities.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Trending")
                            .font(.captionLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(celebrityManager.suggestedCelebrities) { celebrity in
                                Button(action: {
                                    selectedCelebrity = celebrity
                                    celebrityViewStartTime = Date()
                                    
                                    // Track trending celebrity selection
                                    activityTracker.trackCelebrityViewing(
                                        celebrity.name,
                                        category: celebrity.category.rawValue
                                    )
                                    activityTracker.trackCustomEvent("trending_celebrity_selected", data: [
                                        "celebrity_name": celebrity.name,
                                        "source": "trending_bar"
                                    ])
                                    
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }) {
                                    VStack(spacing: 4) {
                                        // Use AnimatedEmoji component with bigger size
                                        AnimatedEmoji(celebrity.emoji, size: 32, fallback: "😊")
                                        
                                        Text(celebrity.name.split(separator: " ").first ?? "")
                                            .font(.captionSmall)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.primaryTextColor)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 60, height: 55)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(themeManager.celebrityCardBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(themeManager.celebrityBorderColor, lineWidth: 1)
                                            )
                                            .shadow(color: themeManager.shadowColor, radius: 1, x: 0, y: 0.5)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 8)
            } else {
                // Empty placeholder when no celebrities
                EmptyView()
            }
        }
    }
    
    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // All categories button
                CategoryFilterButton(
                    title: "All",
                    isSelected: celebrityManager.selectedCategory == nil
                ) {
                    celebrityManager.selectedCategory = nil
                }
                .environmentObject(themeManager)
                
                // Category buttons
                ForEach(CelebrityCategory.allCases, id: \.self) { category in
                    CategoryFilterButton(
                        title: category.rawValue,
                        isSelected: celebrityManager.selectedCategory == category
                    ) {
                        celebrityManager.selectedCategory = category
                    }
                    .environmentObject(themeManager)
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Category Filter Button
struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    // Enhanced readable selected text color
    private var selectedTextColor: Color {
        switch themeManager.currentTheme {
        case .light:
            return themeManager.selectionTextColor
        case .dark:
            return themeManager.selectionTextColor
        case .multiColor:
            return themeManager.selectionTextColor
        }
    }
    
    // Enhanced selected background color
    private var selectedBackgroundColor: Color {
        switch themeManager.currentTheme {
        case .light:
            return themeManager.selectionBackgroundColor
        case .dark:
            return themeManager.selectionBackgroundColor
        case .multiColor:
            return themeManager.selectionBackgroundColor
        }
    }
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.captionLarge)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? selectedTextColor : themeManager.primaryTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? selectedBackgroundColor : themeManager.celebrityCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? themeManager.accentColor.opacity(0.6) : themeManager.celebrityBorderColor, lineWidth: 1)
                        )
                        .shadow(color: themeManager.shadowColor, radius: 2, x: 0, y: 1)
                )
        }
    }
}

// MARK: - Swipeable Celebrity Detail View
struct SwipeableCelebrityDetailView: View {
    let selectedCelebrity: Celebrity
    let allCelebrities: [Celebrity]
    let onDismiss: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    
    private var celebrities: [Celebrity] {
        // Create an infinite-feeling array by starting with selected celebrity
        // and arranging others around it for better UX
        var arranged: [Celebrity] = []
        
        // Find the index of selected celebrity
        if let selectedIndex = allCelebrities.firstIndex(where: { $0.id == selectedCelebrity.id }) {
            // Start with selected celebrity
            arranged.append(selectedCelebrity)
            
            // Add celebrities after the selected one
            for i in (selectedIndex + 1)..<allCelebrities.count {
                arranged.append(allCelebrities[i])
            }
            
            // Add celebrities before the selected one (wrapping around)
            for i in 0..<selectedIndex {
                arranged.append(allCelebrities[i])
            }
        } else {
            // Fallback: use all celebrities starting with selected
            arranged = allCelebrities
        }
        
        return arranged
    }
    
    var body: some View {
        ZStack {
            // Background
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            // Swipeable TabView
            TabView(selection: $currentIndex) {
                ForEach(0..<celebrities.count, id: \.self) { index in
                    CelebrityProfileCard(celebrity: celebrities[index], onDismiss: onDismiss)
                        .environmentObject(themeManager)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea()
            

        }
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    isDragging = true
                    dragOffset = gesture.translation
                }
                .onEnded { gesture in
                    isDragging = false
                    
                    let threshold: CGFloat = 50
                    
                    if gesture.translation.width > threshold {
                        // Swipe right - go to previous
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if currentIndex > 0 {
                                currentIndex -= 1
                            } else {
                                currentIndex = celebrities.count - 1
                            }
                        }
                    } else if gesture.translation.width < -threshold {
                        // Swipe left - go to next
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if currentIndex < celebrities.count - 1 {
                                currentIndex += 1
                            } else {
                                currentIndex = 0
                            }
                        }
                    }
                    
                    dragOffset = .zero
                }
        )
        .onAppear {
            // Add haptic feedback when opening
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        .onChange(of: currentIndex) { oldValue, newValue in
            // Haptic feedback on swipe
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    

}

// MARK: - Celebrity Profile Card (Optimized for Swiping)
struct CelebrityProfileCard: View {
    let celebrity: Celebrity
    let onDismiss: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isFollowing = false
    @State private var followerCount = 0
    @State private var showingShareSheet = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showTopControls: Bool = true
    @State private var showAIScoop = false
    @State private var aiScoopContent = ""
    @State private var isGeneratingAI = false
    
    var body: some View {
        ZStack {
            mainScrollView
            
            if showTopControls {
                topControlsOverlay
            }
        }
        .coordinateSpace(name: "scroll")
        .background(themeManager.backgroundColor)
        .onAppear {
            initializeCelebrityData()
        }
        .trackScreenAuto(CelebrityProfileCard.self)
        .actionSheet(isPresented: $showingShareSheet) {
            ActionSheet(
                title: Text("Share \(celebrity.name)'s Profile"),
                message: Text("Choose how you'd like to share"),
                buttons: [
                    .default(Text("Share to Social Media")) {
                        shareToSocialMedia()
                    },
                    .default(Text("Copy Link")) {
                        copyProfileLink()
                    },
                    .cancel()
                ]
            )
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var mainScrollView: some View {
        ScrollView {
            VStack(spacing: 0) {
                scrollOffsetTracker
                heroSection
                celebrityInfoSection
                contentSection
            }
        }
    }
    
    @ViewBuilder
    private var scrollOffsetTracker: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear {
                    scrollOffset = geometry.frame(in: .named("scroll")).minY
                }
                .onChange(of: geometry.frame(in: .named("scroll")).minY) { oldValue, newValue in
                    scrollOffset = newValue
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showTopControls = newValue >= -50
                    }
                }
        }
        .frame(height: 0)
    }
    
    @ViewBuilder
    private var heroSection: some View {
        ZStack {
            heroBackgroundImage
            heroGradientOverlay
        }
        .ignoresSafeArea(.all, edges: .top)
    }
    
    @ViewBuilder
    private var heroBackgroundImage: some View {
        AsyncImage(url: URL(string: getOptimizedImageURL(for: celebrity))) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.height * 0.5)
                    .clipped()
            case .failure(_), .empty:
                defaultGradientBackground
            @unknown default:
                defaultGradientBackground
            }
        }
    }
    
    @ViewBuilder
    private var defaultGradientBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.purple.opacity(0.8),
                Color.blue.opacity(0.9),
                Color.cyan.opacity(0.7)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: UIScreen.main.bounds.height * 0.5)
    }
    
    @ViewBuilder
    private var heroGradientOverlay: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black.opacity(0.3),
                Color.black.opacity(0.7)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: UIScreen.main.bounds.height * 0.5)
    }
    
    @ViewBuilder
    private var celebrityInfoSection: some View {
        VStack(spacing: 16) {
            AnimatedEmoji(celebrity.emoji, size: 80, fallback: "😊")
            
            celebrityNameAndMood
            actionButtonsRow
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
    
    @ViewBuilder
    private var celebrityNameAndMood: some View {
        VStack(spacing: 8) {
            // Actress Name with enhanced styling
            Text(celebrity.name)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(.black) // Changed to black as requested
                .multilineTextAlignment(.center)
                .shadow(color: .white.opacity(0.8), radius: 2, x: 0, y: 2)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
            
            // Mood text with subtle enhancement
            Text(celebrity.moodText)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                )
        }
        .padding(.horizontal, 8)
    }
    
    @ViewBuilder
    private var actionButtonsRow: some View {
        HStack(spacing: 8) {
            shareButton
            aiScoopButton
            if hasSocialMediaLinks() {
                followButton
            }
        }
    }
    
    @ViewBuilder
    private var shareButton: some View {
        Button(action: {
            showingShareSheet = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13, weight: .semibold))
                Text("Share")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minWidth: 80)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.blue.opacity(0.8))
            )
        }
    }
    
    @ViewBuilder
    private var aiScoopButton: some View {
        Button(action: {
            generateAIArticle()
        }) {
            HStack(spacing: 4) {
                if isGeneratingAI {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: showAIScoop ? "sparkles.square.filled.on.square" : "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(isGeneratingAI ? "Loading" : (showAIScoop ? "AI Scoop ✓" : "AI Scoop"))
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minWidth: 100)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(aiScoopButtonGradient)
            )
        }
        .disabled(isGeneratingAI)
    }
    
    private var aiScoopButtonGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                showAIScoop ? Color.green.opacity(0.8) : Color.purple.opacity(0.8),
                showAIScoop ? Color.teal.opacity(0.8) : Color.pink.opacity(0.8)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    @ViewBuilder
    private var followButton: some View {
        Button(action: {
            toggleFollow()
        }) {
            HStack(spacing: 4) {
                Image(systemName: isFollowing ? "checkmark" : "plus")
                    .font(.system(size: 12, weight: .bold))
                Text(isFollowing ? "Follow" : "Follow")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minWidth: 80)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(isFollowing ? Color.gray.opacity(0.8) : Color.green.opacity(0.8))
            )
        }
    }
    
    @ViewBuilder
    private var contentSection: some View {
        VStack(spacing: 20) {
            emotionalAnalysisSection
            
            if showAIScoop {
                aiScoopSection
            }
            
            emotionalTimelineSection
            sourcesSection
            lastUpdateSection
        }
        .padding(.top, 20)
        .background(themeManager.backgroundColor)
    }
    
    @ViewBuilder
    private var emotionalAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emotion Analysis")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeManager.currentTheme == .dark ? .white : .black)
            
            emotionalAnalysisContent
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var emotionalAnalysisContent: some View {
        let content = celebrity.context?.isEmpty == false ? 
            celebrity.context ?? "" : 
            "Current emotional state based on recent social media analysis and public interactions."
        
        Text(content)
            .font(.system(size: 15))
            .foregroundColor(themeManager.currentTheme == .dark ? .white : .black)
            .padding(16)
            .background(emotionalAnalysisBackground)
    }
    
    @ViewBuilder
    private var emotionalAnalysisBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(themeManager.cardBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(themeManager.borderColor, lineWidth: 1)
            )
            .shadow(color: themeManager.shadowColor, radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private var aiScoopSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            aiScoopHeader
            aiScoopContentView
        }
        .padding(.horizontal, 20)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
    }
    
    @ViewBuilder
    private var aiScoopHeader: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(.purple)
            Text("AI Scoop")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeManager.currentTheme == .dark ? .white : .black)
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Fresh")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }
        }
    }
    
    @ViewBuilder
    private var aiScoopContentView: some View {
        Text(aiScoopContent)
            .font(.system(size: 15))
            .foregroundColor(themeManager.currentTheme == .dark ? .white : .black)
            .padding(16)
            .background(aiScoopBackground)
    }
    
    @ViewBuilder
    private var aiScoopBackground: some View {
        if themeManager.currentTheme == .multiColor {
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.borderColor, lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.05),
                            Color.pink.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple.opacity(0.3),
                                    Color.pink.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }
    
    @ViewBuilder
    private var emotionalTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("24H Emotional Timeline")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(themeManager.currentTheme == .dark ? .white : .black)
            
            timelineScrollView
            timelineLegend
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var timelineScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array<CelebrityTimelineItem>(), id: \.time) { timelineItem in
                    timelineItemView(timelineItem)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private func timelineItemView(_ timelineItem: CelebrityTimelineItem) -> some View {
        VStack(spacing: 6) {
            Text(timelineItem.time)
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
                .fontWeight(.medium)
            
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
                AnimatedEmoji(timelineItem.emoji, size: 24, fallback: "😊")
            }
            
            Text(timelineItem.moodText)
                .font(.caption2)
                .foregroundColor(timelineItem.isCurrent ? 
                    (themeManager.currentTheme == .dark ? .white : .black) : 
                    (themeManager.currentTheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7)))
                .fontWeight(timelineItem.isCurrent ? .bold : .medium)
                .lineLimit(1)
        }
        .frame(width: 60)
        .padding(.vertical, 8)
        .background(timelineItemBackground(timelineItem.isCurrent))
        .scaleEffect(timelineItem.isCurrent ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: timelineItem.isCurrent)
    }
    
    @ViewBuilder
    private func timelineItemBackground(_ isCurrent: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isCurrent ? 
                themeManager.selectionBackgroundColor.opacity(0.3) : 
                themeManager.cardBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCurrent ? themeManager.accentColor.opacity(0.5) : 
                        themeManager.borderColor, lineWidth: 1)
            )
            .shadow(color: themeManager.shadowColor, radius: 1, x: 0, y: 0.5)
    }
    
    @ViewBuilder
    private var timelineLegend: some View {
        HStack {
            HStack(spacing: 4) {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.5))
                    .frame(width: 6, height: 6)
                Text("Current")
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
            }
            
            Spacer()
            
            Text("Updates every 2 hours")
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sources")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.currentTheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(celebrity.emotionReferences, id: \.self) { reference in
                        sourceButton(for: reference)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    @ViewBuilder
    private func sourceButton(for reference: String) -> some View {
        Button(action: {
            if let url = URL(string: reference) {
                UIApplication.shared.open(url)
            }
        }) {
            Text(extractDomainName(from: reference))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
    
    @ViewBuilder
    private var lastUpdateSection: some View {
        Text("Last updated: \(celebrity.lastUpdate)")
            .font(.system(size: 13))
            .foregroundColor(themeManager.currentTheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
    }
    
    @ViewBuilder
    private var topControlsOverlay: some View {
        VStack {
            HStack {
                closeButton
                Spacer()
                socialMediaIcons
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            
            Spacer()
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    @ViewBuilder
    private var closeButton: some View {
        Button(action: onDismiss) {
            HStack(spacing: 8) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                Text("Close")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.6))
            )
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
    
    @ViewBuilder
    private var socialMediaIcons: some View {
        HStack(spacing: 12) {
            if let instagramHandle = celebrity.instagramHandle {
                squareSocialMediaIcon(
                    imageName: "instagram",
                    url: "https://instagram.com/\(instagramHandle)"
                )
            }
            
            if let twitterHandle = celebrity.twitterHandle {
                squareSocialMediaIcon(
                    imageName: "x",
                    url: "https://twitter.com/\(twitterHandle)"
                )
            }
            
            if let facebookHandle = celebrity.facebookHandle {
                squareSocialMediaIcon(
                    imageName: "Facebook",
                    url: "https://facebook.com/\(facebookHandle)"
                )
            }
        }
    }
    
    // Helper functions
    
    private func extractDomainName(from urlString: String) -> String {
        guard let url = URL(string: urlString) else {
            // If it's not a valid URL, return a shortened version
            return String(urlString.prefix(20)) + (urlString.count > 20 ? "..." : "")
        }
        
        if let host = url.host {
            // Remove 'www.' prefix if present
            let cleanHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
            return cleanHost
        }
        
        // Fallback to first part of path or shortened URL
        return String(urlString.prefix(20)) + (urlString.count > 20 ? "..." : "")
    }
    
    private func getOptimizedImageURL(for celebrity: Celebrity) -> String {
        let screenWidth = UIScreen.main.bounds.width
        let optimalWidth = Int(screenWidth * UIScreen.main.scale)
        let imageWidth = min(max(optimalWidth, 400), 1200)
        
        if let apiImageUrl = celebrity.imageUrl {
            return apiImageUrl
        } else {
            return "https://picsum.photos/\(imageWidth)/600?random=\(celebrity.name.hashValue)"
        }
    }
    
    private func hasSocialMediaLinks() -> Bool {
        return celebrity.instagramHandle != nil || celebrity.twitterHandle != nil || celebrity.facebookHandle != nil
    }
    
    private func initializeCelebrityData() {
        isFollowing = false
        followerCount = 0
    }
    
    private func toggleFollow() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isFollowing.toggle()
            followerCount += isFollowing ? 1 : -1
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func shareToSocialMedia() {
        // Implementation for social media sharing
    }
    
    private func copyProfileLink() {
        UIPasteboard.general.string = "https://checkin.app/celebrity/\(celebrity.name.lowercased().replacingOccurrences(of: " ", with: "-"))"
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func generateAIArticle() {
        print("🤖 Generating AI article for \(celebrity.name)")
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // If already showing AI scoop, hide it
        if showAIScoop {
            withAnimation(.easeInOut(duration: 0.3)) {
                showAIScoop = false
            }
            return
        }
        
        // Show loading state
        withAnimation(.easeInOut(duration: 0.2)) {
            isGeneratingAI = true
        }
        
        // Call the actual API
        fetchAIScoopFromAPI()
    }
    
    private func fetchAIScoopFromAPI() {
        guard let celebrityUsername = celebrity.instagramHandle else {
            print("No username available for \(celebrity.name)")
            // Fallback to sample content
            let sampleContent = generateSampleAIContent(for: celebrity)
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.isGeneratingAI = false
                    self.aiScoopContent = sampleContent
                    self.showAIScoop = true
                }
            }
            return
        }
        
        guard let url = URL(string: "https://user-login-register-d6yw.onrender.com/get_latest_scoop") else {
            print("Invalid scoop API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        let payload: [String: String] = [
            "name": celebrityUsername
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
            
            print("🤖 Fetching AI scoop for \(celebrity.name) (username: \(celebrityUsername))")
            
                    // Capture necessary values before network call
        let currentCelebrity = celebrity
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                    
                    if let error = error {
                        print("AI Scoop API Error: \(error.localizedDescription)")
                        // Fallback to sample content on error
                        let sampleContent = generateSampleAIContent(for: currentCelebrity)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isGeneratingAI = false
                            aiScoopContent = sampleContent
                            showAIScoop = true
                        }
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        print("🤖 AI Scoop API Response: Status \(httpResponse.statusCode)")
                        
                        if httpResponse.statusCode == 200, let data = data {
                            do {
                                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                                   let scoop = json["scoop"] as? String {
                                    print("AI Scoop received successfully")
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isGeneratingAI = false
                                        aiScoopContent = scoop
                                        showAIScoop = true
                                    }
                                } else {
                                    print("Invalid response format from AI Scoop API")
                                    // Fallback to sample content
                                    let sampleContent = generateSampleAIContent(for: currentCelebrity)
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isGeneratingAI = false
                                        aiScoopContent = sampleContent
                                        showAIScoop = true
                                    }
                                }
                            } catch {
                                print("Failed to parse AI Scoop response: \(error)")
                                // Fallback to sample content
                                let sampleContent = generateSampleAIContent(for: currentCelebrity)
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isGeneratingAI = false
                                    aiScoopContent = sampleContent
                                    showAIScoop = true
                                }
                            }
                        } else {
                            print("AI Scoop API returned status \(httpResponse.statusCode)")
                            // Fallback to sample content
                            let sampleContent = generateSampleAIContent(for: currentCelebrity)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isGeneratingAI = false
                                aiScoopContent = sampleContent
                                showAIScoop = true
                            }
                        }
                    }
                }
            }.resume()
            
        } catch {
            print("Failed to encode AI Scoop request: \(error)")
            DispatchQueue.main.async {
                // Fallback to sample content
                let sampleContent = generateSampleAIContent(for: celebrity)
                withAnimation(.easeInOut(duration: 0.3)) {
                    isGeneratingAI = false
                    aiScoopContent = sampleContent
                    showAIScoop = true
                }
            }
        }
    }
    
    private func generateSampleAIContent(for celebrity: Celebrity) -> String {
        return "AI scoop content not available"
    }
    
    // Timeline generation removed - use only API data
    
    // Emotion progression generation removed - use only API data
    
    // connectButton function removed - using CelebritySocialLinks file for manual social media management
    
    // Square social media icon with rounded corners - no background
    private func squareSocialMediaIcon(imageName: String, url: String) -> some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Celebrity Row View
struct CelebrityRowView: View {
    let celebrity: Celebrity
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Animated emoji
                AnimatedEmoji(celebrity.emoji, size: 38, fallback: "😊")
                    .frame(width: 55, height: 55)
                
                // Celebrity info - clean and simple
                VStack(alignment: .leading, spacing: 4) {
                    Text(celebrity.name)
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryTextColor)
                        .lineLimit(1)
                    
                    Text(celebrity.moodText)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.celebrityCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager.celebrityBorderColor, lineWidth: 1)
                    )
                    .shadow(color: themeManager.shadowColor, radius: 1, x: 0, y: 0.5)
            )
        }
    }
}

// MARK: - Celebrity Timeline Model
struct CelebrityTimelineItem {
    let time: String
    let emoji: String
    let moodText: String
    let isCurrent: Bool
}
