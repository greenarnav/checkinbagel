//
//  CalendarTabView.swift
//  moodgpt
//
//  Created by Test on 12/20/24.
//

import SwiftUI

// MARK: - Calendar API Models
struct CalendarAPIResponse: Codable {
    let success: Bool
    let data: [CalendarEntry]
    let message: String?
}

struct CalendarEntry: Codable {
    let date: String
    let mood: String
    let notes: String?
}

struct CalendarTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var activityTracker: ActivityTrackingManager
    @State private var selectedDate = Date()
    @State private var showingSettings = false
    @State private var buttonTapCount = 0 // Test counter

    @State private var currentMonth = Date()
    @State private var isLoading = false
    @State private var calendarData: [CalendarEntry] = []
    @State private var errorMessage: String?
    
    private let calendar = Calendar.current
    
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
        GeometryReader { geometry in
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                if let gradient = themeManager.backgroundGradient {
                    gradient.ignoresSafeArea()
                }
                if themeManager.currentTheme == .multiColor {
                    Color.black.opacity(0.3).ignoresSafeArea()
                }
                
                VStack(spacing: 0) {
                    // Simple header test
                    VStack(spacing: 10) {
                        HStack {
                            Text("Profile (Taps: \(buttonTapCount))")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(themeManager.primaryTextColor)
                            Spacer()
                            
                            // Simple test button
                            Button("Settings") {
                                print("🔧 SIMPLE BUTTON TAPPED!")
                                buttonTapCount += 1
                                showingSettings = true
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Test counter button
                        Button("TEST COUNT: \(buttonTapCount)") {
                            print("🔧 TEST BUTTON TAPPED!")
                            buttonTapCount += 1
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        // NavigationLink test
                        NavigationLink(destination: SettingsView()
                            .environmentObject(themeManager)
                            .environmentObject(authManager)
                            .environmentObject(healthDataManager)
                            .environmentObject(activityTracker)
                        ) {
                            Text("NAVIGATION SETTINGS")
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .background(Color.green.opacity(0.2)) // Visible background to see the area
                    
                    HStack {
                        Button(action: { changeMonth(-1) }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.primaryTextColor)
                        }
                        Spacer()
                        Text(monthFormatter.string(from: currentMonth))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(themeManager.primaryTextColor)
                        Spacer()
                        Button(action: { changeMonth(1) }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.primaryTextColor)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                    
                    // Calendar Grid
                    VStack(spacing: 2) {
                        // Weekday headers
                        HStack(spacing: 0) {
                            ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                                Text(day)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(themeManager.secondaryTextColor)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 12)
                        
                        // Calendar Grid
                        let containerPadding: CGFloat = 40
                        let spacingBetweenCells: CGFloat = 4
                        let availableWidth = geometry.size.width - containerPadding
                        let cellWidth = (availableWidth - (spacingBetweenCells * 6)) / 7
                        let cellHeight: CGFloat = cellWidth * 1.4
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: spacingBetweenCells), count: 7), spacing: 6) {
                            ForEach(monthDays, id: \.self) { date in
                                CalendarDateCell(
                                    date: date,
                                    selectedDate: selectedDate,
                                    currentMonth: currentMonth,
                                    cellWidth: cellWidth,
                                    cellHeight: cellHeight,
                                    themeManager: themeManager,
                                    calendar: calendar,
                                    getMoodEmojiForDate: getMoodEmojiForDate,
                                    isPredictedDate: isPredictedDate,
                                    isDateAccessible: isDateAccessible
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeManager.cardBackgroundColor.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(themeManager.borderColor, lineWidth: 1.5)
                            )
                    )
                    .padding(.horizontal, 8)
                    .padding(.bottom, 20)
                }
            }
        }
        .trackScreenAuto(CalendarTabView.self)
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                SettingsView()
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle("Settings")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingSettings = false
                            }
                        }
                    }
            }
            .environmentObject(themeManager)
            .environmentObject(authManager)
            .environmentObject(healthDataManager)
            .environmentObject(activityTracker)
        }

        .onChange(of: selectedDate) { _ in
            fetchCalendarData()
        }
    }
    
    private func fetchCalendarData() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://calender-imr6.onrender.com/get_user_calendar") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        let parameters = ["username": "arnav"]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
            errorMessage = "Failed to prepare request"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(CalendarAPIResponse.self, from: data)
                    if response.success {
                        calendarData = response.data
                    } else {
                        errorMessage = response.message ?? "Unknown error"
                    }
                } catch {
                    errorMessage = "Failed to parse response"
                }
            }
        }.resume()
    }
    
    private func changeMonth(_ value: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
                currentMonth = newMonth
            }
        }
    }
    
    private func getMoodEmojiForDate(_ date: Date) -> String {
        // First check if we have data from the API for this date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        if let calendarEntry = calendarData.first(where: { $0.date == dateString }) {
            return calendarEntry.mood
        }
        
        // For predicted dates, use prediction emojis only within 7 days
        if isPredictedDate(date) {
            return getPredictedMoodEmoji(for: date)
        }
        
        // For dates beyond 7 days prediction, return empty string
        let today = Date()
        if date > today {
            let daysDifference = calendar.dateComponents([.day], from: today, to: date).day ?? 0
            if daysDifference > 7 {
                return "" // No emoji for dates beyond 7 days
            }
        }
        
        // No fallback emoji for historical dates without API data
        return ""
    }
    
    private func isPredictedDate(_ date: Date) -> Bool {
        let today = Date()
        let calendar = Calendar.current
        
        // Check if date is after today
        guard date > today else { return false }
        
        // Only predict up to 7 days
        let daysDifference = calendar.dateComponents([.day], from: today, to: date).day ?? 0
        return daysDifference <= 7
    }
    
    private func isDateAccessible(_ date: Date) -> Bool {
        let today = Date()
        let calendar = Calendar.current
        
        // Allow access to today and past dates
        if date <= today { return true }
        
        // Only allow access to predicted dates (next 7 days)
        let daysDifference = calendar.dateComponents([.day], from: today, to: date).day ?? 0
        return daysDifference <= 7
    }
    
    private func getPredictedMoodEmoji(for date: Date) -> String {
        // Only use API-based predictions, no random generation
        return "neutral-face"
    }
}



