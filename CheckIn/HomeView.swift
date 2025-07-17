//

//  HomeView.swift
//  moodgpt
//
//  Created by Test on 5/27/25.
//

import SwiftUI
import HealthKit
import Combine
import CoreLocation

// MARK: - Data Models
struct TimeSlotData {
    let time: String
    let mood: String
    let description: String
    let isCurrent: Bool
    let steps: Int
    let activeEnergy: Int
    let heartRate: Int
    let analysis: String
    let location: String
    let weather: String
}

struct RefinedVital {
    let icon: String
    let value: String
    let color: Color
}

// MARK: - Header Row Component
struct HeaderRowView: View {
    let spotifyState: HomeView.SpotifyConnectionState
    let onSpotifyTap: () -> Void
    
    var body: some View {
        HStack {
            Text("CheckIn")
                .font(.system(size: 26, weight: .bold, design: .default))
                .foregroundColor(.white)
            Spacer()
            Button(action: onSpotifyTap) {
                HStack(spacing: 5) {
                    Image(systemName: iconName)
                        .foregroundColor(iconColor)
                        .font(.system(size: 13, weight: .medium))
                        .rotationEffect(rotationAngle)
                        .animation(rotationAnimation, value: spotifyState)
                    
                    Text(buttonText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(fillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(strokeColor, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var iconName: String {
        switch spotifyState {
        case .connected: return "music.note.list"
        case .connecting: return "arrow.triangle.2.circlepath"
        case .disconnected: return "music.note"
        }
    }
    
    private var iconColor: Color {
        switch spotifyState {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .white
        }
    }
    
    private var buttonText: String {
        switch spotifyState {
        case .connecting: return "Syncing..."
        case .connected: return "Spotify ✓"
        case .disconnected: return "Spotify"
        }
    }
    
    private var rotationAngle: Angle {
        spotifyState == .connecting ? .degrees(360) : .degrees(0)
    }
    
    private var rotationAnimation: Animation? {
        spotifyState == .connecting ? .linear(duration: 1).repeatForever(autoreverses: false) : .default
    }
    
    private var fillColor: Color {
        switch spotifyState {
        case .connected: return Color.green.opacity(0.2)
        case .connecting: return Color.yellow.opacity(0.2)
        case .disconnected: return Color.white.opacity(0.08)
        }
    }
    
    private var strokeColor: Color {
        switch spotifyState {
        case .connected: return Color.green.opacity(0.4)
        case .connecting: return Color.yellow.opacity(0.4)
        case .disconnected: return Color.clear
        }
    }
}

// MARK: - Refined Vitals Row
struct RefinedVitalsRow: View {
    @State private var selectedMetrics: Set<Int> = Set([0, 1, 2, 3, 4])
    @State private var showingCustomMoodFactors = false
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    // Dynamic vitals that update with real Apple Health data
    private var vitals: [RefinedVital] {
        [
            RefinedVital(
                icon: "figure.walk", 
                value: formatSteps(healthDataManager.lastHealthData?["steps_today"] as? Int), 
                color: .green
            ),
            RefinedVital(
                icon: "heart.fill", 
                value: formatHeartRate(healthDataManager.lastHealthData?["heart_rate_avg_today"] as? Int), 
                color: .red
            ),
            RefinedVital(
                icon: "bolt.fill", 
                value: formatEnergy(healthDataManager.lastHealthData?["active_calories_today"] as? Int), 
                color: .orange
            ),
            RefinedVital(
                icon: "location.fill", 
                value: formatLocation(), 
                color: .blue
            ),
            RefinedVital(
                icon: "bed.double.fill", 
                value: formatSleep(healthDataManager.lastHealthData?["sleep_hours_last_night"] as? Double), 
                color: .purple
            ),
            RefinedVital(
                icon: "figure.run", 
                value: formatExerciseMinutes(healthDataManager.lastHealthData?["exercise_minutes_today"] as? Int), 
                color: .orange
            ),
            RefinedVital(
                icon: "map.fill", 
                value: formatDistance(healthDataManager.lastHealthData?["distance_miles_today"] as? Double), 
                color: .cyan
            ),
            RefinedVital(
                icon: "music.note", 
                value: "0", 
                color: .indigo
            )
        ]
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(vitals.enumerated()), id: \.offset) { index, vital in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedMetrics.contains(index) {
                                if selectedMetrics.count > 3 {
                                    selectedMetrics.remove(index)
                                }
                            } else {
                                if selectedMetrics.count < 8 {
                                    selectedMetrics.insert(index)
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: vital.icon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(selectedMetrics.contains(index) ? vital.color : .white.opacity(0.6))
                            
                            Text(vital.value)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
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
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showingCustomMoodFactors) {
            CustomMoodFactorsSheet()
        }
    }
    
    // MARK: - Formatting Functions for Apple Health Data
    
    private func formatSteps(_ steps: Int?) -> String {
        guard let steps = steps, steps > 0 else { return "0" }
        if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
    
    private func formatHeartRate(_ heartRate: Int?) -> String {
        guard let heartRate = heartRate, heartRate > 0 else { return "0" }
        return "\(heartRate)"
    }
    
    private func formatEnergy(_ energy: Int?) -> String {
        guard let energy = energy, energy > 0 else { return "0" }
        if energy >= 1000 {
            return String(format: "%.1fk", Double(energy) / 1000.0)
        }
        return "\(energy)"
    }
    
    private func formatSleep(_ sleep: Double?) -> String {
        guard let sleep = sleep, sleep > 0 else { return "0h" }
        return String(format: "%.1fh", sleep)
    }
    
    private func formatExerciseMinutes(_ minutes: Int?) -> String {
        guard let minutes = minutes, minutes > 0 else { return "0m" }
        return "\(minutes)m"
    }
    
    private func formatDistance(_ distance: Double?) -> String {
        guard let distance = distance, distance > 0 else { return "0mi" }
        return String(format: "%.1fmi", distance)
    }
    
    private func formatLocation() -> String {
        return "Home" // Placeholder - you can integrate with LocationManager later
    }
}

// MARK: - Main Emotion Snapshot
struct MainEmotionSnapshot: View {
    let mood: String
    let description: String
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
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
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Refined Emotional Timeline
struct RefinedEmotionalTimeline: View {
    let timelineSlots: [(String, String, String, Bool, Bool)]
    let selectedIndex: Int
    let onSlotTap: (Int, String, String, String, Bool) -> Void
    @State private var showForecastMessage = false
    @State private var forecastMessageIndex: Int? = nil
    
    private func isPredicted(_ index: Int) -> Bool {
        guard index < timelineSlots.count else { return false }
        return timelineSlots[index].4
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Forecast")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            if timelineSlots.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cloud.heavyrain")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Fetching mood forecast")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Connecting to backdate APIs...")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(timelineSlots.enumerated()), id: \.offset) { index, slot in
                            let predicted = isPredicted(index)
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    onSlotTap(index, slot.0, slot.1, slot.2, slot.3)
                                    
                                    if predicted {
                                        forecastMessageIndex = index
                                        showForecastMessage = true
                                    }
                                }
                            }) {
                                VStack(spacing: 6) {
                                    HStack(spacing: 3) {
                                        Text(slot.0)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white.opacity(predicted ? 0.5 : 0.6))
                                        
                                        if predicted {
                                            Image(systemName: "crystal.ball")
                                                .font(.system(size: 8, weight: .medium))
                                                .foregroundColor(.blue.opacity(0.7))
                                        }
                                    }
                                    
                                    AnimatedEmoji(slot.1, size: 36, fallback: "neutral-face")
                                        .opacity(predicted ? 0.6 : 0.8)
                                        .scaleEffect(0.9)
                                    
                                    Text(predicted ? "Forecast" : slot.2)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.white.opacity(predicted ? 0.5 : 0.7))
                                        .lineLimit(1)
                                    
                                    if slot.3 {
                                        Circle()
                                            .fill(Color.white.opacity(0.8))
                                            .frame(width: 3, height: 3)
                                    } else {
                                        Circle()
                                            .fill(Color.clear)
                                            .frame(width: 3, height: 3)
                                    }
                                }
                                .frame(width: 55, height: 80)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedIndex == index ? Color.white.opacity(0.1) : Color.white.opacity(0.03))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Location Song Context
struct LocationSongContext: View {
    let currentTimeSlotData: TimeSlotData?
    @ObservedObject var emotionSnapshotService: EmotionSnapshotService
    
    var body: some View {
        VStack(spacing: 12) {
            if let snapshot = emotionSnapshotService.currentSnapshot, 
               let crispAnalyticsPoints = snapshot["crisp_analytics_points"] as? [String],
               !crispAnalyticsPoints.isEmpty {
                ForEach(Array(crispAnalyticsPoints.enumerated()), id: \.offset) { index, point in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue.opacity(0.8))
                        
                        Text(point)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 14))
                        .foregroundColor(.green.opacity(0.8))
                    
                    Text("Steps data not available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Minimal AI Scoop Button
struct MinimalAIScoopButton: View {
    @State private var isExpanded = false
    @ObservedObject var emotionSnapshotService: EmotionSnapshotService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Text("✨")
                        .font(.system(size: 16))
                    
                    Text("AI Scoop")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Analysis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(getAIScoopText())
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.03))
                .cornerRadius(8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private func getAIScoopText() -> String {
        // Get AI scoop from current snapshot
        if let snapshot = emotionSnapshotService.currentSnapshot,
           let aiScoop = snapshot["ai_scoop"] as? String,
           !aiScoop.isEmpty {
            return aiScoop
        }
        
        return "AI analysis not available - data is being processed"
    }
}

// MARK: - Emotion Detail Row
struct EmotionDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Horizontal Button Group
struct HorizontalButtonGroup: View {
    let currentTimeSlotData: TimeSlotData?
    @ObservedObject var emotionSnapshotService: EmotionSnapshotService
    @ObservedObject var healthDataManager: HealthDataManager
    let selectedTimelineEntry: EmotionalTimelineAPIEntry?
    let username: String
    @State private var showingAIScoop = false
    @State private var showingMentalPulse = false
    @State private var showingSocialVibe = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Button("AI Scoop") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingAIScoop.toggle()
                        showingMentalPulse = false
                        showingSocialVibe = false
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.25))
                .cornerRadius(8)
                .foregroundColor(.white)
                
                Button("Mental Pulse") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingMentalPulse.toggle()
                        showingAIScoop = false
                        showingSocialVibe = false
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.25))
                .cornerRadius(8)
                .foregroundColor(.white)
                
                Button("Social Vibe") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingSocialVibe.toggle()
                        showingAIScoop = false
                        showingMentalPulse = false
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.25))
                .cornerRadius(8)
                .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            
            if showingAIScoop {
                Text(getAIScoopText())
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
            }
            
            if showingMentalPulse {
                Text(getMentalPulseText())
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
            }
            
            if showingSocialVibe {
                Text(getSocialVibeText())
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Helper Methods to Get API Data
    
    private func getAIScoopText() -> String {
        print("🔍 AI SCOOP DEBUG: Getting AI scoop text...")
        
        // Try to get from selected timeline entry first
        if let timelineEntry = selectedTimelineEntry,
           !timelineEntry.ai_scoop.isEmpty {
            print("✅ AI SCOOP DEBUG: Found from timeline entry: \(timelineEntry.ai_scoop.prefix(50))...")
            return timelineEntry.ai_scoop
        }
        
        // Fallback to current snapshot
        if let snapshot = emotionSnapshotService.currentSnapshot,
           let aiScoop = snapshot["ai_scoop"] as? String,
           !aiScoop.isEmpty {
            print("✅ AI SCOOP DEBUG: Found from current snapshot: \(aiScoop.prefix(50))...")
            return aiScoop
        }
        
        print("❌ AI SCOOP DEBUG: No data found")
        print("   - Timeline entry exists: \(selectedTimelineEntry != nil)")
        print("   - Current snapshot exists: \(emotionSnapshotService.currentSnapshot != nil)")
        if let snapshot = emotionSnapshotService.currentSnapshot {
            print("   - Snapshot keys: \(snapshot.keys.sorted())")
            print("   - AI scoop value: \(snapshot["ai_scoop"] ?? "nil")")
        }
        return "AI analysis not available - try refreshing the page"
    }
    
    private func getMentalPulseText() -> String {
        print("🔍 MENTAL PULSE DEBUG: Getting mental pulse text...")
        
        // Try to get from selected timeline entry first
        if let timelineEntry = selectedTimelineEntry,
           !timelineEntry.description.isEmpty {
            print("✅ MENTAL PULSE DEBUG: Found from timeline entry: \(timelineEntry.description.prefix(50))...")
            return timelineEntry.description
        }
        
        // Fallback to current snapshot
        if let snapshot = emotionSnapshotService.currentSnapshot,
           let mentalPulse = snapshot["mental_pulse"] as? String,
           !mentalPulse.isEmpty {
            print("✅ MENTAL PULSE DEBUG: Found from current snapshot: \(mentalPulse.prefix(50))...")
            return mentalPulse
        }
        
        print("❌ MENTAL PULSE DEBUG: No data found")
        print("   - Timeline entry exists: \(selectedTimelineEntry != nil)")
        print("   - Current snapshot exists: \(emotionSnapshotService.currentSnapshot != nil)")
        if let snapshot = emotionSnapshotService.currentSnapshot {
            print("   - Snapshot keys: \(snapshot.keys.sorted())")
            print("   - Mental pulse value: \(snapshot["mental_pulse"] ?? "nil")")
        }
        return "Mental pulse data not available - try refreshing the page"
    }
    
    private func getSocialVibeText() -> String {
        print("🔍 SOCIAL VIBE DEBUG: Getting social vibe text...")
        
        // Try to get from selected timeline entry first
        if let timelineEntry = selectedTimelineEntry,
           !timelineEntry.social_vibe.isEmpty {
            print("✅ SOCIAL VIBE DEBUG: Found from timeline entry: \(timelineEntry.social_vibe.prefix(50))...")
            return timelineEntry.social_vibe
        }
        
        // Fallback to current snapshot
        if let snapshot = emotionSnapshotService.currentSnapshot,
           let socialVibe = snapshot["social_vibe"] as? String,
           !socialVibe.isEmpty {
            print("✅ SOCIAL VIBE DEBUG: Found from current snapshot: \(socialVibe.prefix(50))...")
            return socialVibe
        }
        
        print("❌ SOCIAL VIBE DEBUG: No data found")
        print("   - Timeline entry exists: \(selectedTimelineEntry != nil)")
        print("   - Current snapshot exists: \(emotionSnapshotService.currentSnapshot != nil)")
        if let snapshot = emotionSnapshotService.currentSnapshot {
            print("   - Snapshot keys: \(snapshot.keys.sorted())")
            print("   - Social vibe value: \(snapshot["social_vibe"] ?? "nil")")
        }
        return "Social vibe data not available - try refreshing the page"
    }
}

// MARK: - Theme Manager
enum AppTheme: String, CaseIterable {
    case dark = "Dark"
    case light = "Light"
    case multiColor = "Multi-Color"
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "currentTheme")
        }
    }
    
    @Published var showEmojisInBackground: Bool {
        didSet {
            UserDefaults.standard.set(showEmojisInBackground, forKey: "showEmojisInBackground")
        }
    }
    
    private var currentUserMood: String {
        UserDefaults.standard.string(forKey: "CurrentUserMood") ?? "😐"
    }
    
    private var currentUserMoodText: String {
        UserDefaults.standard.string(forKey: "CurrentUserMoodText") ?? "Neutral"
    }
    
    init() {
        let savedTheme = UserDefaults.standard.string(forKey: "currentTheme") ?? AppTheme.dark.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .dark
        self.showEmojisInBackground = UserDefaults.standard.bool(forKey: "showEmojisInBackground") != false // Default to true
        
        // Listen for emotion changes to refresh multi-color theme
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if self?.currentTheme == .multiColor {
                self?.objectWillChange.send()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Legacy support for existing isDarkMode property
    var isDarkMode: Bool {
        get { currentTheme == .dark }
        set { currentTheme = newValue ? .dark : .light }
    }
    
    // MARK: - Enhanced Background Colors with Premium Finishes
    var backgroundColor: Color {
        switch currentTheme {
        case .dark:
            return Color.black
        case .light:
            return Color(red: 0.98, green: 0.98, blue: 0.99) // Premium light background
        case .multiColor:
            return Color.clear // Will use gradient overlay
        }
    }
    
    var backgroundGradient: LinearGradient? {
        switch currentTheme {
        case .multiColor:
            return EmotionData.backgroundGradient(for: currentUserMoodText)
        default:
            return nil
        }
    }
    
    // MARK: - Enhanced Text Colors for Maximum Readability
    var primaryTextColor: Color {
        switch currentTheme {
        case .dark, .multiColor:
            return Color.white
        case .light:
            return Color(red: 0.08, green: 0.08, blue: 0.08) // Premium deep black
        }
    }
    
    var secondaryTextColor: Color {
        switch currentTheme {
        case .dark, .multiColor:
            return Color.white.opacity(0.85)
        case .light:
            return Color(red: 0.2, green: 0.2, blue: 0.2) // Enhanced contrast gray
        }
    }
    
    // MARK: - Premium Card Backgrounds with Enhanced Finishes
    var cardBackgroundColor: Color {
        switch currentTheme {
        case .dark:
            return Color.white.opacity(0.08) // Subtle dark cards
        case .light:
            return Color.white.opacity(0.98) // Premium white cards
        case .multiColor:
            return Color.black.opacity(0.45) // Enhanced readability overlay
        }
    }
    
    // MARK: - Enhanced Border System for Better Definition
    var borderColor: Color {
        switch currentTheme {
        case .dark:
            return Color.white.opacity(0.15) // Subtle dark borders
        case .light:
            return Color(red: 0.78, green: 0.8, blue: 0.82) // Premium light borders
        case .multiColor:
            return Color.white.opacity(0.4) // Visible multi-color borders
        }
    }
    
    // MARK: - Enhanced UI Component Colors
    var accentColor: Color {
        switch currentTheme {
        case .dark:
            return Color.white
        case .light:
            return Color.black
        case .multiColor:
            return Color.white
        }
    }
    
    var surfaceColor: Color {
        switch currentTheme {
        case .dark:
            return Color(red: 0.1, green: 0.1, blue: 0.1)
        case .light:
            return Color(red: 0.96, green: 0.97, blue: 0.98)
        case .multiColor:
            return Color.black.opacity(0.3)
        }
    }
    
    // MARK: - Enhanced Selection Colors for Better UX
    var selectionBackgroundColor: Color {
        switch currentTheme {
        case .dark:
            return Color.white.opacity(0.9)
        case .light:
            return Color.black.opacity(0.9)
        case .multiColor:
            return Color.white.opacity(0.85)
        }
    }
    
    var selectionTextColor: Color {
        switch currentTheme {
        case .dark:
            return Color.black
        case .light:
            return Color.white
        case .multiColor:
            return Color.black
        }
    }
    
    // MARK: - Premium Shadow and Elevation System
    var shadowColor: Color {
        switch currentTheme {
        case .dark:
            return Color.white.opacity(0.1)
        case .light:
            return Color.black.opacity(0.08)
        case .multiColor:
            return Color.black.opacity(0.2)
        }
    }
    
    var elevatedCardBackground: Color {
        switch currentTheme {
        case .dark:
            return Color.white.opacity(0.12)
        case .light:
            return Color.white
        case .multiColor:
            return Color.black.opacity(0.5)
        }
    }
    
    // MARK: - Enhanced Celebrity View Colors (Fixes Light Mode Readability)
    var celebrityCardBackground: Color {
        switch currentTheme {
        case .dark:
            return Color.white.opacity(0.1)
        case .light:
            return Color.white // Pure white for maximum contrast
        case .multiColor:
            return Color.black.opacity(0.6) // Enhanced opacity for readability
        }
    }
    
    var celebrityBorderColor: Color {
        switch currentTheme {
        case .dark:
            return Color.white.opacity(0.2)
        case .light:
            return Color(red: 0.75, green: 0.77, blue: 0.8) // Stronger borders for definition
        case .multiColor:
            return Color.white.opacity(0.5)
        }
    }
    
    // MARK: - Additional property for settings readability
    var settingsBackgroundColor: Color {
        switch currentTheme {
        case .dark:
            return Color.black
        case .light:
            return Color.white
        case .multiColor:
            return Color.black.opacity(0.6) // Semi-transparent black for readability
        }
    }
    
    // MARK: - Enhanced Methods for Premium Feel
    func refreshTheme() {
        if currentTheme == .multiColor {
            objectWillChange.send()
        }
    }
    
    // Get emotion-specific colors when in multi-color mode
    func getEmotionTextColor() -> Color {
        if currentTheme == .multiColor {
            return EmotionData.primaryTextColor(for: currentUserMoodText, theme: currentTheme)
        }
        return primaryTextColor
    }
    
    func getEmotionSecondaryTextColor() -> Color {
        if currentTheme == .multiColor {
            return EmotionData.secondaryTextColor(for: currentUserMoodText, theme: currentTheme)
        }
        return secondaryTextColor
    }
    
    func getEmotionCardBackground() -> Color {
        if currentTheme == .multiColor {
            return EmotionData.cardBackgroundColor(for: currentUserMoodText, theme: currentTheme)
        }
        return cardBackgroundColor
    }
    
    func getEmotionBorderColor() -> Color {
        if currentTheme == .multiColor {
            return EmotionData.borderColor(for: currentUserMoodText, theme: currentTheme)
        }
        return borderColor
    }
}

// MARK: - Loading Animation Components - Moved to CoolLoadingAnimations.swift

struct ShimmerEffect: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.3), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .scaleEffect(x: isAnimating ? 1 : 0, anchor: .leading)
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
            )
            .onAppear {
                isAnimating = true
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Data Models
// JournalEntry is now defined in MoodModels.swift

struct DateTab: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let date: Date
    let isToday: Bool
    let isCalendar: Bool
}

