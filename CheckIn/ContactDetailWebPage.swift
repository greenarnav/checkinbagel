//
//  ContactDetailWebPage.swift
//  CheckIn
//
//  Created by Masroor Elahi on 19/06/2025.
//

import SwiftUI

struct ContactDetailWebPage: View {
    @StateObject private var manager = ContactDetailManager()
    @StateObject private var analysisService = SequentialContactAnalysisService.shared
    @EnvironmentObject var themeManager: ThemeManager
    var contactNumber: String
    var contactName: String?
    @Environment(\.presentationMode) var presentationMode
    @State private var showNewPage = false
    
    // Contact data states - same format as home page
    @State private var contactMood: String = "neutral-face"
    @State private var contactMoodText: String = "Neutral"
    @State private var selectedTimeSlotIndex: Int = 3
    @State private var currentTimeSlotData: ContactTimeSlotData? = nil
    @State private var currentTime = Date()
    
    // Get analyzed contact from the service
    private var analyzedContact: SequentialContactEmotion? {
        analysisService.contactEmotions.first { $0.phoneNumber == contactNumber }
    }
    
    // Connection Resonance states
    @State private var showingConnectionResonance = false
    @State private var connectionResult = ""
    @State private var isGeneratingResonance = false
    
    // Timeline data for the contact
    private var contactEmotionalTimelineSlots: [(String, String, String, Bool)] {
        let currentHour = Calendar.current.component(.hour, from: currentTime)
        let currentInterval = (currentHour / 3) * 3
        
        var slots: [(String, String, String, Bool)] = []
        
        // Generate 7 time slots (3 past + 1 current + 3 future)
        for i in -3...3 {
            let hour = max(0, min(23, currentInterval + (i * 3)))
            let timeString = formatHour(hour)
            let isCurrent = (i == 0)
            
            // Generate mood for contact based on time
            let (mood, description) = generateContactMoodForTime(hour: hour, isCurrent: isCurrent)
            
            slots.append((timeString, mood, description, isCurrent))
        }
        
        return slots
    }
    