// MARK: - Supporting Models
// JournalEntry and EmotionalTimelineItem are now defined in MoodModels.swift

// MARK: - Calendar Extension
extension Calendar {
    func generateDays(inside interval: DateInterval) -> [Date] {
        var days: [Date] = []
        var currentDate = interval.start
        
        while currentDate < interval.end {
            days.append(currentDate)
            guard let nextDate = date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return days
    }
}

// MARK: - Historical Home View
struct HistoricalHomeView: View {
    let selectedDate: Date
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTimeSlotIndex: Int = 3
    @State private var currentTimeSlotData: HistoricalTimeSlotData? = nil
    @State private var showingAIScoop = false
    @State private var showingMentalPulse = false
    @State private var showingSocialVibe = false
    
    // Historical timeline data for the selected date
    private var historicalTimelineSlots: [(String, String, String, Bool)] {
        generateHistoricalTimeline(for: selectedDate)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with close button on the left
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Text(formatSelectedDate())
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible spacer to center the title
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60) // Increased top padding to bring content down
                
                // Historical Timeline
                HistoricalEmotionalTimeline(
                    timelineSlots: historicalTimelineSlots,
                    selectedIndex: selectedTimeSlotIndex,
                    onSlotTap: { index, time, mood, description in
                        handleTimelineSlotTap(index: index, time: time, mood: mood, description: description)
                    }
                )
                
                // Main Emotion Display
                HistoricalMainEmotionSnapshot(
                    mood: currentTimeSlotData?.mood ?? "neutral-face",
                    description: generateHistoricalMoodDescription()
                )
                