extension DateFormatter {
    func dayName(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Short day name (Mon, Tue, etc.)
        return formatter.string(from: date)
    }
}

struct HomeView: View {
    @State private var currentTime = Date()
    @State private var spotifyConnected: Bool = false
    @State private var spotifyState: SpotifyConnectionState = .disconnected
    @State private var spotifyTimer: Timer? = nil
    @State private var isContentLoaded = false

    
    // Computed property to get current mood text from API or fallback
    private var displayMoodText: String {
        // Use API main emoji_id directly
        if let snapshot = emotionSnapshotService.currentSnapshot {
            return (snapshot["mental_pulse"] as? String) ?? (snapshot["ai_scoop"] as? String) ?? "Getting your vibe..."
        }
        
        return UserDefaults.standard.string(forKey: "CurrentUserMoodText") ?? "Neutral"
    }
    @State private var selectedTimeSlotIndex: Int = 3 // Default to current time (middle slot)
    @State private var currentTimeSlotData: TimeSlotData? = nil
    @State private var selectedTimelineEntry: EmotionalTimelineAPIEntry? = nil
    
    enum SpotifyConnectionState {
        case disconnected, connecting, connected
    }
    
    // Removed date tab variables since we only show Today view
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var healthDataManager: HealthDataManager // Added missing connection
    @EnvironmentObject var emotionSnapshotService: EmotionSnapshotService
    
