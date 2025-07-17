//
//  ManualModeTestingView.swift
//  moodgpt
//
//  Created by Test on 6/26/25.
//

import SwiftUI

struct ManualModeTestingView: View {
    @Binding var useManualMode: Bool
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var activityTracker = ActivityTrackingManager()
    
    // Current time for greeting
    @State private var currentTime = Date()
    
    // Sample data that matches the screenshot format
    private let sampleEmotions = ["😊", "😐", "😌", "😴"]
    private let sampleTimeSlots = [
        ("12 PM", "😊", "Energizing"),
        ("2 PM", "😊", "Daily Summary"),
        ("4 PM", "😊", "Good"),
        ("6 PM", "😌", "Relaxed")
    ]
    
    var body: some View {
        ZStack {
            // Background matching the screenshot
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Main content matching screenshot format
                    VStack(spacing: 24) {
                        greetingSection
                        emotionSummarySection
                        emotionalTimelineSection
                        dailyInsightsSection
                        
                        // Manual Mode Toggle Section
                        manualModeToggleSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            currentTime = Date()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Close")
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            
            Spacer()
            
            Text("Manual Mode Testing")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear.frame(width: 60, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 20)
    }
    
    // MARK: - Greeting Section
    
    private var greetingSection: some View {
        VStack(spacing: 12) {
            // App Title
            HStack {
                Text("Checkin")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Greeting Card
            HStack {
                Text(greetingText)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.15))
                    )
                Spacer()
            }
            
            // Location and steps
            HStack {
                Text("New York | 636393 steps")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
        }
    }
    
    // MARK: - Emotion Summary Section
    
    private var emotionSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Emotion: Daily Summary")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Large emoji display
            HStack {
                Spacer()
                Text("😊")
                    .font(.system(size: 120))
                Spacer()
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Emotional Timeline Section
    
    private var emotionalTimelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Emotional Timeline")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Timeline slots
            HStack(spacing: 12) {
                ForEach(Array(sampleTimeSlots.enumerated()), id: \.offset) { index, slot in
                    VStack(spacing: 8) {
                        Text(slot.0)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(slot.1)
                            .font(.system(size: 32))
                        
                        Text(slot.2)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(index == 1 ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(index == 1 ? Color.white.opacity(0.4) : Color.clear, lineWidth: 2)
                            )
                    )
                }
            }
        }
    }
    
    // MARK: - Daily Insights Section
    
    private var dailyInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("Your Daily Insights")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.up")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)
            }
            
            // Insights content
            VStack(alignment: .leading, spacing: 12) {
                Text("Here are the insights based on the provided data: 🏃‍♂️ You're crushing your step game! You took an impressive 636,393 more steps in")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Manual Mode Toggle Section
    
    private var manualModeToggleSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Manual Mode Settings")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Current status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Mode")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(useManualMode ? "Manual Mode Active - Using test data" : "API Mode Active - Using live data")
                            .font(.system(size: 14))
                            .foregroundColor(useManualMode ? .green : .orange)
                    }
                    
                    Spacer()
                    
                    // Toggle switch
                    Toggle("", isOn: $useManualMode)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                        .onChange(of: useManualMode) { oldValue, newValue in
                            UserDefaults.standard.set(newValue, forKey: "useManualMode")
                            activityTracker.trackSettingsChange("manual_mode", oldValue: oldValue, newValue: newValue)
                        }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(useManualMode ? Color.green.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Explanation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Manual Mode Benefits")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        bulletPoint("🚀 Instant testing without API dependencies")
                        bulletPoint("🎭 Rich, realistic test data for all features")
                        bulletPoint("🔄 Consistent behavior for UI development")
                        bulletPoint("⚡ Fast iteration and product testing")
                        bulletPoint("🎯 Perfect for demos and presentations")
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Helper Views
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.blue)
                .font(.system(size: 12, weight: .bold))
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(nil)
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
}

#Preview {
    ManualModeTestingView(useManualMode: .constant(false))
        .environmentObject(ThemeManager())
} 