                // Button Group
                HistoricalHorizontalButtonGroup(
                    selectedDate: selectedDate,
                    currentTimeSlotData: currentTimeSlotData
                )
                
                // Historical Insights
                HistoricalInsightsContext(
                    selectedDate: selectedDate,
                    currentTimeSlotData: currentTimeSlotData
                )
                
                // Bottom spacing
                Color.clear.frame(height: 50)
            }
        }
        .background(Color.black)
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            loadHistoricalData()
        }
    }
    
    private func formatSelectedDate() -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else if isPredictedDate(selectedDate) {
            formatter.dateFormat = "EEEE"
            return "\(formatter.string(from: selectedDate)) Mood Forecast"
        } else {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: selectedDate)
        }
    }
    
    private func isPredictedDate(_ date: Date) -> Bool {
        let today = Date()
        let calendar = Calendar.current
        
        // Check if date is after today
        guard date > today else { return false }
        
        // Only predict up to 7 days
        let daysDifference = calendar.dateComponents([.day], from: today, to: date).day ?? 0
        return daysDifference <= 7
    }
    
    private func loadHistoricalData() {
        // Generate initial historical data for the selected time slot
        updateCurrentTimeSlotData()
    }
    
    private func handleTimelineSlotTap(index: Int, time: String, mood: String, description: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedTimeSlotIndex = index
            updateCurrentTimeSlotData()
        }
    }
    
    private func updateCurrentTimeSlotData() {
        let slot = historicalTimelineSlots[selectedTimeSlotIndex]
        currentTimeSlotData = generateHistoricalTimeSlotData(
            time: slot.0,
            mood: slot.1,
            description: slot.2
        )
    }
    
    private func generateHistoricalTimeSlotData(time: String, mood: String, description: String) -> HistoricalTimeSlotData {
        let steps = 0
        let calories = 0
        
        let heartRate = generateHeartRateForTime(time: time, mood: mood)
        
        return HistoricalTimeSlotData(
            time: time,
            mood: mood,
            description: description,
            steps: steps,
            activeEnergy: calories,
            heartRate: heartRate,
            location: "New York",
            weather: generateWeatherForTime(time: time)
        )
    }
    
    private func getHourMultiplier(from timeString: String) -> Double {
        let hour = extractHour(from: timeString)
        
        switch hour {
        case 6...8: return 0.3      // Morning - less activity
        case 9...11: return 0.6     // Mid morning
        case 12...14: return 0.8    // Lunch time - more active
        case 15...17: return 1.0    // Afternoon peak
        case 18...20: return 0.7    // Evening
        case 21...23: return 0.4    // Night - winding down
        default: return 0.2         // Late night/early morning
        }
    }
    
    private func generateHeartRateForTime(time: String, mood: String) -> Int {
        let baseRate = 70
        let hour = extractHour(from: time)
        
        var rate = baseRate
        switch hour {
        case 6...8: rate += 5      // Morning slight increase
        case 9...11: rate += 10    // More active
        case 12...14: rate += 15   // Peak activity
        case 15...17: rate += 12   // Afternoon
        case 18...20: rate += 8    // Evening
        case 21...23: rate += 2    // Relaxing
        default: rate -= 10        // Sleep/rest
        }
        
        switch mood {
        case "concerned", "worried", "anxios-with-sweat": rate += 8
        case "happy", "grinning", "excited": rate += 5
        case "sad", "cry", "pensive": rate -= 3
        case "sleep", "sleepy", "tired": rate -= 15
        default: rate += 0
        }
        
        return max(45, min(120, rate))
    }
    
    private func generateWeatherForTime(time: String) -> String {
        let hour = extractHour(from: time)
        
        switch hour {
        case 6...9: return "72°F, Sunny"
        case 10...14: return "75°F, Clear"
        case 15...18: return "73°F, Partly Cloudy"
        case 19...21: return "68°F, Clear"
        default: return "65°F, Clear"
        }
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
    
    private func generateHistoricalMoodDescription() -> String {
        guard let data = currentTimeSlotData else {
            return "Neutral — reflecting on this moment"
        }
        
        return "\(data.description) — \(getHistoricalContextualDescription(for: data))"
    }
    
    private func getHistoricalContextualDescription(for data: HistoricalTimeSlotData) -> String {
        let hour = extractHour(from: data.time)
        let dayOfWeek = Calendar.current.component(.weekday, from: selectedDate)
        
        switch hour {
        case 6...8:
            return dayOfWeek <= 5 ? "starting a productive workday" : "leisurely weekend morning"
        case 9...11:
            return "focused and determined energy"
        case 12...14:
            return "peak social connection time"
        case 15...17:
            return "afternoon momentum building"
        case 18...20:
            return "winding down and reflecting"
        default:
            return "peaceful evening state"
        }
    }
}