    @ObservedObject private var emotionManager = EmotionAnalysisManager.shared
    

    
    // Extract hour from time string (e.g., "11:12 PM" -> 23, "5:08 AM" -> 5)
    private func extractHour(from timeString: String) -> Int {
        if timeString.lowercased() == "now" {
            return Calendar.current.component(.hour, from: Date())
        }
        
        let timeComponents = timeString.components(separatedBy: " ")
        guard timeComponents.count >= 2 else { return 12 } // Default to noon if parsing fails
        
        let timeOnly = timeComponents[0] // "11:12"
        let amPm = timeComponents[1].lowercased() // "am" or "pm"
        
        let hourMinute = timeOnly.components(separatedBy: ":")
        guard let hourString = hourMinute.first, let hour = Int(hourString) else { return 12 }
        
        // Convert to 24-hour format
        if amPm == "pm" && hour != 12 {
            return hour + 12
        } else if amPm == "am" && hour == 12 {
            return 0
        } else {
            return hour
        }
    }

    // Helper function to extract the first word from zinger caption for display
    private func getFirstWordOfZinger(_ zingerCaption: String) -> String {
        let trimmedCaption = zingerCaption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCaption.isEmpty else { return "Neutral" }
        
        let words = trimmedCaption.components(separatedBy: .whitespacesAndNewlines)
        let firstWord = words.first?.trimmingCharacters(in: .punctuationCharacters) ?? "Neutral"
        
        // Ensure we return a meaningful word (not empty after punctuation removal)
        return firstWord.isEmpty ? "Neutral" : firstWord
    }

    // Helper function to get emotion display name from emotion ID
    private func getEmotionDisplayName(_ emotionId: Int) -> String {
        // Get the emoji name from the emotion ID
        let emojiName = EmojiMapper.getEmojiForID(emotionId) ?? "neutral-face"
        
        // Convert emoji name to display name using Celebrity helper
        let displayName = Celebrity.formatEmotionNameForDisplay(emojiName)
        
        print("🎭 EMOTION MAPPING DEBUG: ID \(emotionId) -> '\(emojiName)' -> '\(displayName)'")
        return displayName
    }

    // Helper structure for chronological sorting
    private struct TimelineEntry {
        let timestamp: Date
        let formattedTime: String
        let emoji: String
        let displayEmotion: String
        let isCurrent: Bool
        let isPrediction: Bool
        let originalTimestamp: String
        let emojiId: Int
        let zingerCaption: String
    }
    
    // Helper function to parse API timestamp to Date
    private func parseAPITimestamp(_ timestamp: String) -> Date? {
        let formatter = DateFormatter()
        
        // Try the exact API format first: "2025-07-07 22:47:24"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = formatter.date(from: timestamp) {
            return date
        }
        
