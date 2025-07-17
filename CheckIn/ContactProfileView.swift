import SwiftUI

// MARK: - Contact Profile View
struct ContactProfileView: View {
    let contact: Contact
    @StateObject private var emotionManager = EmotionAnalysisManager.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    // State for collapsible sections
    @State private var showBehaviorAnalysis = false
    @State private var showHealthFactors = false
    @State private var showEmotionProfile = false
    
    var body: some View {
        NavigationView {
            ZStack {
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Section
                        contactHeaderSection
                        
                        // Emotion Summary Card
                        emotionSummaryCard
                        
                        // Detailed Analysis Sections
                        if emotionManager.hasContactProfile(for: contact.name) {
                            enhancedBehaviorAnalysisSection
                            enhancedHealthFactorsSection
                            enhancedEmotionProfileSection
                            metadataSection
                        } else {
                            loadingOrErrorSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.primaryTextColor)
                }
            }
        }
        .onAppear {
            loadContactAnalysisIfNeeded()
        }
    }
    
    // MARK: - Header Section
    private var contactHeaderSection: some View {
        VStack(spacing: 16) {
            // Large emoji display with animation
            ZStack {
                Circle()
                    .fill(themeManager.cardBackgroundColor)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(themeManager.borderColor, lineWidth: 2)
                    )
                
                AnimatedEmoji(contact.mood, size: 60, fallback: "neutral-face")
            }
            
            VStack(spacing: 8) {
                Text(contact.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text(contact.location)
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Text(contact.phoneNumber)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeManager.borderColor, lineWidth: 1)
                    )
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Enhanced Emotion Summary Card
    private var emotionSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(themeManager.primaryTextColor)
                Text("Emotion Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                if let emojiId = contact.predictedEmojiId {
                    Text("ID: \(emojiId)")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(6)
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current State")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text(contact.moodText)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.primaryTextColor)
                }
                
                Spacer()
                
                let emojiName = emotionManager.getContactEmojiName(for: contact.name)
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Emoji Type")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text(emojiName.replacingOccurrences(of: "-", with: " ").capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.primaryTextColor)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            if let lastUpdate = contact.lastSentimentUpdate {
                Text("Last updated: \(lastUpdate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .cornerRadius(15)
    }
    
    // MARK: - Enhanced Behavior Analysis Section
    private var enhancedBehaviorAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showBehaviorAnalysis.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(themeManager.primaryTextColor)
                    Text("Behavioral Analysis")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Spacer()
                    
                    Image(systemName: showBehaviorAnalysis ? "chevron.up" : "chevron.down")
                        .foregroundColor(themeManager.secondaryTextColor)
                        .rotationEffect(.degrees(showBehaviorAnalysis ? 180 : 0))
                        .animation(.easeInOut(duration: 0.3), value: showBehaviorAnalysis)
                }
            }
            
            if showBehaviorAnalysis {
                ScrollView {
                    Text(contact.behaviorFactors ?? "No behavioral data available")
                        .font(.body)
                        .foregroundColor(themeManager.primaryTextColor)
                        .lineLimit(nil)
                        .textSelection(.enabled)
                        .padding()
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(10)
                }
                .frame(maxHeight: 300)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .cornerRadius(15)
        .animation(.easeInOut(duration: 0.3), value: showBehaviorAnalysis)
    }
    
    // MARK: - Enhanced Health Factors Section
    private var enhancedHealthFactorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showHealthFactors.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "heart.text.square")
                        .foregroundColor(themeManager.primaryTextColor)
                    Text("Health & Wellness Analysis")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Spacer()
                    
                    Image(systemName: showHealthFactors ? "chevron.up" : "chevron.down")
                        .foregroundColor(themeManager.secondaryTextColor)
                        .rotationEffect(.degrees(showHealthFactors ? 180 : 0))
                        .animation(.easeInOut(duration: 0.3), value: showHealthFactors)
                }
            }
            
            if showHealthFactors {
                ScrollView {
                    Text(contact.healthFactors ?? "No health data available")
                        .font(.body)
                        .foregroundColor(themeManager.primaryTextColor)
                        .lineLimit(nil)
                        .textSelection(.enabled)
                        .padding()
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(10)
                }
                .frame(maxHeight: 300)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .cornerRadius(15)
        .animation(.easeInOut(duration: 0.3), value: showHealthFactors)
    }
    
    // MARK: - Enhanced Emotion Profile Section
    private var enhancedEmotionProfileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showEmotionProfile.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .foregroundColor(themeManager.primaryTextColor)
                    Text("Detailed Emotion Profile")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Spacer()
                    
                    Image(systemName: showEmotionProfile ? "chevron.up" : "chevron.down")
                        .foregroundColor(themeManager.secondaryTextColor)
                        .rotationEffect(.degrees(showEmotionProfile ? 180 : 0))
                        .animation(.easeInOut(duration: 0.3), value: showEmotionProfile)
                }
            }
            
            if showEmotionProfile {
                ScrollView {
                    Text(contact.userEmotionProfile ?? "No emotion profile available")
                        .font(.body)
                        .foregroundColor(themeManager.primaryTextColor)
                        .lineLimit(nil)
                        .textSelection(.enabled)
                        .padding()
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(10)
                }
                .frame(maxHeight: 300)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .cornerRadius(15)
        .animation(.easeInOut(duration: 0.3), value: showEmotionProfile)
    }

    // MARK: - Metadata Section
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(themeManager.primaryTextColor)
                Text("Analysis Metadata")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.primaryTextColor)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                metadataCard("Name", contact.name)
                metadataCard("Phone", contact.phoneNumber)
                metadataCard("Location", contact.location)
                
                if let city = contact.city {
                    metadataCard("Detected City", city)
                }
                
                if let emojiId = contact.predictedEmojiId {
                    metadataCard("Emoji ID", "\(emojiId)")
                    metadataCard("Emoji Type", emotionManager.getContactEmojiName(for: contact.name).replacingOccurrences(of: "-", with: " ").capitalized)
                }
                
                metadataCard("Emotion", contact.moodText)
                
                if let lastUpdate = contact.lastSentimentUpdate {
                    metadataCard("Last Analysis", lastUpdate.formatted(date: .abbreviated, time: .shortened))
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .cornerRadius(15)
    }

    // MARK: - Loading or Error Section
    private var loadingOrErrorSection: some View {
        VStack(spacing: 16) {
            if emotionManager.isLoadingContactsSentiment {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: themeManager.primaryTextColor))
                    .scaleEffect(1.5)
                
                Text("Analyzing contact sentiment...")
                    .font(.headline)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("This may take a few moments")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            } else if emotionManager.hasAPIError() {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("Analysis Unavailable")
                    .font(.headline)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("Unable to load sentiment analysis data")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Button("Retry Analysis") {
                    loadContactAnalysisIfNeeded()
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .foregroundColor(themeManager.primaryTextColor)
                .cornerRadius(10)
            } else {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 50))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("No Analysis Data")
                    .font(.headline)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text("Contact analysis is not available")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .cornerRadius(15)
    }
    
    // MARK: - Helper Views
    private func metadataCard(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
                .fontWeight(.medium)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.primaryTextColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .background(themeManager.cardBackgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(themeManager.borderColor, lineWidth: 1)
        )
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    private func loadContactAnalysisIfNeeded() {
        // Contact analysis is now handled by the sequential analysis system in HomeView
        // This view only displays data - no need to trigger additional API calls
        
    }
}

// MARK: - Preview
struct ContactProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ContactProfileView(
            contact: Contact(
                name: "Alice Johnson",
                location: "San Francisco, CA",
                mood: "😐",
                moodText: "Neutral",
                phoneNumber: "+1-555-123-4567"
            )
        )
    }
} 