// MARK: - Historical Data Models

struct HistoricalTimeSlotData {
    let time: String
    let mood: String
    let description: String
    let steps: Int
    let activeEnergy: Int
    let heartRate: Int
    let location: String
    let weather: String
}

struct HistoricalVitalsRow: View {
    let selectedDate: Date
    @State private var selectedMetrics: Set<Int> = Set([0, 1, 2, 3])
    
    private var historicalVitals: [RefinedVital] {
        generateHistoricalVitals(for: selectedDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Historical wellness data")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(historicalVitals.enumerated()), id: \.offset) { index, vital in
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
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct HistoricalEmotionalTimeline: View {
    let timelineSlots: [(String, String, String, Bool)]
    let selectedIndex: Int
    let onSlotTap: (Int, String, String, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Timeline")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(timelineSlots.enumerated()), id: \.offset) { index, slot in
                        Button(action: {
                            onSlotTap(index, slot.0, slot.1, slot.2)
                        }) {
                            VStack(spacing: 6) {
                                Text(slot.0)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                AnimatedEmoji(slot.1, size: 36, fallback: "neutral-face")
                                    .opacity(0.8)
                                    .scaleEffect(0.9)
                                
                                Text(slot.2)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
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
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedIndex == index ? Color.white.opacity(0.2) : Color.clear, lineWidth: 1)
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
}

struct HistoricalMainEmotionSnapshot: View {
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

struct HistoricalHorizontalButtonGroup: View {
    let selectedDate: Date
    let currentTimeSlotData: HistoricalTimeSlotData?
    @State private var showingAIScoop = false
    @State private var showingMentalPulse = false
    @State private var showingSocialVibe = false
    
    private func isPredictedDate(_ date: Date) -> Bool {
        let today = Date()
        let calendar = Calendar.current
        
        // Check if date is after today
        guard date > today else { return false }
        
        // Check if date is within 7 days of today
        let daysDifference = calendar.dateComponents([.day], from: today, to: date).day ?? 0
        return daysDifference <= 7
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Button(action: { showingAIScoop.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: showingAIScoop ? "sparkles.square.filled.on.square" : "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        Text("AI Scoop")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .frame(width: 95)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [Color.purple.opacity(0.25), Color.pink.opacity(0.25)], startPoint: .leading, endPoint: .trailing))
                            .overlay(Capsule().stroke(Color.purple.opacity(0.3), lineWidth: 0.5))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showingMentalPulse.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: showingMentalPulse ? "brain.head.profile.fill" : "brain.head.profile")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Mental Pulse")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .frame(width: 95)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [Color.indigo.opacity(0.25), Color.blue.opacity(0.25)], startPoint: .leading, endPoint: .trailing))
                            .overlay(Capsule().stroke(Color.indigo.opacity(0.3), lineWidth: 0.5))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showingSocialVibe.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: showingSocialVibe ? "globe.americas.fill" : "globe.americas")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Social Vibe")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .frame(width: 95)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [Color.yellow.opacity(0.25), Color.orange.opacity(0.25)], startPoint: .leading, endPoint: .trailing))
                            .overlay(Capsule().stroke(Color.yellow.opacity(0.3), lineWidth: 0.5))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            
            if showingAIScoop {
                HistoricalContentCard(
                    title: "AI Scoop",
                    content: generateHistoricalAIContent(),
                    color: .purple,
                    isPrediction: isPredictedDate(selectedDate)
                )
            }
            
            if showingMentalPulse {
                HistoricalContentCard(
                    title: "Mental Pulse",
                    content: generateHistoricalMentalContent(),
                    color: .blue,
                    isPrediction: isPredictedDate(selectedDate)
                )
            }
            
            if showingSocialVibe {
                HistoricalContentCard(
                    title: "Social Vibe",
                    content: generateHistoricalSocialContent(),
                    color: .orange,
                    isPrediction: isPredictedDate(selectedDate)
                )
            }
        }
    }
    
    private func generateHistoricalAIContent() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayName = formatter.string(from: selectedDate)
        
        let today = Date()
        let isPredicted = selectedDate > today && Calendar.current.dateComponents([.day], from: today, to: selectedDate).day ?? 0 <= 7
        
        if isPredicted {
            return "Prediction for this \(dayName): Based on your patterns, we anticipate balanced energy with approximately \(currentTimeSlotData?.steps ?? 8500) steps. Your mood forecast suggests steady emotional flow with peak energy around \(currentTimeSlotData?.time ?? "3 PM"). Recommended focus on mindfulness and maintaining current positive trends."
        } else {
            return "On this \(dayName), your emotional pattern showed balanced energy with \(currentTimeSlotData?.steps ?? 8432) steps recorded. Historical mood analysis indicates this was a day of steady emotional flow with peak energy around \(currentTimeSlotData?.time ?? "3 PM"). Your historical data suggests optimal decision-making during this time period."
        }
    }
    
    private func generateHistoricalMentalContent() -> String {
        let today = Date()
        let isPredicted = selectedDate > today && Calendar.current.dateComponents([.day], from: today, to: selectedDate).day ?? 0 <= 7
        
        if isPredicted {
            return "Predicted Mental State: \(currentTimeSlotData?.description ?? "Focused") • Expected Cognitive Load: Moderate • Stress Forecast: Low • Recommended: Maintain current wellness practices • Suggested Focus: Mindfulness and balance"
        } else {
            return "Mental State Analysis: \(currentTimeSlotData?.description ?? "Focused") • Cognitive Load: Moderate • Historical Stress Level: Low • Past Decision Quality: High • Memory Formation: Optimal during this period"
        }
    }
    
    private func generateHistoricalSocialContent() -> String {
        let today = Date()
        let isPredicted = selectedDate > today && Calendar.current.dateComponents([.day], from: today, to: selectedDate).day ?? 0 <= 7
        
        if isPredicted {
            return "Social Forecast: Positive interaction potential • Expected Environment: \(currentTimeSlotData?.location ?? "Home") • Weather Impact: \(currentTimeSlotData?.weather ?? "Favorable") • Recommended: Maintain social connections • Opportunity for meaningful conversations"
        } else {
            return "Historical Social Energy: Balanced • Past Interaction Quality: Meaningful • Location Context: \(currentTimeSlotData?.location ?? "Home") • Weather Impact: \(currentTimeSlotData?.weather ?? "Favorable") • Social Resonance: Strong connections"
        }
    }
}

struct HistoricalContentCard: View {
    let title: String
    let content: String
    let color: Color
    let isPrediction: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: title == "AI Scoop" ? "sparkles" : title == "Mental Pulse" ? "brain.head.profile" : "globe.americas")
                    .foregroundColor(cardColor)
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(cardColor.opacity(0.2), lineWidth: 1))
                )
        }
        .padding(.horizontal, 20)
        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity)))
    }
    
    private var cardColor: Color {
        isPrediction ? Color(red: 0.4, green: 0.6, blue: 1.0) : color
    }
}