        // Try with milliseconds: "2025-07-07 22:47:24.123"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        if let date = formatter.date(from: timestamp) {
            return date
        }
        
        // Try ISO 8601 format: "2025-07-07T22:47:24"
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: timestamp) {
            return date
        }
        
        // Try Unix timestamp parsing
        if let unixTimestamp = Double(timestamp) {
            return Date(timeIntervalSince1970: unixTimestamp)
        }
        
        print("❌ Failed to parse timestamp: '\(timestamp)'")
        return nil
    }

    // Timeline data: historical entries + current + predicted entries (from API)
    // NOW WITH PROPER CHRONOLOGICAL SORTING
    private var emotionalTimelineSlots: [(String, String, String, Bool, Bool)] {
        var allTimelineEntries: [TimelineEntry] = []
        
        print("🔍 Building chronologically sorted timeline from API data...")
        
        // Step 1: Collect all historical entries
        if let historicalTimeline = emotionSnapshotService.emotionalTimeline,
           let predictions = historicalTimeline["predictions"] as? [String: [String: Any]] {
            
            print("📊 Processing \(predictions.count) historical entries")
            
            for (timestamp, data) in predictions.sorted(by: { $0.key < $1.key }) {
                if let emojiId = data["emoji_id"] as? Int,
                   let zingerCaption = data["zinger_caption"] as? String,
                   let parsedDate = parseAPITimestamp(timestamp) {
                    
                    let emoji = EmojiMapper.getEmojiForID(emojiId) ?? "neutral-face"
                    let displayEmotion = getFirstWordOfZinger(zingerCaption)  // Use first word instead of emotion mapping
                    let formattedTime = formatAPITimeString(timestamp)
                    
                    print("🎭 TIMELINE EMOJI DEBUG - Historical entry:")
                    print("   - Timestamp: \(timestamp)")
                    print("   - Emotion ID: \(emojiId)")
                    print("   - Mapped emoji name: '\(emoji)'")
                    print("   - Zinger caption: '\(zingerCaption)'")
                    print("   - First word display: '\(displayEmotion)'")
                    print("   - Final display: \(formattedTime) [\(emoji)] \(displayEmotion)")
                    
                    let entry = TimelineEntry(
                        timestamp: parsedDate,
                        formattedTime: formattedTime,
                        emoji: emoji,
                        displayEmotion: displayEmotion,
                        isCurrent: false,
                        isPrediction: false,
                        originalTimestamp: timestamp,
                        emojiId: emojiId,
                        zingerCaption: zingerCaption
                    )
                    
                    allTimelineEntries.append(entry)
                }
            }
        }
        
        // Step 2: Add current snapshot entry
        if let currentSnapshot = emotionSnapshotService.currentSnapshot,
           let emojiId = currentSnapshot["emoji_id"] as? Int,
           let zingerCaption = currentSnapshot["zinger_caption"] as? String {
            
            let emoji = EmojiMapper.getEmojiForID(emojiId) ?? "neutral-face"
            let displayEmotion = getFirstWordOfZinger(zingerCaption)  // Use first word instead of emotion mapping
            let currentTime = Date()
            
            print("🎭 TIMELINE EMOJI DEBUG - Current snapshot:")
            print("   - Emotion ID: \(emojiId)")
            print("   - Mapped emoji name: '\(emoji)'")
            print("   - Zinger caption: '\(zingerCaption)'")
            print("   - First word display: '\(displayEmotion)'")
            print("   - Final display: Now [\(emoji)] \(displayEmotion)")
            
            let entry = TimelineEntry(
                timestamp: currentTime,
                formattedTime: "Now",
                emoji: emoji,
                displayEmotion: displayEmotion,
                isCurrent: true,
                isPrediction: false,
                originalTimestamp: "current",
                emojiId: emojiId,
                zingerCaption: zingerCaption
            )
            
            allTimelineEntries.append(entry)
        }
        
        // Step 3: Collect all prediction entries
        if let predictionData = emotionSnapshotService.predictionData,
           let predictions = predictionData["predictions"] as? [String: [String: Any]] {
            
            for (timestamp, data) in predictions.sorted(by: { $0.key < $1.key }) {
                if let emojiId = data["emoji_id"] as? Int,
                   let zingerCaption = data["zinger_caption"] as? String,
                   let parsedDate = parseAPITimestamp(timestamp) {
                    
                    let emoji = EmojiMapper.getEmojiForID(emojiId) ?? "neutral-face"
                    let displayEmotion = getFirstWordOfZinger(zingerCaption)  // Use first word instead of emotion mapping
                    let formattedTime = formatAPITimeString(timestamp)
                    
                    print("🎭 TIMELINE EMOJI DEBUG - Prediction entry:")
                    print("   - Timestamp: \(timestamp)")
                    print("   - Emotion ID: \(emojiId)")
                    print("   - Mapped emoji name: '\(emoji)'")
                    print("   - Zinger caption: '\(zingerCaption)'")
                    print("   - First word display: '\(displayEmotion)'")
                    print("   - Final display: \(formattedTime) [\(emoji)] \(displayEmotion)")
                    
                    let entry = TimelineEntry(
                        timestamp: parsedDate,
                        formattedTime: formattedTime,
                        emoji: emoji,
                        displayEmotion: displayEmotion,
                        isCurrent: false,
                        isPrediction: true,
                        originalTimestamp: timestamp,
                        emojiId: emojiId,
                        zingerCaption: zingerCaption
                    )
                    
                    allTimelineEntries.append(entry)
                }
            }
        }
        
        // Step 4: Sort all entries chronologically by timestamp
        let sortedEntries = allTimelineEntries.sorted { $0.timestamp < $1.timestamp }
        
        print("📊 Timeline complete: \(sortedEntries.count) total entries")
        
        // Convert to the timeline slots format
        let timelineSlots = sortedEntries.map { entry in
            print("🎭 FINAL TIMELINE SLOT DEBUG:")
            print("   - Time: \(entry.formattedTime)")
            print("   - Emoji: '\(entry.emoji)' (ID: \(entry.emojiId))")
            print("   - Display: '\(entry.displayEmotion)'")
            print("   - Will show: AnimatedEmoji('\(entry.emoji)', ...)")
            return (entry.formattedTime, entry.emoji, entry.displayEmotion, entry.isCurrent, entry.isPrediction)
        }
        
        return timelineSlots
    }
    
    // Format API timestamp to display format
    private func formatAPITimestamp(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // Format API timestamp string (e.g., "2025-07-02 16:26:47") to display format
    private func formatAPITimeString(_ timestamp: String) -> String {
        print("🕐 Parsing timestamp: '\(timestamp)'")
        
        let formatter = DateFormatter()
        
        // Try the exact API format first: "2025-07-07 22:47:24"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = formatter.date(from: timestamp) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"  // Fixed: Added :mm to show minutes
            let result = timeFormatter.string(from: date)
            print("✅ Successfully parsed: '\(timestamp)' -> '\(result)'")
            return result
        }
        
        // Try with milliseconds: "2025-07-07 22:47:24.123"
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        if let date = formatter.date(from: timestamp) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"  // Fixed: Added :mm to show minutes
            let result = timeFormatter.string(from: date)
            print("✅ Successfully parsed with ms: '\(timestamp)' -> '\(result)'")
            return result
        }
        
        // Try ISO 8601 format: "2025-07-07T22:47:24"
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter.date(from: timestamp) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"  // Fixed: Added :mm to show minutes
            let result = timeFormatter.string(from: date)
            print("✅ Successfully parsed ISO: '\(timestamp)' -> '\(result)'")
            return result
        }
        
        // Try Unix timestamp parsing
        if let unixTimestamp = Double(timestamp) {
            let date = Date(timeIntervalSince1970: unixTimestamp)
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"  // Fixed: Added :mm to show minutes
            let result = timeFormatter.string(from: date)
            print("✅ Successfully parsed Unix: '\(timestamp)' -> '\(result)'")
            return result
        }
        
        // Manual parsing for space-separated format
        let components = timestamp.components(separatedBy: " ")
        if components.count >= 2 {
            let timeComponent = components[1] // Get "22:47:24" part
            let hourMinuteComponents = timeComponent.components(separatedBy: ":")
            if let hourString = hourMinuteComponents.first, 
               let minuteString = hourMinuteComponents.dropFirst().first,
               let hour = Int(hourString), 
               let minute = Int(minuteString) {
                let adjustedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
                let period = hour < 12 ? "AM" : "PM"
                let result = "\(adjustedHour):\(String(format: "%02d", minute)) \(period)"  // Fixed: Added minutes formatting
                print("✅ Manual parsing: '\(timestamp)' -> '\(result)'")
                return result
            }
        }
        
        print("❌ Failed to parse timestamp: '\(timestamp)' - using fallback")
        return "Now" // Fallback
    }
    
    // Reduced frequency timer for better performance
    private let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    // Removed dateTabsData since we only show Today view
    
    // Removed yesterday's data since we only show Today view
    
    // Personal timeline is now generated from API data only via emotionalTimelineSlots
    
    private var displayName: String {
        if !authManager.currentName.isEmpty {
            return authManager.currentName
        } else {
            return authManager.currentUsername
        }
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
    
    var body: some View {
        ZStack {
            // Base background
            themeManager.backgroundColor.ignoresSafeArea()
            
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
            
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    timelineSection
                    mainEmojiSection
                    aiScoopSection
                    contextSection
                    bottomSpacing
                }
            }
        }
        .recordSession(screenName: "HomeView")
        .onAppear {
            initializeCurrentTimeSlot()
            loadUserEmotionData()
            
            // ENHANCED: Immediate Apple Health integration
            print("🍎 HomeView appeared - requesting Apple Health permissions and data")
            
            // Force immediate health data fetch
            DispatchQueue.main.async {
                print("🍎 Triggering immediate health data request...")
                healthDataManager.requestPermissionsAndFetchData()
                
                // Also trigger a direct fetch if already authorized
                if healthDataManager.isAuthorized {
                    print("🍎 Already authorized - fetching data directly...")
                    DispatchQueue.global(qos: .background).async {
                        healthDataManager.fetchEssentialHealthData()
                    }
                }
            }
            
            // ENHANCED: Aggressive mood forecast API fetching for real data
            let username = getCurrentUsername()
            print("🚀 Starting comprehensive mood forecast API calls...")
            print("   - AuthManager username: '\(authManager.currentUsername)'")
            print("   - LoggedInUsername: '\(UserDefaults.standard.string(forKey: "LoggedInUsername") ?? "nil")'")
            print("   - GuestUsername: '\(UserDefaults.standard.string(forKey: "GuestUsername") ?? "nil")'")
            print("   - Final username: '\(username)'")
            
            if !username.isEmpty {
                print("✅ Username available - calling all 3 APIs for mood forecast...")
                print("🔄 FORCING FRESH API CALLS - no cached data")
                
                // FORCE FRESH API CALLS - Clear all cached data and get real API responses
                Task {
                    print("📡 Starting FORCED fresh API call sequence...")
                    
                    // Use the new force refresh method to clear cache and get fresh data
                    await emotionSnapshotService.forceRefreshAllData(username: username)
                    
                    print("🎯 Force refresh completed - checking final data...")
                    
                    // Debug final state and force UI refresh
                    DispatchQueue.main.async {
                        print("📊 FINAL DATA CHECK AFTER FORCE REFRESH:")
                        print("   - currentSnapshot: \(emotionSnapshotService.currentSnapshot != nil)")
                        print("   - emotionalTimeline: \(emotionSnapshotService.emotionalTimeline != nil)")
                        print("   - predictionData: \(emotionSnapshotService.predictionData != nil)")
                        
                        // Force timeline refresh by calling emotionalTimelineSlots again
                        print("🔄 Forcing timeline slots refresh...")
                        let finalSlots = emotionalTimelineSlots
                        print("🔄 Final timeline slots count: \(finalSlots.count)")
                        for (index, slot) in finalSlots.enumerated() {
                            print("     [\(index)] \(slot.0) - \(slot.1) - \(slot.2) (current: \(slot.3), prediction: \(slot.4))")
                        }
                        
                        // FIXED: Force view refresh after API data comes in
                        print("🔄 Triggering view refresh after fresh API data...")
                        self.updateSelectedTimelineEntry()
                    }
                }
                
                // Also run the manual test to compare
                testBackdateAPI()
            } else {
                print("❌ No username available - cannot call mood forecast APIs")
                print("   This means user is not logged in or guest mode not set up properly")
            }
            
            // Fetch user analysis data for AI Scoop and other features
            healthDataManager.fetchUserAnalysis()
            
            // Request health permissions for enhanced metrics
            let healthKitManager = HealthKitManager()
            healthKitManager.requestAuthorization()
            
            // ENHANCED: Add a delayed health data fetch to ensure it happens
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                print("🍎 Delayed health data fetch (3 seconds after HomeView appeared)")
                if healthDataManager.isAuthorized {
                    DispatchQueue.global(qos: .background).async {
                        healthDataManager.fetchEssentialHealthData()
                    }
                } else {
                    print("⚠️ Health data not authorized yet - requesting permissions again")
                    healthDataManager.requestPermissionsAndFetchData()
                }
            }
        }
        // FIXED: Listen for changes in emotion data and refresh timeline
        .onReceive(emotionSnapshotService.$currentSnapshot) { _ in
            print("🔄 Current snapshot updated - refreshing timeline...")
            DispatchQueue.main.async {
                let updatedSlots = emotionalTimelineSlots
                print("🔄 Updated timeline slots: \(updatedSlots.count)")
                self.updateSelectedTimelineEntry()
            }
        }
        .onReceive(emotionSnapshotService.$emotionalTimeline) { _ in
            print("🔄 Emotional timeline updated - refreshing timeline...")
            DispatchQueue.main.async {
                let updatedSlots = emotionalTimelineSlots
                print("🔄 Updated timeline slots: \(updatedSlots.count)")
                self.updateSelectedTimelineEntry()
            }
        }
        .onReceive(emotionSnapshotService.$predictionData) { _ in
            print("🔄 Prediction data updated - refreshing timeline...")
            DispatchQueue.main.async {
                let updatedSlots = emotionalTimelineSlots
                print("🔄 Updated timeline slots: \(updatedSlots.count)")
                self.updateSelectedTimelineEntry()
            }
        }
    }
    
    // MARK: - Body Components
    private var headerSection: some View {
        VStack(spacing: 12) {
        HeaderRowView(
            spotifyState: spotifyState,
            onSpotifyTap: toggleSpotifyConnection
        )
    
            // Add the Apple Health header stats below the Spotify header
            NewsHeaderView()
        }
    }
    
    private var timelineSection: some View {
        RefinedEmotionalTimeline(
            timelineSlots: emotionalTimelineSlots.map { ($0.0, $0.1, $0.2, $0.3, $0.4) },
            selectedIndex: selectedTimeSlotIndex,
            onSlotTap: handleTimelineSlotTap
        )
    }
    
    private var mainEmojiSection: some View {
        MainEmotionSnapshot(
            mood: currentTimeSlotData?.mood ?? getValidatedCurrentMood(),
            description: generateEmotionDescription()
        )
    }
    
    private var aiScoopSection: some View {
        HorizontalButtonGroup(
            currentTimeSlotData: currentTimeSlotData,
            emotionSnapshotService: emotionSnapshotService,
            healthDataManager: healthDataManager,
            selectedTimelineEntry: selectedTimelineEntry,
            username: getCurrentUsername()
        )
    }
    
    private var contextSection: some View {
        LocationSongContext(
            currentTimeSlotData: currentTimeSlotData,
            emotionSnapshotService: emotionSnapshotService
        )
    }
    
    private var bottomSpacing: some View {
        Spacer(minLength: 100)
    }
    
    private func initializeCurrentTimeSlot() {
        if currentTimeSlotData == nil {
            let currentSlots = emotionalTimelineSlots
            
            // FIXED: Find the current slot by looking for isCurrent flag instead of assuming index 3
            var currentSlotIndex = 0
            for (index, slot) in currentSlots.enumerated() {
                if slot.3 { // isCurrent flag
                    currentSlotIndex = index
                    break
                }
            }
            
            // Ensure we don't go out of bounds
            if currentSlotIndex < currentSlots.count {
                let currentSlot = currentSlots[currentSlotIndex]
                selectedTimeSlotIndex = currentSlotIndex
                currentTimeSlotData = generateTimeSlotData(
                    timeString: currentSlot.0,
                    emojiName: currentSlot.1,
                    description: currentSlot.2,
                    isCurrent: currentSlot.3,
                    isPrediction: currentSlot.4,
                    timelineEntry: nil
                )
                print("🎯 Initialized current time slot at index \(currentSlotIndex): \(currentSlot.0)")
            } else {
                print("⚠️ Could not find current time slot, using first available slot")
                if !currentSlots.isEmpty {
                    selectedTimeSlotIndex = 0
                    let firstSlot = currentSlots[0]
                    currentTimeSlotData = generateTimeSlotData(
                        timeString: firstSlot.0,
                        emojiName: firstSlot.1,
                        description: firstSlot.2,
                        isCurrent: firstSlot.3,
                        isPrediction: firstSlot.4,
                        timelineEntry: nil
                    )
                }
            }
        }
    }
    
    private func loadUserEmotionData() {
        // Get username from session
        let username = getCurrentUsername()
        
        guard !username.isEmpty else {
            return
        }
        
        Task {
            await emotionSnapshotService.analyzeUser(username: username)
            await emotionSnapshotService.fetchEmotionalTimeline(username: username)
            await emotionSnapshotService.fetchPredictions(username: username)
        }
    }
    
    private func getCurrentUsername() -> String {
        print("🔍 USERNAME DEBUG: Getting current username...")
        
        // Try to get logged in username first
        let loggedInUsername = UserDefaults.standard.string(forKey: "LoggedInUsername") ?? ""
        print("   - LoggedInUsername: '\(loggedInUsername)'")
        
        if !loggedInUsername.isEmpty {
            print("✅ USERNAME DEBUG: Using LoggedInUsername: '\(loggedInUsername)'")
            return loggedInUsername
        }
        
        // Try to get guest username
        let guestUsername = UserDefaults.standard.string(forKey: "GuestUsername") ?? ""
        print("   - GuestUsername: '\(guestUsername)'")
        
        if !guestUsername.isEmpty {
            print("✅ USERNAME DEBUG: Using GuestUsername: '\(guestUsername)'")
            return guestUsername
        }
        
        // Fallback to authManager username
        let authManagerUsername = authManager.currentUsername
        print("   - AuthManager username: '\(authManagerUsername)'")
        
        if !authManagerUsername.isEmpty {
            print("✅ USERNAME DEBUG: Using AuthManager username: '\(authManagerUsername)'")
            return authManagerUsername
        }
        
        print("❌ USERNAME DEBUG: No username found! All sources are empty")
        print("🧪 USERNAME DEBUG: Using 'testuser' as fallback for API testing")
        return "testuser"  // Temporary fallback for testing
    }
    
    private func generateEmotionDescription() -> String {
        // Use selected timeline entry if available
        if let timelineEntry = selectedTimelineEntry {
            return timelineEntry.zinger_caption
        }
        
        // Fallback to current snapshot
        if let snapshot = emotionSnapshotService.currentSnapshot {
            return snapshot["zinger_caption"] as? String ?? "Balanced emotional state"
        }
        
        // Use the selected time slot's description if available, otherwise current mood
        if let timeSlotData = currentTimeSlotData {
            return "\(timeSlotData.description) — \(getContextualDescription(for: timeSlotData))"
        } else {
            let currentMoodText = UserDefaults.standard.string(forKey: "CurrentUserMoodText") ?? "Neutral"
            return "\(currentMoodText) — probably from low movement & music calm-down"
        }
    }
    
    private func getContextualDescription(for timeSlotData: TimeSlotData) -> String {
        let hour = extractHour(from: timeSlotData.time)
        
        switch hour {
        case 6...8: return "morning energy building up"
        case 9...11: return "focused work mode activated"  
        case 12...14: return "peak energy and social engagement"
        case 15...17: return "afternoon flow state"
        case 18...20: return "winding down naturally"
        case 21...23: return "relaxation mode setting in"
        default: return "deep rest and recovery time"
        }
    }
    
    func toggleSpotifyConnection() {
        switch spotifyState {
        case .disconnected:
            connectSpotify()
        case .connecting:
            // Cancel connection attempt
            spotifyState = .disconnected
        case .connected:
            // Disconnect manually
            disconnectSpotify()
        }
    }
    
    func connectSpotify() {
        spotifyState = .connecting
        
        SpotifyAuthManager.shared.configureSpotify { result in
            switch result {
            case .success(let isAuthenticated):
                if isAuthenticated {
                    self.spotifyState = .connected
                    self.spotifyConnected = true
                    loadSpotifyRecentyPlayed()
                    
                    // Auto-disconnect after 5 minutes
                    self.spotifyTimer?.invalidate()
                    self.spotifyTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: false) { _ in
                        self.disconnectSpotify()
                    }
                } else {
                    self.spotifyState = .disconnected
                }
            case .failure(let error):
                print("Spotify authentication failed: \(error.localizedDescription)")
                self.spotifyState = .disconnected
            }
        }
    }
    
    func disconnectSpotify() {
        spotifyState = .disconnected
        spotifyConnected = false
        spotifyTimer?.invalidate()
        spotifyTimer = nil
    }
    
    func loadSpotifyRecentyPlayed() {
        SpotifyAuthManager.shared.fetchRecentlyPlayedList { result in
            switch result {
            case .success(let tracks):
                savesSpotifyData(tracks: tracks.map({$0.track}))
            case .failure(let error):
                // Handle Spotify API error
                print("Failed to load Spotify recently played: \(error.localizedDescription)")
                // Could show user-friendly error message here if needed
            }
        }
    }
    
    func savesSpotifyData(tracks: [SPTTrack]) {
        var username = UserDefaults.standard.string(forKey: "LoggedInUsername")
        if username == nil {
            username = UserDefaults.standard.string(forKey: "GuestUsername")
        }
        guard let _ = URL.init(string: "https://user-login-register-d6yw.onrender.com/add_spotify_data"), let username else { return }
        
        // TODO: Implement Spotify data saving directly or use a dedicated service

    }
    
    // Helper methods for emoji timeline
    private func formatTimeString(hour: Int) -> String {
        let adjustedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        let period = hour < 12 ? "AM" : "PM"
        return "\(adjustedHour) \(period)"
    }
    

    
    // Format prediction timestamp (e.g., "2025-07-02 23:25:03") to display format
    private func formatPredictionTimeString(_ timestamp: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        
        if let date = formatter.date(from: timestamp) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"  // Fixed: Added :mm to show minutes
            
            // Check if it's today, tomorrow, or future
            let calendar = Calendar.current
            let now = Date()
            
            if calendar.isDate(date, inSameDayAs: now) {
                // Same day - just show time
                return timeFormatter.string(from: date)
            } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: now) ?? now) {
                // Tomorrow - show "Tom" + time
                return "Tom \(timeFormatter.string(from: date))"
            } else {
                // Future days - show day abbreviation + time
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "E"
                let dayName = dayFormatter.string(from: date)
                return "\(dayName) \(timeFormatter.string(from: date))"
            }
        }
        
        // Fallback to original string if parsing fails
        return timestamp
    }
    

    
    private func getValidatedCurrentMood() -> String {
        // Use selected timeline entry if available
        if let timelineEntry = selectedTimelineEntry {
            let emojiName = ContactProfileHelpers.emojiNameForID(timelineEntry.emoji_id)
            return emojiName
        }
        
        // Fallback to current snapshot
        if let snapshot = emotionSnapshotService.currentSnapshot {
            let emojiId = snapshot["emoji_id"] as? Int ?? 46
            let emojiName = ContactProfileHelpers.emojiNameForID(emojiId)
            return emojiName
        }
        
        // Fallback to neutral if no API data
        return "neutral-face"
    }
    
    private func handleTimelineSlotTap(index: Int, time: String, mood: String, description: String, isCurrent: Bool) {
        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Update selected index
        selectedTimeSlotIndex = index
        
        // Get the timeline slots to access full data
        let slots = emotionalTimelineSlots
        guard index < slots.count else { return }
        
        let (timeString, emojiName, desc, isCurrentSlot, isPrediction) = slots[index]
        
                    
        
        // Generate comprehensive time slot data based on API source
        if isPrediction {
            // For predictions, use prediction API data
            if let predictionData = emotionSnapshotService.predictionData,
               let predictions = predictionData["predictions"] as? [String: [String: Any]],
               let firstPrediction = predictions.values.first {
                selectedTimelineEntry = EmotionalTimelineAPIEntry(
                    timestamp: Date().timeIntervalSince1970 + Double((index - 3) * 3600), // Future time
                    emoji_id: firstPrediction["emoji_id"] as? Int ?? 46,
                    description: (firstPrediction["mental_pulse"] as? String) ?? desc,
                    ai_scoop: firstPrediction["ai_scoop"] as? String ?? "",
                    social_vibe: firstPrediction["social_vibe"] as? String ?? "",
                    zinger_caption: firstPrediction["zinger_caption"] as? String ?? "Getting your vibe..."
                )
            } else {
                selectedTimelineEntry = nil
            }
        } else if isCurrentSlot {
            // For current time, use current snapshot data
            if let snapshot = emotionSnapshotService.currentSnapshot {
                selectedTimelineEntry = EmotionalTimelineAPIEntry(
                    timestamp: Date().timeIntervalSince1970,
                    emoji_id: snapshot["emoji_id"] as? Int ?? 46,
                    description: (snapshot["mental_pulse"] as? String) ?? desc,
                    ai_scoop: snapshot["ai_scoop"] as? String ?? "",
                    social_vibe: (snapshot["social_vibe"] as? String) ?? "Current environment assessment.",
                    zinger_caption: snapshot["zinger_caption"] as? String ?? "Getting your vibe..."
                )
            } else {
                selectedTimelineEntry = nil
            }
        } else {
            // For historical data, use historical timeline data
            if let timeline = emotionSnapshotService.emotionalTimeline,
               let predictions = timeline["predictions"] as? [String: [String: Any]],
               !predictions.isEmpty {
                // Convert predictions dictionary to array and get by index
                let predictionValues = Array(predictions.values)
                if index < predictionValues.count {
                    let prediction = predictionValues[index]
                    selectedTimelineEntry = EmotionalTimelineAPIEntry(
                        timestamp: Date().timeIntervalSince1970 - Double((3 - index) * 3600),
                        emoji_id: prediction["emoji_id"] as? Int ?? 46,
                        description: (prediction["mental_pulse"] as? String) ?? (prediction["ai_scoop"] as? String) ?? "Analysis pending",
                        ai_scoop: prediction["ai_scoop"] as? String ?? "",
                        social_vibe: prediction["social_vibe"] as? String ?? "",
                        zinger_caption: prediction["zinger_caption"] as? String ?? "Getting your vibe..."
                    )
                } else {
                    selectedTimelineEntry = nil
                }
            } else {
                selectedTimelineEntry = nil
            }
        }
        
        // Update the current time slot data for display
        currentTimeSlotData = generateTimeSlotData(
            timeString: timeString,
            emojiName: emojiName,
            description: desc,
            isCurrent: isCurrentSlot,
            isPrediction: isPrediction,
            timelineEntry: selectedTimelineEntry
        )
        

    }
    
    // Generate time slot data from API responses only
    private func generateTimeSlotData(
        timeString: String,
        emojiName: String,
        description: String,
        isCurrent: Bool,
        isPrediction: Bool,
        timelineEntry: EmotionalTimelineAPIEntry?
    ) -> TimeSlotData {
        
        // Use API data when available, otherwise use minimal defaults
        let steps = timelineEntry?.additionalData?["steps"] as? Int ?? 0
        let calories = timelineEntry?.additionalData?["calories"] as? Int ?? 0
        let heartRate = timelineEntry?.additionalData?["heartRate"] as? Int ?? 0
        
        return TimeSlotData(
            time: timeString,
            mood: emojiName,
            description: description,
            isCurrent: isCurrent,
            steps: steps,
            activeEnergy: calories,
            heartRate: heartRate,
            analysis: timelineEntry?.ai_scoop ?? "Analysis not available",
            location: timelineEntry?.additionalData?["location"] as? String ?? "",
            weather: timelineEntry?.additionalData?["weather"] as? String ?? ""
        )
    }
    
    // Update the selected timeline entry when timeline data changes
    private func updateSelectedTimelineEntry() {
        guard selectedTimeSlotIndex >= 0 && selectedTimeSlotIndex < emotionalTimelineSlots.count else { return }
        
        let slots = emotionalTimelineSlots
        let (timeString, emojiName, description, isCurrent, isPrediction) = slots[selectedTimeSlotIndex]
        
        // Re-generate data for the selected time slot
        currentTimeSlotData = generateTimeSlotData(
            timeString: timeString,
            emojiName: emojiName,
            description: description,
            isCurrent: isCurrent,
            isPrediction: isPrediction,
            timelineEntry: selectedTimelineEntry
        )
    }
    
    // Removed helper methods for date tabs since we only show Today view
    
    // MARK: - Manual API Test (for debugging)
    
    private func testBackdateAPI() {
        print("🧪 MANUAL API TEST: Calling get_last_emotional_data directly...")
        
        let username = getCurrentUsername()
        print("🧪 Using username: '\(username)'")
        
        guard !username.isEmpty else {
            print("❌ MANUAL TEST FAILED: Username is empty")
            print("   - Check if user is logged in or guest mode is set up")
            print("   - LoggedInUsername: '\(UserDefaults.standard.string(forKey: "LoggedInUsername") ?? "nil")'")
            print("   - GuestUsername: '\(UserDefaults.standard.string(forKey: "GuestUsername") ?? "nil")'")
            print("   - AuthManager username: '\(authManager.currentUsername)'")
            return
        }
        
        Task {
            do {
                guard let url = URL(string: "https://django-api-test-rubo.onrender.com/api/emotional_timeline/get_last_emotional_data") else {
                    print("❌ MANUAL TEST: Invalid URL")
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let requestBody = ["username": username]
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                
                print("🧪 Making API request to: \(url)")
                print("🧪 Request body: \(requestBody)")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("🧪 HTTP Status: \(httpResponse.statusCode)")
                }
                
                print("🧪 Response data size: \(data.count) bytes")
                
                guard let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("❌ MANUAL TEST: Failed to parse JSON response")
                    return
                }
                
                print("🧪 RAW API RESPONSE:")
                print("   - Top-level keys: \(responseJSON.keys.sorted())")
                print("   - Username in response: \(responseJSON["username"] ?? "nil")")
                
                if let predictions = responseJSON["predictions"] as? [String: [String: Any]] {
                    print("✅ FOUND PREDICTIONS: \(predictions.count) entries")
                    
                    for (timestamp, data) in predictions.sorted(by: { $0.key < $1.key }) {
                        print("🧪 Entry: \(timestamp)")
                        print("   - emoji_id: \(data["emoji_id"] ?? "nil")")
                        print("   - zinger_caption: \(data["zinger_caption"] ?? "nil")")
                        print("   - All keys: \(data.keys.sorted())")
                        
                        // Test parsing this specific entry
                        if let emojiId = data["emoji_id"] as? Int,
                           let zingerCaption = data["zinger_caption"] as? String {
                            let formattedTime = formatAPITimeString(timestamp)
                            let emoji = EmojiMapper.getEmojiForID(emojiId) ?? "😐"
                            print("   ✅ Parsed: \(formattedTime) - \(emoji) - '\(zingerCaption)'")
                        } else {
                            print("   ❌ Failed to parse this entry")
                        }
                        print("   ---")
                    }
                    
                    print("🧪 CONCLUSION:")
                    print("   - API returned \(predictions.count) backdate entries")
                    print("   - This is what should appear in the mood forecast")
                    
                } else {
                    print("❌ NO PREDICTIONS FOUND in API response")
                    print("   - Predictions key exists: \(responseJSON["predictions"] != nil)")
                    print("   - Predictions type: \(type(of: responseJSON["predictions"]))")
                }
                
            } catch {
                print("❌ MANUAL TEST: Network error: \(error)")
            }
        }
    }
    
    // MARK: - Real API Testing (No Hardcoded Data)
}

