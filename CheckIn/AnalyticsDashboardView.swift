//
//  AnalyticsDashboardView.swift
//  moodgpt
//
//  Created by Test on 6/3/25.
//

import SwiftUI

struct AnalyticsDashboardView: View {
    @StateObject private var dataManager = IntegratedDataManager.shared
    @State private var selectedTab = 0
    @State private var showingRefreshIndicator = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Sync Status Header
                    syncStatusCard
                    
                    // Quick Stats Overview
                    quickStatsSection
                    
                    // Main Content Tabs
                    TabView(selection: $selectedTab) {
                        userAnalysisTab
                            .tag(0)
                        
                        healthDataTab
                            .tag(1)
                        
                        locationInsightsTab
                            .tag(2)
                        
                        contactsSentimentTab
                            .tag(3)
                    }
                    .frame(height: 500)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                }
                .padding()
            }
            .navigationTitle("Analytics Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshData) {
                        Image(systemName: showingRefreshIndicator ? "arrow.clockwise" : "arrow.clockwise")
                            .rotationEffect(.degrees(showingRefreshIndicator ? 360 : 0))
                            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: showingRefreshIndicator)
                    }
                }
            }
            .onAppear {
                dataManager.trackViewAppearance("AnalyticsDashboard")
            }
            .onDisappear {
                dataManager.trackViewDisappearance("AnalyticsDashboard")
            }
        }
    }
    
    // MARK: - Sync Status Card
    
    private var syncStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: dataManager.isLoading ? "arrow.clockwise" : "checkmark.circle.fill")
                    .foregroundColor(dataManager.isLoading ? .orange : .green)
                    .font(.title2)
                    .rotationEffect(.degrees(dataManager.isLoading ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: dataManager.isLoading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Data Sync")
                        .font(.headline)
                    Text(dataManager.syncStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let lastSync = dataManager.lastSyncDate {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Last Updated")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(lastSync, style: .time)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
            
            if let error = dataManager.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Snapshot")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 12) {
                quickStatCard(
                    icon: "figure.walk",
                    title: "Steps",
                    value: "\(dataManager.healthData?.steps ?? 0)",
                    color: .blue
                )
                
                quickStatCard(
                    icon: "bed.double",
                    title: "Sleep",
                    value: String(format: "%.1fh", dataManager.healthData?.sleep_hours ?? 0),
                    color: .purple
                )
                
                quickStatCard(
                    icon: "location",
                    title: "Location",
                    value: dataManager.currentLocation != nil ? "Tracked" : "Unknown",
                    color: .green
                )
                
                quickStatCard(
                    icon: "person.2",
                    title: "Contacts",
                    value: "\(dataManager.contactsSentiment.count)",
                    color: .orange
                )
            }
        }
    }
    
    private func quickStatCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - User Analysis Tab
    
    private var userAnalysisTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Insights")
                .font(.title2)
                .fontWeight(.bold)
            
            if let analysis = dataManager.userAnalysis {
                VStack(spacing: 16) {
                    // Overall Mood
                    insightCard(
                        title: "Overall Mood",
                        content: analysis.socialVibe,
                        icon: "face.smiling",
                        color: .blue
                    )
                    
                    // Mental Pulse
                    insightCard(
                        title: "Mental Pulse",
                        content: analysis.mentalPulse,
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green
                    )
                    
                    // AI Insights
                    insightCard(
                        title: "AI Insights",
                        content: analysis.aiScoop,
                        icon: "figure.run",
                        color: .orange
                    )
                    
                    // Zinger Caption
                    insightCard(
                        title: "Current Vibe",
                        content: analysis.zingerCaption,
                        icon: "heart.fill",
                        color: .red
                    )
                    
                    // Recommendations
                    if !analysis.crispAnalyticsPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Key Insights")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ForEach(analysis.crispAnalyticsPoints.prefix(3), id: \.self) { point in
                                HStack {
                                    Image(systemName: "lightbulb")
                                        .foregroundColor(.yellow)
                                    Text(point)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
            } else {
                emptyStateCard(message: "Analyzing your data...", icon: "brain.head.profile")
            }
        }
        .padding()
    }
    
    // MARK: - Health Data Tab
    
    private var healthDataTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Metrics")
                .font(.title2)
                .fontWeight(.bold)
            
            if let health = dataManager.healthData {
                VStack(spacing: 12) {
                    if let steps = health.steps {
                        healthMetricRow(icon: "figure.walk", title: "Steps", value: "\(steps)", unit: "steps")
                    }
                    
                    if let heartRate = health.heart_rate {
                        healthMetricRow(icon: "heart", title: "Heart Rate", value: "\(heartRate)", unit: "BPM")
                    }
                    
                    if let sleep = health.sleep_hours {
                        healthMetricRow(icon: "bed.double", title: "Sleep", value: String(format: "%.1f", sleep), unit: "hours")
                    }
                    
                    if let calories = health.calories_burned {
                        healthMetricRow(icon: "flame", title: "Calories", value: "\(calories)", unit: "cal")
                    }
                    
                    if let distance = health.distance_miles {
                        healthMetricRow(icon: "location", title: "Distance", value: String(format: "%.1f", distance), unit: "miles")
                    }
                    
                    if let activeMinutes = health.active_minutes {
                        healthMetricRow(icon: "timer", title: "Active Time", value: "\(activeMinutes)", unit: "min")
                    }
                }
            } else {
                emptyStateCard(message: "Gathering health data...", icon: "heart.text.square")
            }
        }
        .padding()
    }
    
    private func healthMetricRow(icon: String, title: String, value: String, unit: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Location Insights Tab
    
    private var locationInsightsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location Insights")
                .font(.title2)
                .fontWeight(.bold)
            
            if let location = dataManager.currentLocation {
                VStack(spacing: 16) {
                    locationInfoCard(
                        title: "Current Location",
                        latitude: location.latitude,
                        longitude: location.longitude,
                        accuracy: location.accuracy
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location Insights")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "mappin.circle")
                                .foregroundColor(.green)
                            Text("Location data is being tracked for pattern analysis")
                                .font(.body)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            } else {
                emptyStateCard(message: "Location tracking disabled", icon: "location.slash")
            }
        }
        .padding()
    }
    
    private func locationInfoCard(title: String, latitude: Double, longitude: Double, accuracy: Double?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Latitude: \(latitude, specifier: "%.4f")")
                Text("Longitude: \(longitude, specifier: "%.4f")")
                if let accuracy = accuracy {
                    Text("Accuracy: ±\(accuracy, specifier: "%.0f")m")
                        .foregroundColor(.secondary)
                }
            }
            .font(.body)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Contacts Sentiment Tab
    
    private var contactsSentimentTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Social Connections")
                .font(.title2)
                .fontWeight(.bold)
            
            if !dataManager.contactsSentiment.isEmpty {
                VStack(spacing: 12) {
                    ForEach(Array(dataManager.contactsSentiment.keys.prefix(6)), id: \.self) { contactName in
                        if let sentiment = dataManager.contactsSentiment[contactName] {
                            contactSentimentRow(name: contactName, sentiment: sentiment)
                        }
                    }
                }
            } else {
                emptyStateCard(message: "Analyzing social connections...", icon: "person.2.circle")
            }
        }
        .padding()
    }
    
    private func contactSentimentRow(name: String, sentiment: SimpleContactSentiment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(sentiment.sentiment ?? "Unknown")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorForSentiment(sentiment.sentiment ?? "neutral"))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            if let score = sentiment.score {
                Text("Score: \(score, specifier: "%.1f")")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            if let emotion = sentiment.emotion {
                Text("Emotion: \(emotion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Views
    
    private func insightCard(title: String, content: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func emptyStateCard(message: String, icon: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Functions
    
    private func colorForSentiment(_ sentiment: String) -> Color {
        switch sentiment.lowercased() {
        case "positive":
            return .green
        case "negative":
            return .red
        case "neutral":
            return .blue
        default:
            return .gray
        }
    }
    
    private func refreshData() {
        withAnimation {
            showingRefreshIndicator = true
        }
        
        dataManager.refreshData()
        dataManager.logButtonTap("Refresh", on: "AnalyticsDashboard")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showingRefreshIndicator = false
            }
        }
    }
} 