struct HistoricalInsightsContext: View {
    let selectedDate: Date
    let currentTimeSlotData: HistoricalTimeSlotData?
    
    private func isPredictedDate(_ date: Date) -> Bool {
        let today = Date()
        let calendar = Calendar.current
        
        // Check if date is after today
        guard date > today else { return false }
        
        // Check if date is within 7 days of today
        let daysDifference = calendar.dateComponents([.day], from: today, to: date).day ?? 0
        return daysDifference <= 7
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(generateHistoricalInsights(), id: \.0) { insight in
                HStack(spacing: 8) {
                    Image(systemName: insight.0)
                        .font(.system(size: 14))
                        .foregroundColor(insight.2)
                    
                    Text(insight.1)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func generateHistoricalInsights() -> [(String, String, Color)] {
        let steps = currentTimeSlotData?.steps ?? 0
        let heartRate = currentTimeSlotData?.heartRate ?? 0
        
        let today = Date()
        let isPredicted = selectedDate > today && Calendar.current.dateComponents([.day], from: today, to: selectedDate).day ?? 0 <= 7
        
        if isPredicted {
            return [
                ("figure.walk", "Predicted \(steps) steps for this day", .green.opacity(0.8)),
                ("music.note", "Suggested listening: \(generatePredictedMusicInsight())", .indigo.opacity(0.8)),
                ("location.fill", "Expected location: \(currentTimeSlotData?.location ?? "home/office")", .orange.opacity(0.8)),
                ("heart.fill", "Forecasted heart rate: \(heartRate) bpm", .red.opacity(0.8)),
                ("chart.line.uptrend.xyaxis", generatePredictedTrendInsight(), .blue.opacity(0.8))
            ]
        } else {
            return [
                ("figure.walk", "You took \(steps) steps on this day", .green.opacity(0.8)),
                ("music.note", "You listened to \(generateHistoricalMusicInsight())", .indigo.opacity(0.8)),
                ("location.fill", "You spent time at \(currentTimeSlotData?.location ?? "multiple locations")", .orange.opacity(0.8)),
                ("heart.fill", "Your heart rate averaged \(heartRate) bpm", .red.opacity(0.8)),
                ("chart.line.uptrend.xyaxis", generateHistoricalTrendInsight(), .blue.opacity(0.8))
            ]
        }
    }
    
    private func generateHistoricalMusicInsight() -> String {
        let options = ["upbeat pop tracks", "calming instrumental music", "energetic workout playlists", "focused study ambience", "relaxing evening jazz"]
        return "Music data not available"
    }
    
    private func generateHistoricalTrendInsight() -> String {
        let trends = ["Mood trending upward by 15%", "Energy levels remained stable", "Stress decreased throughout the day", "Social energy peaked during afternoon", "Overall wellness score: 8.2/10"]
        return "Trend data not available"
    }
    
    private func generatePredictedMusicInsight() -> String {
        let options = ["calming instrumentals for focus", "upbeat tracks for energy", "nature sounds for relaxation", "motivational playlists", "ambient music for productivity"]
        return "Recommendation data not available"
    }
    
    private func generatePredictedTrendInsight() -> String {
        let trends = ["Predicted mood stability", "Energy forecast: steady increase", "Stress levels expected to remain low", "Social energy likely to peak afternoon", "Wellness outlook: positive"]
        return "Forecast data not available"
    }
}

// MARK: - Calendar Date Cell Component
struct CalendarDateCell: View {
    let date: Date
    let selectedDate: Date
    let currentMonth: Date
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    let themeManager: ThemeManager
    let calendar: Calendar
    let getMoodEmojiForDate: (Date) -> String
    let isPredictedDate: (Date) -> Bool
    let isDateAccessible: (Date) -> Bool
    
    private var emojiName: String {
        getMoodEmojiForDate(date)
    }
    
    var body: some View {
        Group {
            if isDateAccessible(date) && !emojiName.isEmpty {
                NavigationLink(destination: HistoricalHomeView(selectedDate: date)) {
                    cellContent
                }
            } else {
                cellContent
            }
        }
    }
    
    private var cellContent: some View {
        VStack(spacing: 3) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(dayTextColor)
            
            if !emojiName.isEmpty {
                AnimatedEmoji(
                    emojiName,
                    size: 36,
                    fallback: emojiName
                )
                .opacity(emojiOpacity)
                .scaleEffect(isSelected ? 1.15 : 1.0)
            } else {
                // Empty space for dates beyond prediction
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 36, height: 36)
            }
        }
        .frame(width: cellWidth, height: cellHeight)
        .background(backgroundView)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedDate)
    }
    