// Remove old TodayView and related components since we've redesigned the interface
// The new sleek interface is now directly in the main HomeView body

// MARK: - Supporting Functions for Timeline
extension HomeView {
    // These functions are now handled by the main generateTimeSlotData function
}

// MARK: - Time Specific Header View
struct TimeSpecificHeaderView: View {
    let timeSlot: TimeSlotData
    
    var body: some View {
        // Simple header view with basic metrics
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CapsuleMetricItem(
                    icon: "figure.walk", 
                    value: formatSteps(timeSlot.steps), 
                    color: .green
                )
                
                CapsuleMetricItem(
                    icon: "heart.fill", 
                    value: "\(timeSlot.heartRate)", 
                    color: .red
                )
                
                CapsuleMetricItem(
                    icon: "bolt.fill", 
                    value: "\(timeSlot.activeEnergy)", 
                    color: .orange
                )
                
                CapsuleMetricItem(
                    icon: "location.fill", 
                    value: timeSlot.location, 
                    color: .blue
                )
                
                CapsuleMetricItem(
                    icon: "cloud.sun.fill", 
                    value: timeSlot.weather, 
                    color: .yellow
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
}



// MARK: - Simple Bullet Point Component
struct SimpleBulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text("•")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Simple Analysis Section Component
struct SimpleAnalysisSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text(content)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Capsule Metric Item (Spotify-style capsules)
struct CapsuleMetricItem: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 12, weight: .medium))
            
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - News Header View
struct NewsHeaderView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var locationTracker: LocationTrackingManager
    @State private var isRefreshing = false
    @State private var lastRefreshTime = Date()
    
    var body: some View {
        VStack(spacing: 8) {
            // Enhanced status indicator with more information
            if isRefreshing {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Syncing Apple Health data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            } else if healthDataManager.isAuthorized {
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Tap to enable Apple Health")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
                .onTapGesture {
                    healthDataManager.requestPermissionsAndFetchData()
                }
            }
            
        // Slidable bar with individual capsules
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                    // Steps from Apple Health
                    CapsuleMetricItem(
                        icon: "figure.walk", 
                        value: formatSteps(healthDataManager.lastHealthData?["steps_today"] as? Int),
                        color: .green
                    )
                    
                    // Heart Rate from Apple Health
                    CapsuleMetricItem(
                        icon: "heart.fill", 
                        value: formatHeartRate(healthDataManager.lastHealthData?["heart_rate_avg_today"] as? Int),
                        color: .red
                    )
                    
                    // Active Energy from Apple Health
                    CapsuleMetricItem(
                        icon: "bolt.fill", 
                        value: formatEnergy(healthDataManager.lastHealthData?["active_calories_today"] as? Int),
                        color: .orange
                    )
                    
                    // Exercise Minutes from Apple Health
                    CapsuleMetricItem(
                        icon: "music.note", 
                        value: formatExerciseMinutes(healthDataManager.lastHealthData?["exercise_minutes_today"] as? Int),
                        color: .purple
                    )
                    
                    // Current Location
                    CapsuleMetricItem(
                        icon: "location.fill", 
                        value: getCurrentLocationText(),
                        color: .blue
                    )
            }
            .padding(.horizontal, 20)
                .onTapGesture {
                    // Enhanced tap to refresh with better feedback
                    refreshHealthData()
                }
            }
            .onAppear {
                // Enhanced refresh when view appears + debug logging
                print("🍎 NewsHeaderView appeared - checking health data...")
                logCurrentHealthData()
                refreshHealthDataOnAppear()
            }
            .refreshable {
                // Enhanced pull to refresh functionality
                await performPullToRefresh()
            }
            // Listen for health data changes
            .onReceive(healthDataManager.$lastHealthData) { newData in
                // Update refresh time when data changes
                lastRefreshTime = Date()
                print("🍎 NewsHeaderView received health data update:")
                logCurrentHealthData()
            }
        }
    }
    
    // MARK: - Enhanced Refresh Methods
    
    func refreshHealthData() {
        guard healthDataManager.isAuthorized && !isRefreshing else {
            if !healthDataManager.isAuthorized {
                healthDataManager.requestPermissionsAndFetchData()
            }
            return
        }
        
        withAnimation {
            isRefreshing = true
        }
        
        print("🍎 Manual header stats refresh initiated - fetching today's latest data")
        DispatchQueue.global(qos: .background).async {
            // Use the new method that gets only today's data
            healthDataManager.refreshTodaysHeaderStats()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isRefreshing = false
                }
            }
        }
    }
    
    func refreshHealthDataOnAppear() {
        guard healthDataManager.isAuthorized else { return }
        
        // Only refresh if it's been more than 2 minutes since last refresh
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshTime)
        if timeSinceLastRefresh > 120 {
            withAnimation {
                isRefreshing = true
            }
            
            print("🍎 Auto-refresh on view appear - fetching today's latest data")
            DispatchQueue.global(qos: .background).async {
                // Use the new method that gets only today's data
                healthDataManager.refreshTodaysHeaderStats()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        isRefreshing = false
                    }
                }
            }
        }
    }
    
    func performPullToRefresh() async {
        await MainActor.run {
            isRefreshing = true
        }
        
        // Perform refresh on background thread with today's data only
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                // Use the new method that gets only today's data
                self.healthDataManager.refreshTodaysHeaderStats()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    isRefreshing = false
                    continuation.resume()
                }
            }
        }
    }
    
    // MARK: - Apple Health Data Formatting Functions
    
    private func formatSteps(_ steps: Int?) -> String {
        guard let steps = steps, steps > 0 else { return "0" }
        if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }
    
    private func formatHeartRate(_ heartRate: Int?) -> String {
        guard let heartRate = heartRate, heartRate > 0 else { return "--" }
        return "\(heartRate)"
    }
    
    private func formatEnergy(_ energy: Int?) -> String {
        guard let energy = energy, energy > 0 else { return "0" }
        if energy >= 1000 {
            return String(format: "%.1fk", Double(energy) / 1000.0)
        }
        return "\(energy)"
    }
    
    private func formatExerciseMinutes(_ minutes: Int?) -> String {
        guard let minutes = minutes, minutes > 0 else { return "0m" }
        return "\(minutes)m"
    }
    
    private func formatDistance(_ distance: Double?) -> String {
        guard let distance = distance, distance > 0 else { return "0.0" }
        return String(format: "%.1f", distance)
    }
    
    private func formatSleep(_ hours: Double?) -> String {
        guard let hours = hours, hours > 0 else { return "0h" }
        return String(format: "%.1fh", hours)
    }
    
    private func getCurrentLocationText() -> String {
        // Simplified location text - can be enhanced later with actual location data
        return "Location"
    }
    
    // MARK: - Debug Logging
    
    private func logCurrentHealthData() {
        guard let healthData = healthDataManager.lastHealthData else {
            print("❌ No health data available in HealthDataManager")
            return
        }
        
        print("🍎 Current health data in HealthDataManager:")
        print("   - steps_today: \(healthData["steps_today"] ?? "nil")")
        print("   - heart_rate_avg_today: \(healthData["heart_rate_avg_today"] ?? "nil")")
        print("   - active_calories_today: \(healthData["active_calories_today"] ?? "nil")")
        print("   - exercise_minutes_today: \(healthData["exercise_minutes_today"] ?? "nil")")
        print("   - distance_miles_today: \(healthData["distance_miles_today"] ?? "nil")")
        print("   - sleep_hours_last_night: \(healthData["sleep_hours_last_night"] ?? "nil")")
        print("   - Total keys: \(healthData.keys.count)")
        print("   - All keys: \(Array(healthData.keys).sorted())")
        
        // Test the formatting functions with current data
        let steps = healthData["steps_today"] as? Int
        let heartRate = healthData["heart_rate_avg_today"] as? Int
        let calories = healthData["active_calories_today"] as? Int
        let exerciseMinutes = healthData["exercise_minutes_today"] as? Int
        
        print("🍎 Formatted values:")
        print("   - Steps: \(formatSteps(steps))")
        print("   - Heart Rate: \(formatHeartRate(heartRate))")
        print("   - Calories: \(formatEnergy(calories))")
        print("   - Exercise: \(formatExerciseMinutes(exerciseMinutes))")
    }
}

