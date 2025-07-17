//
//  ContactDetailView.swift
//  moodgpt
//
//  Created by Test on 5/27/25.
//

import SwiftUI

// MARK: - Contact Detail View
struct ContactDetailView: View {
    let contact: Contact
    @State private var showingReplyOverlay = false
    @State private var contentOffset: CGFloat = 0
    @State private var replyContext: ReplyContext?
    @Environment(\.chatIsShowing) var chatIsShowing
    @State private var dragOffset: CGFloat = 0
    @EnvironmentObject var pinnedContactsManager: PinnedContactsManager
    @Environment(\.presentationMode) var presentationMode
    
    // Generate emotional timeline for this contact
    var emotionalTimeline: [EmotionalTimelineItem] {
        ContactDetailHelpers.generateEmotionalTimeline(for: contact)
    }
    
    var body: some View {
        ZStack {
            EmotionData.backgroundGradient(for: contact.moodText)
                .ignoresSafeArea(.all)
            VStack {
                // Custom header with back button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Back")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.3))
                        )
                    }
                    
                    Spacer()
                    
                    Text("\(contact.name)'s Emotions")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 80, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60) // Account for status bar
                
                // Main content
                ScrollView {
                    VStack(spacing: 20) {
                        // Header - Optimized spacing with proper top padding for safe area
                        VStack(spacing: 12) {
                            AnimatedEmoji(contact.mood, size: 80, fallback: contact.mood)
                            
                            VStack(spacing: 6) {
                                Text(contact.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(contact.location)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.top, 100) // Add more top padding to account for nav bar
                        
                        // Current Emotion - Compact and clickable design
                        VStack(spacing: 12) {
                            Text("Current Emotion")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Button(action: {
                                replyContext = ReplyContext(
                                    type: .emotion,
                                    content: contact.moodText,
                                    emoji: contact.mood
                                )
                                withAnimation(.spring()) {
                                    showingReplyOverlay = true
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Text(contact.moodText)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("Primary Emotion")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("Last updated 2 minutes ago")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Emotional Timeline
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.white)
                                Text("Mood Forecast")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(emotionalTimeline, id: \.time) { item in
                                        PullDownTimelineCard(
                                            item: item,
                                            showingOverlay: $showingReplyOverlay,
                                            replyContext: $replyContext
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Emotion Analysis
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(.white)
                                Text("Emotion Analysis")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            PullDownAnalysisCard(
                                text: ContactDetailHelpers.generateEmotionAnalysis(for: contact),
                                contact: contact,
                                showingOverlay: $showingReplyOverlay,
                                replyContext: $replyContext
                            )
                        }
                        .padding(.horizontal)
                        
                        // Emotion Intensity
                        NavigationLink(destination: EmotionIntensityDetailView(contact: contact)) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Emotion Intensity")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                VStack(spacing: 8) {
                                    HStack {
                                        Text(ContactDetailHelpers.generateIntensityPercentage(for: contact))
                                            .font(.largeTitle)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "thermometer")
                                            .foregroundColor(ContactDetailHelpers.intensityColor(for: contact))
                                            .font(.title2)
                                    }
                                    
                                    ProgressView(value: Double(ContactDetailHelpers.generateIntensityValue(for: contact)) / 100)
                                        .progressViewStyle(LinearProgressViewStyle(tint: ContactDetailHelpers.intensityColor(for: contact)))
                                        .scaleEffect(x: 1, y: 2, anchor: .center)
                                    
                                    Text(ContactDetailHelpers.generateIntensityDescription(for: contact))
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("Tap for detailed analysis →")
                                        .font(.caption)
                                        .foregroundColor(.blue.opacity(0.8))
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Mood Triggers & Influences
                        NavigationLink(destination: MoodTriggersDetailView(contact: contact)) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Mood Triggers & Influences")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                VStack(spacing: 10) {
                                    ForEach(ContactDetailHelpers.generateMoodTriggers(for: contact), id: \.self) { trigger in
                                        TriggerRow(icon: "arrow.up.right", text: trigger)
                                    }
                                    
                                    Text("Tap for detailed impact analysis →")
                                        .font(.caption)
                                        .foregroundColor(.blue.opacity(0.8))
                                        .padding(.top, 4)
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Communication Insights
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "message.fill")
                                    .foregroundColor(.white)
                                Text("Communication Insights")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 12) {
                                PullDownCommunicationInsightRow(
                                    icon: "clock.fill",
                                    title: "Best Contact Time",
                                    value: ContactDetailHelpers.generateBestContactTime(for: contact),
                                    showingOverlay: $showingReplyOverlay,
                                    replyContext: $replyContext
                                )
                                
                                PullDownCommunicationInsightRow(
                                    icon: "phone.fill",
                                    title: "Preferred Method",
                                    value: ContactDetailHelpers.generatePreferredMethod(for: contact),
                                    showingOverlay: $showingReplyOverlay,
                                    replyContext: $replyContext
                                )
                                
                                PullDownCommunicationInsightRow(
                                    icon: "chart.pie.fill",
                                    title: "Response Rate",
                                    value: ContactDetailHelpers.generateResponseRate(for: contact),
                                    showingOverlay: $showingReplyOverlay,
                                    replyContext: $replyContext
                                )
                                
                                PullDownCommunicationInsightRow(
                                    icon: "person.3.fill",
                                    title: "Relationship Strength",
                                    value: ContactDetailHelpers.generateRelationshipStrength(for: contact),
                                    showingOverlay: $showingReplyOverlay,
                                    replyContext: $replyContext
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Recent Mood Changes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Mood Changes")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 10) {
                                ForEach(ContactDetailHelpers.generateRecentMoodChanges(for: contact), id: \.id) { change in
                                    PullDownMoodChangeRow(
                                        fromMood: change.fromMood,
                                        toMood: change.toMood,
                                        timeAgo: change.timeAgo,
                                        reason: change.reason,
                                        showingOverlay: $showingReplyOverlay,
                                        replyContext: $replyContext
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Secondary Emotions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Secondary Emotions")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(ContactDetailHelpers.generateSecondaryEmotions(for: contact), id: \.emotion) { secondary in
                                        PullDownSecondaryEmotion(
                                            emotion: secondary.emotion,
                                            emoji: secondary.emoji,
                                            percentage: secondary.percentage,
                                            showingOverlay: $showingReplyOverlay,
                                            replyContext: $replyContext
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Related Contacts
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Related Contacts")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 10) {
                                HStack {
                                    Text("People with similar moods")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Spacer()
                                }
                                
                                ContactMoodStack(contacts: ContactDetailHelpers.generateRelatedContacts(for: contact))
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 60)
                    }
                }
            }
            .offset(y: showingReplyOverlay ? -UIScreen.main.bounds.height * 0.3 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showingReplyOverlay)
            
            // Full-screen chat overlay
            if showingReplyOverlay {
                FullScreenChatOverlay(
                    recipientName: contact.name,
                    replyContext: replyContext,
                    isShowing: $showingReplyOverlay
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
                .zIndex(1)
            }
        }
        .navigationBarHidden(true) // Hide navigation bar completely to remove white space
    }
} 