    private var isSelected: Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }
    
    private var isToday: Bool {
        calendar.isDate(date, inSameDayAs: Date())
    }
    
    private var isCurrentMonth: Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    private var isPredicted: Bool {
        isPredictedDate(date)
    }
    
    private var dayTextColor: Color {
        if !emojiName.isEmpty {
            if isSelected {
                return .white
            } else if isToday {
                return .blue
            } else if isPredicted {
                return Color(red: 0.4, green: 0.6, blue: 1.0) // Light blue for predicted dates
            } else if isCurrentMonth {
                return themeManager.primaryTextColor
            } else {
                return themeManager.secondaryTextColor.opacity(0.4)
            }
        } else {
            // Dimmed text for dates beyond prediction
            return themeManager.secondaryTextColor.opacity(0.2)
        }
    }
    
    private var emojiOpacity: Double {
        if emojiName.isEmpty {
            return 0.0
        } else if isPredicted {
            return 0.7
        } else if isCurrentMonth {
            return 1.0
        } else {
            return 0.3
        }
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(backgroundFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    private var backgroundFillColor: Color {
        if emojiName.isEmpty {
            return Color.clear // No background for empty dates
        } else if isSelected {
            return Color.blue.opacity(0.2)
        } else if isToday {
            return themeManager.cardBackgroundColor.opacity(0.3)
        } else if isPredicted {
            return Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.1)  // Light blue tint for predicted dates
        } else {
            return themeManager.cardBackgroundColor.opacity(0.15)
        }
    }
    
    private var borderColor: Color {
        if emojiName.isEmpty {
            return Color.clear // No border for empty dates
        } else if isSelected {
            return Color.blue.opacity(0.4)
        } else if isToday {
            return Color.blue.opacity(0.3)
        } else if isPredicted {
            return Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3)  // Light blue border for predicted dates
        } else {
            return themeManager.borderColor.opacity(0.2)
        }
    }
    
    private var borderWidth: CGFloat {
        if emojiName.isEmpty {
            return 0 // No border for empty dates
        } else if isSelected || isToday || isPredicted {
            return 2
        } else {
            return 1
        }
    }
}