// MARK: - Missing View Components (removed duplicates)

// MARK: - Helper Functions for Formatting Health Data
func formatSteps(_ steps: Int?) -> String {
    guard let steps = steps, steps > 0 else { return "0" }
    if steps >= 1000 {
        return String(format: "%.1fK", Double(steps) / 1000.0)
    }
    return "\(steps)"
}

func formatHeartRate(_ heartRate: Int?) -> String {
    guard let heartRate = heartRate, heartRate > 0 else { return "--" }
    return "\(heartRate)"
}

func formatEnergy(_ energy: Int?) -> String {
    guard let energy = energy, energy > 0 else { return "0" }
    return "\(energy)"
}

func formatExerciseMinutes(_ minutes: Int?) -> String {
    guard let minutes = minutes, minutes > 0 else { return "0m" }
    return "\(minutes)m"
}

func formatDistance(_ distance: Double?) -> String {
    guard let distance = distance, distance > 0 else { return "0mi" }
    return String(format: "%.1fmi", distance)
}

func formatSleep(_ sleepHours: Double?) -> String {
    guard let sleepHours = sleepHours, sleepHours > 0 else { return "0h" }
    return String(format: "%.1fh", sleepHours)
}

func getCurrentLocationText() -> String {
    return "Location"
}

// MARK: - Missing View Components (removed duplicates)