    var body: some View {
        ZStack {
            // Pure black background
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Header Row with close button and contact name
                    HStack {
                        Button("Close") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        
                        Spacer()
                        
                        Text(contactName ?? "Contact")
                            .font(.system(size: 26, weight: .bold, design: .default))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Connection Resonance button
                        Button(action: {
                            generateConnectionResonance()
                        }) {
                            Image(systemName: "person.2.wave.2")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Loading state or Contact Info Card with API Data
                    if analysisService.isAnalyzing && analysisService.currentlyAnalyzing == contactName {
                        // Show loading state while analyzing
                        HStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Analyzing \(contactName ?? "Contact")...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Fetching emotion data from API")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    } else if let apiContact = analyzedContact {
                        HStack(spacing: 12) {
                            AnimatedEmoji(apiContact.emoji, size: 48, fallback: "neutral-face")
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current Emotion")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(apiContact.isApiUser ? 
                                    ContactProfileHelpers.emojiNameForID(Int(apiContact.emoji) ?? 46) : 
                                    "Not a user")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                if !apiContact.city.isEmpty && apiContact.city != "Location Unknown" {
                                    HStack(spacing: 4) {
                                        Image(systemName: "location.fill")
                                            .font(.caption)
                                        Text(apiContact.city)
                                            .font(.caption)
                                    }
                                    .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            if apiContact.isApiUser {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Updated")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    Text(TimeAgo.text(from: apiContact.lastUpdated))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    
                    // Contact's Vitals Row (their data)
                    ContactVitalsRow()
                    
                    // Contact's Emotional Timeline
                    ContactEmotionalTimeline(
                        timelineSlots: contactEmotionalTimelineSlots,
                        selectedIndex: selectedTimeSlotIndex,
                        onSlotTap: handleTimelineSlotTap
                    )
                    
                    // Main Contact Emotion Display
                    ContactMainEmotionSnapshot(
                        mood: analyzedContact?.emoji ?? contactMood,
                        description: analyzedContact?.isApiUser == true ? 
                            analyzedContact!.emotionProfile : 
                            generateContactEmotionDescription()
                    )
                    
                    // Contact's Analysis Buttons (only show if contact is an API user)
                    if analyzedContact?.isApiUser == true {
                        ContactHorizontalButtonGroup(
                            currentTimeSlotData: currentTimeSlotData, 
                            contactName: contactName ?? "Contact",
                            analyzedContact: analyzedContact
                        )
                    }
                    
                    // Contact's Dynamic Insights - Disabled (no dummy data)
                    // ContactInsightsContext(currentTimeSlotData: currentTimeSlotData, contactName: contactName ?? "Contact")
                    
                    // Connection Resonance Result - Disabled (no dummy data)
                    // if !connectionResult.isEmpty {
                    //     ConnectionResonanceResult()
                    // }
                    
                    // Bottom spacing
                    Color.clear
                        .frame(height: 50)
                }
            }
        }
        .onAppear {
            loadContactData()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        .sheet(isPresented: $showNewPage) {
            NewPageView()
        }
    }
    
    // MARK: - Contact Data Generation Functions
    
    private func loadContactData() {
        // Check if we have API data for this contact
        if let apiContact = analyzedContact {
            contactMood = apiContact.emoji
            contactMoodText = apiContact.isApiUser ? 
                ContactProfileHelpers.emojiNameForID(Int(apiContact.emoji) ?? 46) : 
                "Not a user"
            
            // Log API data for debugging
            print("📱 Contact Detail: Loading API data for \(contactName ?? "Unknown")")
            print("   - Emoji: \(apiContact.emoji)")
            print("   - City: \(apiContact.city)")
            print("   - Is API User: \(apiContact.isApiUser)")
            print("   - Last Updated: \(apiContact.lastUpdated)")
        } else {
            // No API data available
            contactMood = "neutral-face"
            contactMoodText = ""
            print("📱 Contact Detail: No API data for \(contactName ?? "Unknown")")
        }
        
        // Generate current time slot data
        updateCurrentTimeSlotData()
    }
    
    private func handleTimelineSlotTap(index: Int, time: String, mood: String, description: String, isCurrent: Bool) {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedTimeSlotIndex = index
            contactMood = mood
            contactMoodText = description
            
            // Generate detailed data for selected time slot
            currentTimeSlotData = generateContactTimeSlotData(time: time, mood: mood, description: description, isCurrent: isCurrent)
        }
    }
    
    private func updateCurrentTimeSlotData() {
        let currentHour = Calendar.current.component(.hour, from: currentTime)
        let timeString = formatHour(currentHour)
        let (mood, description) = generateContactMoodForTime(hour: currentHour, isCurrent: true)
        
        currentTimeSlotData = generateContactTimeSlotData(time: timeString, mood: mood, description: description, isCurrent: true)
    }
    
    private func generateContactMoodForTime(hour: Int, isCurrent: Bool) -> (String, String) {
        // Return neutral state - no dummy moods
        return ("neutral-face", "")
    }
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 {
            return "12 AM"
        } else if hour < 12 {
            return "\(hour) AM"
        } else if hour == 12 {
            return "12 PM"
        } else {
            return "\(hour - 12) PM"
        }
    }
    
    private func generateContactEmotionDescription() -> String {
        return ""
    }
    

    
    private func extractHour(from timeString: String) -> Int {
        let components = timeString.components(separatedBy: " ")
        if let timeComponent = components.first {
            if let hour = Int(timeComponent) {
                let isPM = timeString.contains("PM")
                if isPM && hour != 12 {
                    return hour + 12
                } else if !isPM && hour == 12 {
                    return 0
                } else {
                    return hour
                }
            }
        }
        return 12
    }
    
    private func generateConnectionResonance() {
        // Connection resonance feature disabled - no dummy data
        isGeneratingResonance = false
        connectionResult = ""
    }
    
    private func generateContactTimeSlotData(time: String, mood: String, description: String, isCurrent: Bool) -> ContactTimeSlotData {
        return ContactTimeSlotData(
            time: time,
            mood: mood,
            description: description,
            isCurrent: isCurrent,
            steps: 0,
            activeEnergy: 0,
            heartRate: 0,
            location: "",
            weather: ""
        )
    }
    

}

// MARK: - Contact Data Models and Components

struct ContactTimeSlotData {
    let time: String
    let mood: String
    let description: String
    let isCurrent: Bool
    let steps: Int
    let activeEnergy: Int
    let heartRate: Int
    let location: String
    let weather: String
}

// MARK: - Contact Vitals Row
struct ContactVitalsRow: View {
    @State private var selectedMetrics: Set<Int> = Set([0, 1, 2, 3]) // Default 4 selected for contacts
    
    private let vitals = [
        RefinedVital(icon: "figure.walk", value: "", color: .green),
        RefinedVital(icon: "heart.fill", value: "", color: .red),
        RefinedVital(icon: "bolt.fill", value: "", color: .orange),
        RefinedVital(icon: "location.fill", value: "", color: .blue),
        RefinedVital(icon: "bed.double.fill", value: "", color: .purple),
        RefinedVital(icon: "thermometer.sun.fill", value: "", color: .orange),
        RefinedVital(icon: "map.fill", value: "", color: .cyan),
        RefinedVital(icon: "music.note", value: "", color: .indigo)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Their wellness data")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(vitals.enumerated()), id: \.offset) { index, vital in
                        HStack(spacing: 6) {
                            Image(systemName: vital.icon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(selectedMetrics.contains(index) ? vital.color : .white.opacity(0.6))
                            
                            if !vital.value.isEmpty {
                            Text(vital.value)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(selectedMetrics.contains(index) ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                                .overlay(
                                    Capsule()
                                        .stroke(selectedMetrics.contains(index) ? vital.color.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Contact Emotional Timeline
struct ContactEmotionalTimeline: View {
    let timelineSlots: [(String, String, String, Bool)]
    let selectedIndex: Int
    let onSlotTap: (Int, String, String, String, Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Their Mood Timeline")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(timelineSlots.enumerated()), id: \.offset) { index, slot in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                onSlotTap(index, slot.0, slot.1, slot.2, slot.3)
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(slot.0)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedIndex == index ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
                                        .frame(width: 65, height: 65)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedIndex == index ? Color.cyan.opacity(0.6) : Color.white.opacity(0.1), lineWidth: selectedIndex == index ? 2 : 1)
                                        )
                                    
                                    AnimatedEmoji(slot.1, size: 36, fallback: "neutral-face")
                                        .opacity(0.8)
                                        .scaleEffect(0.9)
                                }
                                
                                Text(slot.2)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Contact Main Emotion Snapshot
struct ContactMainEmotionSnapshot: View {
    let mood: String
    let description: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Large floating emoji with gentle animation
            AnimatedEmoji(mood, size: 104, fallback: "neutral-face")
                .opacity(0.8)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: isAnimating)
                .shadow(color: .white.opacity(0.05), radius: 10, x: 0, y: 5)
                .onAppear {
                    isAnimating = true
                }
            
            Text(description)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Contact Horizontal Button Group (AI Scoop, Mental Pulse, Social Vibe)
struct ContactHorizontalButtonGroup: View {
    let currentTimeSlotData: ContactTimeSlotData?
    let contactName: String
    let analyzedContact: SequentialContactEmotion?
    @State private var showingAIScoop = false
    @State private var showingMentalPulse = false
    @State private var showingSocialVibe = false
    @State private var isGeneratingAI = false
    @State private var isGeneratingMental = false
    @State private var isGeneratingSocial = false
    @State private var aiScoopContent = ""
    @State private var mentalPulseContent = ""
    @State private var socialVibeContent = ""
    
    var body: some View {
        VStack(spacing: 12) {
            // Horizontal Button Group
            HStack(spacing: 6) {
                // AI Scoop Button
                Button(action: {
                    handleAIScoopTap()
                }) {
                    HStack(spacing: 4) {
                        if isGeneratingAI {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: showingAIScoop ? "sparkles.square.filled.on.square" : "sparkles")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Text("AI Scoop")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(width: 95)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        showingAIScoop ? Color.green.opacity(0.25) : Color.purple.opacity(0.25),
                                        showingAIScoop ? Color.teal.opacity(0.25) : Color.pink.opacity(0.25)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(showingAIScoop ? Color.green.opacity(0.3) : Color.purple.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                }
                .disabled(isGeneratingAI)
                .buttonStyle(PlainButtonStyle())
                
                // Mental Pulse Button
                Button(action: {
                    handleMentalPulseTap()
                }) {
                    HStack(spacing: 4) {
                        if isGeneratingMental {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: showingMentalPulse ? "brain.head.profile.fill" : "brain.head.profile")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Mental Pulse")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(width: 95)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        showingMentalPulse ? Color.blue.opacity(0.25) : Color.indigo.opacity(0.25),
                                        showingMentalPulse ? Color.cyan.opacity(0.25) : Color.blue.opacity(0.25)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(showingMentalPulse ? Color.blue.opacity(0.3) : Color.indigo.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                }
                .disabled(isGeneratingMental)
                .buttonStyle(PlainButtonStyle())
                
                // Social Vibe Button
                Button(action: {
                    handleSocialVibeTap()
                }) {
                    HStack(spacing: 4) {
                        if isGeneratingSocial {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: showingSocialVibe ? "globe.americas.fill" : "globe.americas")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Social Vibe")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(width: 95)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        showingSocialVibe ? Color.orange.opacity(0.25) : Color.yellow.opacity(0.25),
                                        showingSocialVibe ? Color.red.opacity(0.25) : Color.orange.opacity(0.25)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(showingSocialVibe ? Color.orange.opacity(0.3) : Color.yellow.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                }
                .disabled(isGeneratingSocial)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            
            // Content Sections
            VStack(spacing: 16) {
                // AI Scoop Content
                if showingAIScoop {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("AI Scoop for \(contactName)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("Fresh")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Text(aiScoopContent)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.horizontal, 20)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
                
                // Mental Pulse Content
                if showingMentalPulse {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.blue)
                            Text("Mental Pulse for \(contactName)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                                Text("Live")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Text(mentalPulseContent)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.horizontal, 20)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
                
                // Social Vibe Content
                if showingSocialVibe {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "globe.americas")
                                .foregroundColor(.orange)
                            Text("Social Vibe for \(contactName)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 6, height: 6)
                                Text("Nearby")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Text(socialVibeContent)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.horizontal, 20)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
            }
        }
    }
    
    // MARK: - Button Actions
    
    private func handleAIScoopTap() {
        if showingAIScoop {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingAIScoop = false
            }
            return
        }
        
        // Hide other sections
        withAnimation(.easeInOut(duration: 0.2)) {
            showingMentalPulse = false
            showingSocialVibe = false
        }
        
        generateAIScoop()
    }
    
    private func handleMentalPulseTap() {
        if showingMentalPulse {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingMentalPulse = false
            }
            return
        }
        
        // Hide other sections
        withAnimation(.easeInOut(duration: 0.2)) {
            showingAIScoop = false
            showingSocialVibe = false
        }
        
        generateMentalPulse()
    }
    
    private func handleSocialVibeTap() {
        if showingSocialVibe {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingSocialVibe = false
            }
            return
        }
        
        // Hide other sections
        withAnimation(.easeInOut(duration: 0.2)) {
            showingAIScoop = false
            showingMentalPulse = false
        }
        
        generateSocialVibe()
    }
    
    // MARK: - Content Generation Functions
    
    private func generateAIScoop() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isGeneratingAI = true
        }
        
        // Simulate AI generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isGeneratingAI = false
                aiScoopContent = generateContactAIContent()
                showingAIScoop = true
            }
        }
    }
    
    private func generateMentalPulse() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isGeneratingMental = true
        }
        
        // Simulate mental pulse generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isGeneratingMental = false
                mentalPulseContent = generateContactMentalPulseContent()
                showingMentalPulse = true
            }
        }
    }
    
    private func generateSocialVibe() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isGeneratingSocial = true
        }
        
        // Simulate social vibe generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isGeneratingSocial = false
                socialVibeContent = generateContactSocialVibeContent()
                showingSocialVibe = true
            }
        }
    }
    
    // MARK: - Content Generation for Contact Context
    
    private func generateContactAIContent() -> String {
        guard let apiContact = analyzedContact, apiContact.isApiUser else {
            return ""
        }
        
        // Use real API data for AI content
        let behaviorFactors = apiContact.behaviorFactors.isEmpty ? "No behavior data available" : apiContact.behaviorFactors
        let healthFactors = apiContact.healthFactors.isEmpty ? "No health data available" : apiContact.healthFactors
        
        return "\(contactName ?? "Contact") analysis: \(behaviorFactors). Health indicators: \(healthFactors)"
    }
    
    private func generateContactMentalPulseContent() -> String {
        guard let apiContact = analyzedContact, apiContact.isApiUser else {
            return ""
        }
        
        // Use emotion profile data for mental pulse
        let emotionProfile = apiContact.emotionProfile.isEmpty ? "No emotion profile available" : apiContact.emotionProfile
        return "Mental state analysis: \(emotionProfile)"
    }
    
    private func generateContactSocialVibeContent() -> String {
        guard let apiContact = analyzedContact, apiContact.isApiUser else {
            return ""
        }
        
        // Combine location and emotion data for social vibe
        let location = apiContact.city.isEmpty || apiContact.city == "Location Unknown" ? "Unknown location" : apiContact.city
        let emoji = apiContact.emoji
        let emotionName = ContactProfileHelpers.emojiNameForID(Int(emoji) ?? 46)
        
        return "\(contactName ?? "Contact") is in \(location), feeling \(emotionName). Last updated: \(TimeAgo.text(from: apiContact.lastUpdated))"
    }
    
    // MARK: - Helper Functions for Contact Analysis
    
    private func extractHour(from timeString: String) -> Int {
        let components = timeString.components(separatedBy: " ")
        if let timeComponent = components.first {
            if let hour = Int(timeComponent) {
                let isPM = timeString.contains("PM")
                if isPM && hour != 12 {
                    return hour + 12
                } else if !isPM && hour == 12 {
                    return 0
                } else {
                    return hour
                }
            }
        }
        return 12
    }
    
    private func getContactCognitiveState(for hour: Int, mood: String) -> String {
        switch hour {
        case 6...9: return "Alert"
        case 10...14: return "Peak Performance"
        case 15...17: return "Focused"
        case 18...20: return "Relaxed"
        default: return "Restful"
        }
    }
    
    private func getContactStressLevel(for data: ContactTimeSlotData) -> String {
        switch data.heartRate {
        case 50...70: return "Very Low"
        case 71...80: return "Low"
        case 81...90: return "Moderate"
        default: return "Elevated"
        }
    }
    
    private func getContactMentalClarity(for data: ContactTimeSlotData) -> String {
        switch data.mood {
        case "thinking-face": return "Highly Focused"
        case "happy", "grinning": return "Optimistic"
        case "relieved": return "Clear & Calm"
        case "sleepy": return "Low Energy"
        default: return "Balanced"
        }
    }
    
    private func getContactEnergyLevel(for data: ContactTimeSlotData) -> String {
        let energyScore = data.steps + (data.activeEnergy * 10)
        switch energyScore {
        case 0...3000: return "Low"
        case 3001...6000: return "Moderate"
        case 6001...10000: return "High"
        default: return "Very High"
        }
    }
    
    private func getContactSocialEnergy(for hour: Int, mood: String) -> String {
        switch mood {
        case "happy", "grinning": return "High & Positive"
        case "thinking-face": return "Focused"
        case "relieved": return "Calm & Open"
        case "sleepy": return "Low"
        default: return "Balanced"
        }
    }
    
    private func getContactAvailability(for data: ContactTimeSlotData) -> String {
        switch data.location {
        case "Home": return "Highly Available"
        case "Office": return "Work Mode"
        case "Gym": return "Busy"
        case "Restaurant": return "Social Mode"
        default: return "Variable"
        }
    }
    
    private func getContactConnectionQuality(for data: ContactTimeSlotData) -> String {
        switch data.mood {
        case "happy", "grinning": return "Excellent"
        case "thinking-face", "relieved": return "Good"
        case "sleepy": return "Fair"
        default: return "Stable"
        }
    }
    
    private func getContactInteractionReadiness(for data: ContactTimeSlotData) -> String {
        switch data.location {
        case "Home": return "Perfect for deep conversation"
        case "Office": return "Brief check-ins work best"
        case "Gym": return "Quick messages only"
        case "Restaurant": return "Great for social connection"
        default: return "Flexible interaction timing"
        }
    }
}

// MARK: - Contact Dynamic Insights
struct ContactInsightsContext: View {
    let currentTimeSlotData: ContactTimeSlotData?
    let contactName: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Steps insight
            HStack(spacing: 8) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 14))
                    .foregroundColor(.green.opacity(0.8))
                
                Text(getContactStepsInsight())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            
            // Activity pattern insight
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.8))
                
                Text(getContactActivityInsight())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            
            // Social energy insight
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue.opacity(0.8))
                
                Text(getContactSocialInsight())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            
            // Location pattern insight
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange.opacity(0.8))
                
                Text(getContactLocationInsight())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func getContactStepsInsight() -> String {
        return ""
    }
    
    private func getContactActivityInsight() -> String {
        return ""
    }
    
    private func getContactSocialInsight() -> String {
        return ""
    }
    
    private func getContactLocationInsight() -> String {
        return ""
    }
}

// MARK: - Connection Resonance Result
struct ConnectionResonanceResult: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.wave.2")
                    .foregroundColor(.cyan)
                Text("Connection Resonance")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 6, height: 6)
                    Text("Live")
                        .font(.caption)
                        .foregroundColor(.cyan)
                        .fontWeight(.medium)
                }
            }
            
            Text("")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .padding(.horizontal, 20)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
    }
}

#Preview {
    ContactDetailWebPage(contactNumber: "", contactName: "John Doe")
}