// MARK: - Historical Data Generation Functions

func getHourMultiplier(from timeString: String) -> Double {
    let hour = extractHour(from: timeString)
    
    switch hour {
    case 6...8: return 0.3      // Morning - less activity
    case 9...11: return 0.6     // Mid morning
    case 12...14: return 0.8    // Lunch time - more active
    case 15...17: return 1.0    // Afternoon peak
    case 18...20: return 0.7    // Evening
    case 21...23: return 0.4    // Night - winding down
    default: return 0.2         // Late night/early morning
    }
}

func generateHeartRateForTime(time: String, mood: String) -> Int {
    let baseRate = 70
    let hour = extractHour(from: time)
    
    var rate = baseRate
    switch hour {
    case 6...8: rate += 5      // Morning slight increase
    case 9...11: rate += 10    // More active
    case 12...14: rate += 15   // Peak activity
    case 15...17: rate += 12   // Afternoon
    case 18...20: rate += 8    // Evening
    case 21...23: rate += 2    // Relaxing
    default: rate -= 10        // Sleep/rest
    }
    
    switch mood {
    case "concerned", "worried", "anxios-with-sweat": rate += 8
    case "happy", "grinning", "excited": rate += 5
    case "sad", "cry", "pensive": rate -= 3
    case "sleep", "sleepy", "tired": rate -= 15
    default: rate += 0
    }
    
    return max(45, min(120, rate))
}