// MARK: - Data Models
struct NewsItem {
    let icon: String
    let title: String
    let value: String
    let trend: Trend
    let trendValue: String
    
    enum Trend {
        case up, down, neutral
    }
}

// Moved to top of file



// MARK: - Calendar View
struct CalendarView: View {
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    private var monthDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let lastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end) else {
            return []
        }
        
        let dateInterval = DateInterval(start: firstWeek.start, end: lastWeek.end)
        return calendar.generateDays(inside: dateInterval)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Calendar")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(themeManager.primaryTextColor)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Month navigation
                HStack {
                    Button(action: { changeMonth(-1) }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                    
                    Spacer()
                    
                    Text(monthFormatter.string(from: currentMonth))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Spacer()
                    
                    Button(action: { changeMonth(1) }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                }
                .padding(.horizontal, 20)
                
                // Calendar grid
                VStack(spacing: 8) {
                    // Weekday headers
                    HStack {
                        ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Calendar days
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(monthDays, id: \.self) { date in
                            Button(action: {
                                selectedDate = date
                                onDateSelected(date)
                            }) {
                                VStack(spacing: 4) {
                                    Text("\(calendar.component(.day, from: date))")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(
                                            calendar.isDate(date, inSameDayAs: selectedDate) ? .white :
                                            calendar.isDate(date, inSameDayAs: Date()) ? themeManager.primaryTextColor :
                                            calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) ? themeManager.primaryTextColor : themeManager.secondaryTextColor.opacity(0.5)
                                        )
                                    
                                    // Mood indicator dot (sample)
                                    Circle()
                                        .fill(getMoodColor(for: date))
                                        .frame(width: 6, height: 6)
                                        .opacity(calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) ? 1 : 0)
                                }
                                .frame(width: 80, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            calendar.isDate(date, inSameDayAs: selectedDate) ? themeManager.primaryTextColor :
                                            calendar.isDate(date, inSameDayAs: Date()) ? themeManager.cardBackgroundColor.opacity(0.3) :
                                            Color.clear
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Bottom spacing
                Spacer(minLength: 100)
            }
        }
    }
    
    private func changeMonth(_ value: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
                currentMonth = newMonth
            }
        }
    }
    
    private func getMoodColor(for date: Date) -> Color {
        // Sample mood colors - in a real app, this would be based on actual data
        let colors: [Color] = [.green, .blue, .orange, .purple, .pink]
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        return colors[dayOfYear % colors.count]
    }
}



