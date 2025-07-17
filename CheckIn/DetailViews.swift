//
//  DetailViews.swift
//  moodgpt
//
//  Created by Test on 5/27/25.
//

import SwiftUI
import MapKit

// MARK: - City Detail View
struct CityDetailView: View {
    let cityName: String
    let currentMood: String
    let percentage: Int
    
    var body: some View {
        ZStack {
            EmotionData.backgroundGradient(for: currentMood)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        AnimatedEmoji("😊", size: 100, fallback: "😊")
                        
                        Text("New York City")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Manhattan • 57th Street • Happy")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button("Current Location") {
                            // Current location action
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    .padding(.top, 40)
                    
                    // Mood Prediction Analysis
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.white)
                            Text("Mood Prediction Analysis")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Text("Based on analysis of social media posts, news articles, and community sentiment in Manhattan, we predict the mood will be Happy during the day period.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    
                    // Key Themes
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.white)
                            Text("Key Themes Driving This Mood")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 15) {
                            ThemeCard(
                                icon: "building.2.fill",
                                title: "City Energy",
                                posts: 156,
                                sentiment: "positive, vibrant",
                                tags: ["business district", "cultural events", "city life"]
                            )
                            
                            ThemeCard(
                                icon: "person.3.fill",
                                title: "Social Activity",
                                posts: 89,
                                sentiment: "connected, social",
                                tags: ["meetups", "restaurants", "entertainment"]
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Additional Insights
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.white)
                            Text("Manhattan Insights")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 15) {
                            InsightRow(
                                icon: "chart.pie.fill",
                                title: "Confidence Level",
                                value: "92% based on local data"
                            )
                            
                            InsightRow(
                                icon: "location.fill",
                                title: "Area Focus",
                                value: "57th Street corridor shows highest positivity"
                            )
                            
                            InsightRow(
                                icon: "person.3.fill",
                                title: "Data Sources",
                                value: "324 local posts analyzed for this prediction"
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("NYC Mood Analysis")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Map Location Detail View
struct MapLocationDetailView: View {
    let location: MoodLocation
    let locationName: String
    
    var body: some View {
        ZStack {
            EmotionData.backgroundGradient(for: location.mood)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 15) {
                        AnimatedEmoji(location.mood, size: 120, fallback: location.mood)
                        
                        Text(locationName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Mood: \(location.moodText)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 40)
                    
                    // Mood Details
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.white)
                            Text("Location Mood Analysis")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Text("This area is showing a \(location.moodText.lowercased()) mood. Based on local social media activity and community sentiment, people here are feeling \(moodDescription(for: location.mood)).")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    
                    // Contributors
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.white)
                            Text("Recent Mood Contributors")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(0..<3) { _ in
                                HStack {
                                    AnimatedEmoji(location.mood, size: 30, fallback: location.mood)
                                    
                                    VStack(alignment: .leading) {
                                        Text(randomName())
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("\(Int.random(in: 1...30)) minutes ago")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func moodDescription(for mood: String) -> String {
        switch mood {
        case "😊", "😄": return "positive and upbeat"
        case "😢", "😔": return "somewhat melancholic or reflective"
        case "😡", "😠": return "frustrated or intense"
        case "😮", "😲": return "surprised or intrigued"
        case "😐", "😑": return "neutral or contemplative"
        case "🤔": return "thoughtful and pondering"
        case "😏": return "confident and cool"
        case "😴": return "tired or relaxed"
        case "🥳": return "celebratory and excited"
        case "😌": return "calm and peaceful"
        case "😤": return "determined or slightly frustrated"
        default: return "varied emotions"
        }
    }
    
    private func randomName() -> String {
        let names = ["Alex M.", "Sarah L.", "Mike R.", "Emma K.", "John D.", "Lisa P.", "David W.", "Kate S."]
        return names.randomElement() ?? "Anonymous"
    }
}

// MARK: - Mood Timeline Detail View
struct MoodTimelineDetailView: View {
    let timelineItem: MoodTimelineItem
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            EmotionData.backgroundGradient(for: timelineItem.mood)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 20) {
                        AnimatedEmoji(timelineItem.mood, size: 120, fallback: timelineItem.mood)
                        
                        Text(timelineItem.time)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("NYC Mood at \(timelineItem.time)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Mood intensity meter
                        HStack(spacing: 20) {
                            VStack {
                                Text("Intensity")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(Int.random(in: 70...95))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            VStack {
                                Text("Confidence")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(Int.random(in: 80...98))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            VStack {
                                Text("Spread")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(Int.random(in: 60...90))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(15)
                    }
                    .padding(.top, 40)
                    
                    // Tab selector
                    HStack(spacing: 0) {
                        ForEach(["Overview", "Demographics", "Locations", "Insights"], id: \.self) { tab in
                            let index = ["Overview", "Demographics", "Locations", "Insights"].firstIndex(of: tab) ?? 0
                            Button(action: { selectedTab = index }) {
                                Text(tab)
                                    .font(.caption)
                                    .fontWeight(selectedTab == index ? .bold : .medium)
                                    .foregroundColor(selectedTab == index ? .white : .white.opacity(0.6))
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedTab == index ? Color.white.opacity(0.2) : Color.clear)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Content based on selected tab
                    Group {
                        switch selectedTab {
                        case 0: overviewSection
                        case 1: demographicsSection
                        case 2: locationsSection
                        case 3: insightsSection
                        default: overviewSection
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("NYC \(timelineItem.time) Mood")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Overview Section
    var overviewSection: some View {
        VStack(spacing: 20) {
            // Mood Description
            VStack(spacing: 20) {
                Text("Mood Analysis")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 15) {
                    Text(timelineItem.description)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("The city's energy at \(timelineItem.time) reflects a \(moodIntensity) throughout Manhattan.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(15)
                }
            }
            .padding(.horizontal)
            
            // Key Metrics Grid
            VStack(alignment: .leading, spacing: 15) {
                Text("Key Metrics")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    StatCard(title: "Active Users", value: "\(Int.random(in: 50...200))", icon: "person.3.fill")
                    StatCard(title: "Mood Score", value: String(format: "%.1f", Double.random(in: 6.0...9.5)), icon: "heart.fill")
                    StatCard(title: "Check-ins", value: "\(Int.random(in: 20...80))", icon: "location.fill")
                    StatCard(title: "Trend", value: trendText, icon: "chart.line.uptrend.xyaxis")
                    StatCard(title: "Social Shares", value: "\(Int.random(in: 100...500))", icon: "square.and.arrow.up")
                    StatCard(title: "Reactions", value: "\(Int.random(in: 200...800))", icon: "hand.thumbsup.fill")
                }
            }
            .padding(.horizontal)
            
            // Weather Impact
            VStack(alignment: .leading, spacing: 10) {
                Text("Environmental Factors")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: weatherIcon)
                            .font(.title2)
                        Text("Weather Impact: \(weatherDescription)")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int.random(in: 60...85))%")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.title2)
                        Text("Time of Day Factor")
                            .font(.subheadline)
                        Spacer()
                        Text("\(timeOfDayFactor)%")
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .font(.title2)
                        Text("Day of Week Impact")
                            .font(.subheadline)
                        Spacer()
                        Text("\(dayOfWeekImpact)%")
                            .fontWeight(.bold)
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Demographics Section
    var demographicsSection: some View {
        VStack(spacing: 20) {
            Text("Demographic Breakdown")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Age Groups
            VStack(alignment: .leading, spacing: 10) {
                Text("Age Distribution")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(ageGroups, id: \.0) { group in
                    HStack {
                        Text(group.0)
                            .font(.subheadline)
                        Spacer()
                        ProgressView(value: group.1 / 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .frame(width: 150)
                        Text("\(Int(group.1))%")
                            .font(.caption)
                            .frame(width: 40)
                    }
                    .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
            
            // Gender Distribution
            HStack(spacing: 20) {
                VStack {
                    Text("Gender Split")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 30) {
                        VStack {
                            Image(systemName: "person.fill")
                                .font(.title)
                            Text("\(Int.random(in: 45...55))%")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Male")
                                .font(.caption)
                        }
                        
                        VStack {
                            Image(systemName: "person.fill")
                                .font(.title)
                            Text("\(Int.random(in: 45...55))%")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Female")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
            }
            
            // Occupation Categories
            VStack(alignment: .leading, spacing: 10) {
                Text("Top Occupations")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(occupations, id: \.0) { occupation in
                    HStack {
                        Text(occupation.0)
                            .font(.subheadline)
                        Spacer()
                        Text("\(occupation.1)%")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Locations Section
    var locationsSection: some View {
        VStack(spacing: 20) {
            Text("Geographic Distribution")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Borough breakdown
            VStack(alignment: .leading, spacing: 10) {
                Text("By Borough")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(boroughData, id: \.0) { borough in
                    HStack {
                        Text(borough.0)
                            .font(.subheadline)
                        Spacer()
                        HStack(spacing: 5) {
                            ForEach(0..<5) { i in
                                Image(systemName: i < borough.2 ? "star.fill" : "star")
                                    .font(.caption)
                            }
                        }
                        Text("\(borough.1)%")
                            .font(.caption)
                            .frame(width: 40)
                    }
                    .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
            
            // Popular Venues
            VStack(alignment: .leading, spacing: 10) {
                Text("Trending Locations")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(trendingVenues, id: \.self) { venue in
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                        Text(venue)
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Insights Section
    var insightsSection: some View {
        VStack(spacing: 20) {
            Text("AI Insights")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Predictions
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "brain")
                        .font(.title2)
                    Text("Mood Predictions")
                        .font(.headline)
                }
                .foregroundColor(.white)
                
                Text("Based on current patterns, the mood is expected to \(predictionTrend) over the next 2 hours with \(Int.random(in: 75...95))% confidence.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                
                HStack {
                    Text("Next Hour:")
                        .font(.caption)
                    AnimatedEmoji(nextHourMood, size: 25, fallback: nextHourMood)
                    Spacer()
                    Text("In 3 Hours:")
                        .font(.caption)
                    AnimatedEmoji(threeHourMood, size: 25, fallback: threeHourMood)
                }
                .foregroundColor(.white)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
            
            // Contributing Factors
            VStack(alignment: .leading, spacing: 10) {
                Text("Contributing Factors")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(contributingFactors, id: \.0) { factor in
                    HStack {
                        Image(systemName: factor.2)
                        Text(factor.0)
                            .font(.subheadline)
                        Spacer()
                        Text("\(factor.1)% impact")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
            
            // Recommendations
            VStack(alignment: .leading, spacing: 10) {
                Text("Recommendations")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(recommendations, id: \.self) { recommendation in
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text(recommendation)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Properties
    private var moodIntensity: String {
        switch timelineItem.description.lowercased() {
        case "happy", "excited": return "energetic and positive atmosphere"
        case "calm", "peaceful": return "relaxed and content vibe"
        case "sleepy", "tired": return "quiet and restful ambiance"
        default: return "balanced and steady mood"
        }
    }
    
    private var trendText: String {
                    let trends = ["Rising", "Falling", "Stable", "Peaking", "Dipping", "Volatile"]
        return trends.randomElement() ?? "→ Stable"
    }
    
    private var weatherIcon: String {
        ["sun.max.fill", "cloud.sun.fill", "cloud.fill", "cloud.rain.fill"].randomElement() ?? "sun.max.fill"
    }
    
    private var weatherDescription: String {
        ["Sunny boost", "Partly cloudy neutral", "Overcast dampening", "Rainy blues"].randomElement() ?? "Clear"
    }
    
    private var timeOfDayFactor: Int {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6...9: return Int.random(in: 70...85)
        case 10...16: return Int.random(in: 80...95)
        case 17...22: return Int.random(in: 75...90)
        default: return Int.random(in: 60...75)
        }
    }
    
    private var dayOfWeekImpact: Int {
        return 0
    }
    
    private var ageGroups: [(String, Double)] {
        []
    }
    
    private var occupations: [(String, Int)] {
        []
    }
    
    private var boroughData: [(String, Int, Int)] {
        []
    }
    
    private var trendingVenues: [String] {
        []
    }
    
    private var predictionTrend: String {
        "No data available"
    }
    
    private var nextHourMood: String {
        ""
    }
    
    private var threeHourMood: String {
        ""
    }
    
    private var contributingFactors: [(String, Int, String)] {
        []
    }
    
    private var recommendations: [String] {
        []
    }
}

// MARK: - Emotion Intensity Detail View
struct EmotionIntensityDetailView: View {
    let contact: Contact
    @State private var showingChatOverlay = false
    @State private var replyContext: ReplyContext?
    
    var intensityMetrics: [(String, String, String)] {
        [
            ("Current Level", ContactDetailHelpers.generateIntensityPercentage(for: contact), "Based on recent interactions and mood patterns"),
            ("Baseline Average", "67%", "Historical 30-day emotional baseline"),
            ("Peak Today", "94%", "Highest emotional engagement observed"),
            ("Recovery Rate", "85%", "How quickly emotions stabilize"),
            ("Volatility Index", "23%", "Emotional fluctuation frequency"),
            ("Social Amplification", "78%", "How social interactions affect intensity"),
            ("Stress Resilience", "91%", "Ability to maintain composure under pressure"),
            ("Energy Correlation", "89%", "How physical energy impacts emotional state")
        ]
    }
    
    var body: some View {
        ZStack {
            EmotionData.backgroundGradient(for: contact.moodText)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 15) {
                        AnimatedEmoji(contact.mood, size: 80, fallback: contact.mood)
                        
                        Text("Emotion Intensity Analysis")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("for \(contact.name)")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 20)
                    
                    // Main Intensity Display
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Current Intensity")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(ContactDetailHelpers.generateIntensityPercentage(for: contact))
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "thermometer")
                                .font(.system(size: 40))
                                .foregroundColor(ContactDetailHelpers.intensityColor(for: contact))
                        }
                        
                        ProgressView(value: Double(ContactDetailHelpers.generateIntensityValue(for: contact)) / 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: ContactDetailHelpers.intensityColor(for: contact)))
                            .scaleEffect(x: 1, y: 4, anchor: .center)
                        
                        Button(action: {
                            replyContext = ReplyContext(type: .analysis, content: "emotion intensity", emoji: "😊")
                            showingChatOverlay = true
                        }) {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("Discuss Intensity Patterns")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Detailed Metrics
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Detailed Metrics")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ForEach(Array(intensityMetrics.enumerated()), id: \.offset) { index, metric in
                            Button(action: {
                                replyContext = ReplyContext(type: .analysis, content: metric.0, emoji: "😊")
                                showingChatOverlay = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(metric.0)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Text(metric.2)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Text(metric.1)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(15)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
            
            // Chat overlay
            if showingChatOverlay {
                FullScreenChatOverlay(
                    recipientName: contact.name,
                    replyContext: replyContext,
                    isShowing: $showingChatOverlay
                )
                .zIndex(1)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Mood Triggers Detail View
struct MoodTriggersDetailView: View {
    let contact: Contact
    @State private var showingChatOverlay = false
    @State private var replyContext: ReplyContext?
    
    var triggerData: [(String, String, String, String)] {
        [
            ("Market Volatility", "High Impact", "87%", "Significant emotional response to market changes"),
            ("Team Performance", "Medium Impact", "65%", "Mood correlates with team success metrics"),
            ("Strategic Decisions", "High Impact", "92%", "Major decisions create emotional investment"),
            ("Client Interactions", "Medium Impact", "71%", "Positive/negative client feedback affects mood"),
            ("Work-Life Balance", "Low Impact", "34%", "Generally maintains emotional equilibrium"),
            ("Industry News", "Medium Impact", "58%", "Sector developments influence emotional state"),
            ("Personal Goals", "High Impact", "89%", "Progress toward goals significantly affects mood"),
            ("Social Recognition", "Medium Impact", "63%", "Appreciation and acknowledgment matter")
        ]
    }
    
    var body: some View {
        ZStack {
            EmotionData.backgroundGradient(for: contact.moodText)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 15) {
                        Image(systemName: "target")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("Mood Triggers & Influences")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("for \(contact.name)")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 20)
                    
                    // Analysis Method
                    VStack(spacing: 15) {
                        Text("Analysis Methodology")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Correlation analysis of mood changes with external events, communication patterns, and behavioral indicators over 6 months of data.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            replyContext = ReplyContext(type: .analysis, content: "mood triggers methodology", emoji: "😊")
                            showingChatOverlay = true
                        }) {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("Discuss Analysis Method")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Trigger Analysis
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Impact Analysis")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ForEach(Array(triggerData.enumerated()), id: \.offset) { index, trigger in
                            Button(action: {
                                replyContext = ReplyContext(type: .analysis, content: trigger.0, emoji: "😊")
                                showingChatOverlay = true
                            }) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text(trigger.0)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text(trigger.2)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(impactColor(for: trigger.1))
                                    }
                                    
                                    HStack {
                                        Text(trigger.1)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(impactColor(for: trigger.1))
                                        
                                        Spacer()
                                    }
                                    
                                    Text(trigger.3)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    ProgressView(value: Double(trigger.2.replacingOccurrences(of: "%", with: "")) ?? 0 / 100)
                                        .progressViewStyle(LinearProgressViewStyle(tint: impactColor(for: trigger.1)))
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(15)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
            
            // Chat overlay
            if showingChatOverlay {
                FullScreenChatOverlay(
                    recipientName: contact.name,
                    replyContext: replyContext,
                    isShowing: $showingChatOverlay
                )
                .zIndex(1)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func impactColor(for impact: String) -> Color {
        switch impact {
        case "High Impact": return .red
        case "Medium Impact": return .orange
        case "Low Impact": return .green
        default: return .white
        }
    }
}

// MARK: - Supporting Components
struct ThemeCard: View {
    let icon: String
    let title: String
    let posts: Int
    let sentiment: String
    let tags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(posts)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().stroke(Color.white, lineWidth: 2))
            }
            
            Text("\(posts) posts • \(sentiment)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.title2)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

// MARK: - Personal Emotion Detail View
struct PersonalEmotionDetailView: View {
    let currentMood: String
    let moodText: String
    
    @ObservedObject private var emotionManager = EmotionAnalysisManager.shared
    
    // Personal timeline removed - use only API data
    private var personalTimeline: [EmotionalTimelineItem] {
        return []
    }
    
    var body: some View {
        ZStack {
            EmotionData.backgroundGradient(for: currentMood)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header with user's current emotion - more compact
                    VStack(spacing: 15) {
                        AnimatedEmoji(currentMood, size: 100, fallback: currentMood)
                        
                        Text(moodText)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Your Current Emotion")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Last updated 2 minutes ago")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)
                    
                    // 24-Hour Emotional Timeline - moved up to fill space
                    VStack(alignment: .leading, spacing: 15) {
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
                            HStack(spacing: 15) {
                                ForEach(personalTimeline, id: \.time) { item in
                                    VStack(spacing: 8) {
                                        Text(item.time)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        AnimatedEmoji(item.mood, size: 30, fallback: item.mood)
                                        
                                        Text(item.description)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        if item.isCurrentTime {
                                            Circle()
                                                .fill(Color.yellow)
                                                .frame(width: 6, height: 6)
                                                .shadow(color: Color.yellow.opacity(0.6), radius: 3, x: 0, y: 0)
                                        }
                                    }
                                    .frame(width: 80, height: 100)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(item.isCurrentTime ? Color.yellow.opacity(0.2) : Color.white.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(item.isCurrentTime ? Color.yellow.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Emotion Analysis - now uses real API data
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.white)
                            Text("Emotion Analysis")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Text(emotionManager.getUserEmotionProfile())
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(15)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.horizontal)
                    
                    // Emotion Intensity
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Emotion Intensity")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        VStack(spacing: 15) {
                            HStack {
                                Text("91%")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "thermometer.high")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                            }
                            
                            ProgressView(value: 0.91)
                                .progressViewStyle(LinearProgressViewStyle(tint: .red))
                                .scaleEffect(x: 1, y: 3, anchor: .center)
                            
                            Text("Very intense emotional response")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Button(action: {}) {
                                Text("Tap for detailed analysis")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal)
                    
                    // Key Behavioral Patterns - now uses real API data
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.white)
                            Text("Behavioral & Health Factors")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        VStack(spacing: 15) {
                            // Behavior Factors
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    Text("Behavior Patterns")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                
                                Text(emotionManager.getUserBehaviorFactors())
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                            
                            // Health Factors
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "heart.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    Text("Health Indicators")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                
                                Text(emotionManager.getUserHealthFactors())
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Your Emotions")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
} 