func generateWeatherForTime(time: String) -> String {
    let hour = extractHour(from: time)
    
    switch hour {
    case 6...9: return "72°F, Sunny"
    case 10...14: return "75°F, Clear"
    case 15...18: return "73°F, Partly Cloudy"
    case 19...21: return "68°F, Clear"
    default: return "65°F, Clear"
    }
}

func extractHour(from timeString: String) -> Int {
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

func generateHistoricalTimeline(for date: Date) -> [(String, String, String, Bool)] {
    let times = ["6 AM", "9 AM", "12 PM", "3 PM", "6 PM", "9 PM"]
    
    // Check if this is a predicted date
    let today = Date()
    let isPredicted = date > today && Calendar.current.dateComponents([.day], from: today, to: date).day ?? 0 <= 7
    
    if isPredicted {
        // Use more neutral moods for predictions
        let predictedMoods = ["slightly-happy", "smile", "relieved", "peaceful", "thinking-face", "warm-smile"]
        let predictedDescriptions = ["Morning", "Getting Started", "Peak Energy", "Focused", "Golden Hour", "Wind Down"]
        
        let seed = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        
        return times.enumerated().map { index, time in
            let moodIndex = (seed + index) % predictedMoods.count
            let isCurrentTime = Calendar.current.component(.hour, from: Date()) / 3 == index
            return (time, predictedMoods[moodIndex], predictedDescriptions[index], isCurrentTime)
        }
    } else {
        // Historical data
        let moods = ["relieved", "slightly-happy", "happy", "grinning", "thinking-face", "sleepy"]
        let descriptions = ["Morning", "Getting Started", "Peak Energy", "Neutral", "Golden Hour", "Wind Down"]
        
        // Use date as seed for consistent historical data
        let seed = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        
        return times.enumerated().map { index, time in
            let moodIndex = (seed + index) % moods.count
            let isCurrentTime = Calendar.current.component(.hour, from: Date()) / 3 == index
            return (time, moods[moodIndex], descriptions[index], isCurrentTime)
        }
    }
}

func generateHistoricalTimeSlotData(time: String, mood: String, description: String) -> HistoricalTimeSlotData {
            let steps = 0
        let calories = 0
    
    let heartRate = generateHeartRateForTime(time: time, mood: mood)
    
    return HistoricalTimeSlotData(
        time: time,
        mood: mood,
        description: description,
        steps: steps,
        activeEnergy: calories,
        heartRate: heartRate,
        location: "New York",
        weather: generateWeatherForTime(time: time)
    )
}

func generateHistoricalVitals(for date: Date) -> [RefinedVital] {
    let seed = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
    let baseSteps = 6000 + (seed % 4000)
    let baseHeartRate = 65 + (seed % 20)
    
    return [
        RefinedVital(icon: "figure.walk", value: "\(baseSteps)", color: .green),
        RefinedVital(icon: "heart.fill", value: "\(baseHeartRate)", color: .red),
        RefinedVital(icon: "bolt.fill", value: "\(250 + (seed % 200))", color: .orange),
        RefinedVital(icon: "location.fill", value: "Office", color: .blue),
        RefinedVital(icon: "bed.double.fill", value: "7.5h", color: .purple),
        RefinedVital(icon: "thermometer.sun.fill", value: "72°F", color: .orange)
    ]
}

// MARK: - Supporting Models
// JournalEntry and EmotionalTimelineItem are now defined in MoodModels.swift 