// MARK: - Calendar Extension
// generateDays function is now defined in CalendarTabView.swift





#Preview {
    HomeView()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
}

// MARK: - Enhanced UI Components

// Enhanced Bullet Point with Icons and Colors
struct EnhancedBulletPoint: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
            
            Spacer()
        }
    }
}

// Prediction Row for Mood Forecast
struct PredictionRow: View {
    let time: String
    let emoji: String
    let prediction: String
    let confidence: Int
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Time and Emoji
            VStack(spacing: 4) {
                Text(time)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(emoji)
                    .font(.system(size: 24))
            }
            .frame(width: 60)
            
            // Prediction Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(prediction)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(confidence)%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// Recommendation Row for Smart Suggestions
struct RecommendationRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let timing: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .cornerRadius(12)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(timing)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// Minimalist Vitals Row
struct MinimalistVitalsRow: View {
    @State private var selectedVital: Int? = nil
    
    private let vitals = [
        VitalStat(icon: "figure.walk", value: "12,547", trend: .up, change: "+1,234"),
        VitalStat(icon: "heart.fill", value: "72", trend: .down, change: "-3"),
        VitalStat(icon: "bolt.fill", value: "487", trend: .up, change: "+45"),
        VitalStat(icon: "music.note", value: "23", trend: .up, change: "+8"),
        VitalStat(icon: "location.fill", value: "5", trend: .neutral, change: "0")
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(vitals.enumerated()), id: \.offset) { index, vital in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedVital = selectedVital == index ? nil : index
                        }
                    }) {
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: vital.icon)
                                    .font(.system(size: 16, weight: .medium)) // 15-20% bigger
                                    .foregroundColor(.white)
                                
                                Text(vital.value)
                                    .font(.system(size: 15, weight: .bold)) // 15-20% bigger
                                    .foregroundColor(.white)
                                
                                // Trend arrow
                                Image(systemName: vital.trend.arrow)
                                    .font(.system(size: 12))
                                    .foregroundColor(vital.trend.color)
                            }
                            
                            Text(vital.change)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedVital == index ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedVital == index ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                                        .shadow(color: selectedVital == index ? .white.opacity(0.2) : .clear, radius: 4)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// Vital Stat Model
struct VitalStat {
    let icon: String
    let value: String
    let trend: Trend
    let change: String
    
    enum Trend {
        case up, down, neutral
        
        var arrow: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
    }
}

// MARK: - Custom Mood Factors Sheet (Placeholder)
struct CustomMoodFactorsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Custom Mood Factors")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This feature will allow you to add custom factors that affect your mood.")
                                .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                    Spacer()
            }
            .padding()
            .navigationTitle("Mood Factors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Array Extension for Safe Access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

