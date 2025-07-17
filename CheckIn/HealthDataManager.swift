//


//  HealthDataManager.swift
//  moodgpt
//
//  Created by Test on 5/31/25.
//

import Foundation
import HealthKit
import SwiftUI
import Combine

/**
 * HealthDataManager - Comprehensive Health Data and User Analysis System
 * 
 * This class manages the complete flow of health data collection, API communication,
 * and user analysis. Here's how it works step by step:
 * 
 * 1. INITIALIZATION & SETUP:
 *    - Creates HealthKit store and connects to centralized APIManager
 *    - Loads user preferences and auto-logging settings
 *    - Sets up automatic health data logging timer (every 10 minutes)
 * 
 * 2. USERNAME MANAGEMENT:
 *    - The currentUsername property tracks the logged-in user
 *    - This username is automatically used in all API calls
 *    - When username changes, health data is re-sent with the new username
 * 
 * 3. HEALTH DATA COLLECTION:
 *    - fetchEssentialHealthData(): Collects comprehensive health metrics
 *    - fetchEssentialHealthDataForAPI(): Collects simplified data for API
 *    - Includes: steps, heart rate, calories, exercise minutes, sleep, etc.
 * 
 * 4. API COMMUNICATION (via centralized APIManager):
 *    - sendHealthDataToAPI(): Sends health data to health endpoint
 *    - fetchUserAnalysis(): Gets user analysis from Django API
 *    - sendHealthDataAndFetchAnalysis(): Combined operation
 * 
 * 5. USER ANALYSIS INTEGRATION:
 *    - Fetches comprehensive user analysis (emoji, insights, social vibe)
 *    - Analysis includes: emoji_id, zinger_caption, social_vibe, mental_pulse, ai_scoop
 *    - All analysis data is tied to the current username
 * 
 * 6. AUTOMATIC OPERATIONS:
 *    - Auto-logging sends health data every 10 minutes if enabled
 *    - Username changes trigger immediate data re-sending
 *    - Health data updates automatically trigger analysis refresh
 * 
 * 7. TESTING & DEBUGGING:
 *    - testCompleteHealthAndAnalysisFlow(): Tests the entire system
 *    - testHealthDataAPI(): Tests only health data sending
 *    - testUserAnalysisAPI(): Tests only user analysis fetching
 */
class HealthDataManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private let apiManager = APIManager.shared
    
    @Published var isAuthorized = false
    @Published var healthStatus = "Not initialized"
    @Published var lastHealthData: [String: Any]?
    @Published var userProfile: [String: String] = [:]
    @Published var currentUsername: String = "" // Will be set from AuthManager
    @Published var isAutoLoggingEnabled = true
    @Published var lastAutoLogTime: Date?
    
    // MARK: - User Analysis Data (From Centralized APIManager)
    /// Contains the complete user analysis response from the Django API
    /// Includes: emoji_id, zinger_caption, social_vibe, mental_pulse, ai_scoop, crisp_analytics_points
    @Published var userAnalysis: UserAnalysisResponse?
    
    /// Status of the user analysis API call (for UI feedback)
    @Published var analysisStatus = "Not loaded"
    
    /// Loading state for analysis API call (for UI loading indicators)
    @Published var isLoadingAnalysis = false
    
    // Timer for automatic health data logging every 10 minutes
    private var autoLogTimer: Timer?
    private let autoLogInterval: TimeInterval = 600 // 10 minutes in seconds
    
    // User profile data (name, email, phone)
    @Published var userName: String = "" {
        didSet {
            userProfile["name"] = userName
            UserDefaults.standard.set(userName, forKey: "UserName")
        }
    }
    
    @Published var userEmail: String = "" {
        didSet {
            userProfile["email"] = userEmail
            UserDefaults.standard.set(userEmail, forKey: "UserEmail")
        }
    }
    
    @Published var userPhone: String = "" {
        didSet {
            userProfile["phone"] = userPhone
            UserDefaults.standard.set(userPhone, forKey: "UserPhone")
        }
    }
    
    // COMPREHENSIVE Health data types - includes all major Apple Health metrics
    private let healthDataTypes: Set<HKObjectType> = {
        var types: Set<HKObjectType> = []
        
        // MARK: - Characteristic Data (Personal Info)
        if let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) {
            types.insert(dateOfBirth)
        }
        if let sex = HKObjectType.characteristicType(forIdentifier: .biologicalSex) {
            types.insert(sex)
        }
        
        // MARK: - Activity & Fitness
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        if let walkingRunningDistance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(walkingRunningDistance)
        }
        if let cyclingDistance = HKObjectType.quantityType(forIdentifier: .distanceCycling) {
            types.insert(cyclingDistance)
        }
        if let swimmingDistance = HKObjectType.quantityType(forIdentifier: .distanceSwimming) {
            types.insert(swimmingDistance)
        }
        if let flightsClimbed = HKObjectType.quantityType(forIdentifier: .flightsClimbed) {
            types.insert(flightsClimbed)
        }
        if let exerciseMinutes = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
            types.insert(exerciseMinutes)
        }
        
        // MARK: - Energy & Nutrition
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        if let restingEnergy = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) {
            types.insert(restingEnergy)
        }
        if let dietaryEnergy = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            types.insert(dietaryEnergy)
        }
        
        // MARK: - Heart & Cardiovascular
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let restingHeartRate = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHeartRate)
        }
        if let heartRateVariability = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(heartRateVariability)
        }
        
        // MARK: - Blood Pressure
        if let systolicBP = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic) {
            types.insert(systolicBP)
        }
        if let diastolicBP = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) {
            types.insert(diastolicBP)
        }
        
        // MARK: - Body Measurements
        if let height = HKObjectType.quantityType(forIdentifier: .height) {
            types.insert(height)
        }
        if let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weight)
        }
        if let bodyTemperature = HKObjectType.quantityType(forIdentifier: .bodyTemperature) {
            types.insert(bodyTemperature)
        }
        
        // MARK: - Respiratory & Vitals
        if let respiratoryRate = HKObjectType.quantityType(forIdentifier: .respiratoryRate) {
            types.insert(respiratoryRate)
        }
        if let oxygenSaturation = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) {
            types.insert(oxygenSaturation)
        }
        
        // MARK: - Sleep & Recovery
        if let sleepAnalysis = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepAnalysis)
        }
        
        // MARK: - Mindfulness
        if let mindfulSession = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindfulSession)
        }
        
        // MARK: - Environmental
        if let environmentalSoundLevels = HKObjectType.quantityType(forIdentifier: .environmentalAudioExposure) {
            types.insert(environmentalSoundLevels)
        }
        if let headphoneSoundLevels = HKObjectType.quantityType(forIdentifier: .headphoneAudioExposure) {
            types.insert(headphoneSoundLevels)
        }
        
        // MARK: - Workouts
        let workoutType = HKObjectType.workoutType()
        types.insert(workoutType)
        
        return types
    }()
    
    override init() {
        super.init()
        
        // Load saved user profile data
        userName = UserDefaults.standard.string(forKey: "UserName") ?? ""
        userEmail = UserDefaults.standard.string(forKey: "UserEmail") ?? ""
        userPhone = UserDefaults.standard.string(forKey: "UserPhone") ?? ""
        
        // Update profile dictionary
        userProfile["name"] = userName
        userProfile["email"] = userEmail
        userProfile["phone"] = userPhone
        
        // Load auto logging settings
        isAutoLoggingEnabled = UserDefaults.standard.bool(forKey: "AutoHealthLoggingEnabled") 
        if let lastLogTime = UserDefaults.standard.object(forKey: "LastAutoLogTime") as? Date {
            lastAutoLogTime = lastLogTime
        }
        
        // Start auto logging if enabled
        if isAutoLoggingEnabled {
            startAutoHealthLogging()
        }
        
        // Listen for user authentication events
        setupAuthenticationNotificationListener()
    }
    
    deinit {
        // Clean up notification observer
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Authentication Integration
    
    /// Set up notification listener for user authentication events
    private func setupAuthenticationNotificationListener() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserAuthentication(_:)),
            name: NSNotification.Name("UserAuthenticatedForHeaderStats"),
            object: nil
        )
    }
    
    /// Handle user authentication notification and submit header stats
    @objc private func handleUserAuthentication(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let username = userInfo["username"] as? String else { return }
        
        print("🔔 HealthDataManager received authentication notification for user: \(username)")
        
        // Update username and submit header stats
        setUsername(username)
        
        // Small delay to ensure username is set, then submit stats
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) {
            self.submitCurrentHeaderStats()
        }
    }
    
    // MARK: - Auto Health Logging
    
    func startAutoHealthLogging() {
        guard isAutoLoggingEnabled else { return }
        
        autoLogTimer?.invalidate() // Cancel any existing timer
        
        autoLogTimer = Timer.scheduledTimer(withTimeInterval: autoLogInterval, repeats: true) { [weak self] _ in
            self?.performAutoHealthLog()
        }
        
        // Perform initial log
        performAutoHealthLog()
        
                    healthStatus = "Auto-logging started - every 10 minutes"
    }
    
    func stopAutoHealthLogging() {
        autoLogTimer?.invalidate()
        autoLogTimer = nil
        isAutoLoggingEnabled = false
        UserDefaults.standard.set(false, forKey: "AutoHealthLoggingEnabled")
        
        healthStatus = "Auto-logging stopped"
    }
    
    func enableAutoLogging(_ enabled: Bool) {
        isAutoLoggingEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "AutoHealthLoggingEnabled")
        
        if enabled {
            startAutoHealthLogging()
        } else {
            stopAutoHealthLogging()
        }
    }
    
    private func performAutoHealthLog() {
        guard isAutoLoggingEnabled else { return }
        
        // Update last log time
        lastAutoLogTime = Date()
        UserDefaults.standard.set(lastAutoLogTime, forKey: "LastAutoLogTime")
        
        healthStatus = "Auto-logging health data..."
        
        // Fetch simplified health data for API
        fetchEssentialHealthDataForAPI()
        
        // Submit header stats as well during auto-logging
        submitHeaderStats()
    }

    // MARK: - Public Methods
    func requestPermissionsAndFetchData() {
        healthStatus = "Requesting permissions for \(healthDataTypes.count) comprehensive metrics..."
        
        guard HKHealthStore.isHealthDataAvailable() else {
            healthStatus = "HealthKit not available"
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: healthDataTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.healthStatus = "Permission granted - fetching comprehensive health data..."
                    
                    // Start auto logging if enabled
                    if self?.isAutoLoggingEnabled == true {
                        self?.startAutoHealthLogging()
                    }
                    
                    // Fetch comprehensive data on background thread to avoid blocking UI
                    DispatchQueue.global(qos: .background).async {
                        self?.fetchEssentialHealthData()
                    }
                } else {
                    self?.healthStatus = "Permission denied: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        }
    }
    
    // Update username from authentication system
    func setUsername(_ username: String) {
        currentUsername = username.isEmpty ? "guest" : username
        
        // Re-send health data with updated username if we have data
        if let healthData = lastHealthData {
            DispatchQueue.global(qos: .background).async {
                self.sendHealthDataToAPI(healthData)
                // Also submit header stats with new username
                self.submitHeaderStats()
            }
        }
    }
    
    /// Manually submit header stats - can be called from UI
    public func submitCurrentHeaderStats() {
        submitHeaderStats()
    }
    
    /// Manually refresh all health data - can be called from UI
    public func refreshHealthData() {
        guard isAuthorized else {
            healthStatus = "Health access not authorized"
            return
        }
        
        healthStatus = "Refreshing health data..."
        DispatchQueue.global(qos: .background).async {
            self.fetchEssentialHealthData()
        }
    }
    
    // Update user name from authentication system
    func setUserName(_ name: String) {
        if userName.isEmpty && !name.isEmpty {
            userName = name
        }
    }
    
    // Update user profile and send to API
    func updateUserProfile(name: String, email: String, phone: String) {
        userName = name
        userEmail = email
        userPhone = phone
        
        // Send profile data asynchronously
        DispatchQueue.global(qos: .background).async {
            if let healthData = self.lastHealthData {
                self.sendHealthDataToAPI(healthData)
            } else {
                self.sendHealthDataToAPI([:])
            }
        }
    }
    
    // MARK: - Comprehensive Data Fetching (expanded health metrics)
    public func fetchEssentialHealthData() {
        let group = DispatchGroup()
        var healthData: [String: Any] = [:]
        
        // Get date ranges - FIXED: Use only today's data instead of 2-day aggregation
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now) // Changed from -2 days to start of today
        
        // MARK: - Core Activity Metrics
        group.enter()
        fetchSteps(from: startOfDay, to: now) { steps in
            healthData["steps_today"] = steps
            group.leave()
        }
        
        group.enter()
        fetchQuantitySum(from: startOfDay, to: now, identifier: .activeEnergyBurned, unit: HKUnit.kilocalorie()) { calories in
            healthData["active_calories_today"] = Int(calories)
            group.leave()
        }
        
        group.enter()
        fetchQuantitySum(from: startOfDay, to: now, identifier: .appleExerciseTime, unit: HKUnit.minute()) { minutes in
            healthData["exercise_minutes_today"] = Int(minutes)
            group.leave()
        }
        
        // MARK: - Distance Metrics
        group.enter()
        fetchQuantitySum(from: startOfDay, to: now, identifier: .distanceWalkingRunning, unit: HKUnit.mile()) { distance in
            healthData["walking_running_distance_today"] = Double(String(format: "%.2f", distance)) ?? distance
            healthData["distance_miles_today"] = Double(String(format: "%.2f", distance)) ?? distance // For header display
            group.leave()
        }
        
        group.enter()
        fetchQuantitySum(from: startOfDay, to: now, identifier: .flightsClimbed, unit: HKUnit.count()) { flights in
            healthData["flights_climbed_today"] = Int(flights)
            group.leave()
        }
        
        // MARK: - Heart & Cardiovascular
        group.enter()
        fetchHeartRateAverage(from: startOfDay, to: now) { heartRate in
            healthData["heart_rate_avg_today"] = Int(heartRate)
            group.leave()
        }
        
        group.enter()
        fetchQuantityAverage(from: startOfDay, to: now, identifier: .restingHeartRate, unit: HKUnit(from: "count/min")) { restingHR in
            healthData["resting_heart_rate_avg_week"] = Int(restingHR)
            group.leave()
        }
        
        group.enter()
        fetchQuantityAverage(from: startOfDay, to: now, identifier: .heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli)) { hrv in
            healthData["heart_rate_variability_avg_week"] = Int(hrv)
            group.leave()
        }
        
        // MARK: - Energy & Nutrition
        group.enter()
        fetchQuantitySum(from: startOfDay, to: now, identifier: .basalEnergyBurned, unit: HKUnit.kilocalorie()) { restingCalories in
            healthData["resting_calories_today"] = Int(restingCalories)
            group.leave()
        }
        
        group.enter()
        fetchQuantitySum(from: startOfDay, to: now, identifier: .dietaryEnergyConsumed, unit: HKUnit.kilocalorie()) { dietaryCalories in
            healthData["dietary_energy_today"] = Int(dietaryCalories)
            group.leave()
        }
        
        // MARK: - Body Measurements (latest values)
        group.enter()
        fetchLatestQuantity(identifier: .bodyMass, unit: HKUnit.gramUnit(with: .kilo)) { weight in
            healthData["weight_kg"] = Double(String(format: "%.1f", weight)) ?? weight
            group.leave()
        }
        
        group.enter()
        fetchLatestQuantity(identifier: .height, unit: HKUnit.meter()) { height in
            healthData["height_meters"] = Double(String(format: "%.2f", height)) ?? height
            group.leave()
        }
        
        // MARK: - Blood Pressure (latest readings)
        group.enter()
        fetchLatestQuantity(identifier: .bloodPressureSystolic, unit: HKUnit.millimeterOfMercury()) { systolic in
            healthData["systolic_blood_pressure"] = Int(systolic)
            group.leave()
        }
        
        group.enter()
        fetchLatestQuantity(identifier: .bloodPressureDiastolic, unit: HKUnit.millimeterOfMercury()) { diastolic in
            healthData["diastolic_blood_pressure"] = Int(diastolic)
            group.leave()
        }
        
        // MARK: - Respiratory & Vitals
        group.enter()
        fetchQuantityAverage(from: startOfDay, to: now, identifier: .respiratoryRate, unit: HKUnit(from: "count/min")) { respRate in
            healthData["respiratory_rate_avg_week"] = Int(respRate)
            group.leave()
        }
        
        // MARK: - Sleep Analysis
        group.enter()
        fetchSleepData(from: calendar.date(byAdding: .day, value: -1, to: startOfDay) ?? startOfDay, to: startOfDay) { sleepData in
            healthData["sleep_hours_last_night"] = sleepData["total_hours"]
            healthData["sleep_quality_last_night"] = sleepData["quality"]
            group.leave()
        }
        
        // MARK: - Mindfulness
        group.enter()
        fetchMindfulMinutes(from: startOfDay, to: now) { mindfulMinutes in
            healthData["mindful_minutes_today"] = Int(mindfulMinutes)
            group.leave()
        }
        
        // MARK: - Environmental
        group.enter()
        fetchQuantityAverage(from: startOfDay, to: now, identifier: .environmentalAudioExposure, unit: HKUnit.decibelHearingLevel()) { soundLevel in
            healthData["environmental_sound_level_today"] = Int(soundLevel)
            group.leave()
        }
        
        // MARK: - Workout Summary
        group.enter()
        fetchWorkoutSummary(from: startOfDay, to: now) { workoutData in
            healthData["workouts_today"] = workoutData["count"]
            healthData["workout_duration_minutes_today"] = workoutData["total_duration"]
            group.leave()
        }
        
        // MARK: - API Communication (Background Thread)
        group.notify(queue: .global(qos: .background)) {
            DispatchQueue.main.async {
                self.lastHealthData = healthData
                self.healthStatus = "Comprehensive data collected - \(healthData.count) metrics"
            }
            
            // Send to API on background thread
            self.sendHealthDataToAPI(healthData)
            
            // Submit header stats to Django API
            self.submitHeaderStats()
        }
    }
    
    // New method specifically for auto-logging with simplified data
    private func fetchEssentialHealthDataForAPI() {
        let group = DispatchGroup()
        var healthData: [String: Any] = [:]
        
        // Get date ranges
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        // Fetch only heart rate and steps for the API (as per the example)
        group.enter()
        fetchSteps(from: startOfDay, to: now) { steps in
            healthData["steps"] = steps
            group.leave()
        }
        
        group.enter()
        fetchHeartRateAverage(from: startOfDay, to: now) { heartRate in
            healthData["heart_rate"] = Int(heartRate)
            group.leave()
        }
        
        group.notify(queue: .global(qos: .background)) {
            self.sendHealthDataToAPI(healthData)
        }
    }

    // MARK: - Optimized Data Fetcher Methods
    
    // Generic quantity sum fetcher
    private func fetchQuantitySum(from startDate: Date, to endDate: Date, identifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(0)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
            completion(value)
        }
        
        healthStore.execute(query)
    }
    
    // Workout summary fetcher
    private func fetchWorkoutSummary(from startDate: Date, to endDate: Date, completion: @escaping ([String: Any]) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            
            var totalDuration: Double = 0
            var workoutCount = 0
            
            if let workouts = samples as? [HKWorkout] {
                workoutCount = workouts.count
                
                for workout in workouts {
                    totalDuration += workout.duration / 60 // Convert to minutes
                }
            }
            
            let summary: [String: Any] = [
                "count": workoutCount,
                "total_duration": totalDuration
            ]
            
            completion(summary)
        }
        
        healthStore.execute(query)
    }
    
    // Heart rate average fetcher
    private func fetchHeartRateAverage(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(0)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
            let heartRate = result?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 0
            completion(heartRate)
        }
        
        healthStore.execute(query)
    }
    
    // Individual Health Metric Fetchers
    private func fetchSteps(from startDate: Date, to endDate: Date, completion: @escaping (Int) -> Void) {
        fetchQuantitySum(from: startDate, to: endDate, identifier: .stepCount, unit: HKUnit.count()) { steps in
            completion(Int(steps))
        }
    }
    
    // MARK: - Additional Data Fetcher Methods
    
    // Generic quantity average fetcher
    private func fetchQuantityAverage(from startDate: Date, to endDate: Date, identifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(0)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
            let value = result?.averageQuantity()?.doubleValue(for: unit) ?? 0
            completion(value)
        }
        
        healthStore.execute(query)
    }
    
    // Latest quantity value fetcher (for body measurements, blood pressure, etc.)
    private func fetchLatestQuantity(identifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(0)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                completion(0)
                return
            }
            let value = sample.quantity.doubleValue(for: unit)
            completion(value)
        }
        
        healthStore.execute(query)
    }
    
    // Sleep data fetcher
    private func fetchSleepData(from startDate: Date, to endDate: Date, completion: @escaping ([String: Any]) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion([:])
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            
            guard let sleepSamples = samples as? [HKCategorySample] else {
                completion([:])
                return
            }
            
            var totalSleepSeconds: TimeInterval = 0
            var deepSleepSeconds: TimeInterval = 0
            var remSleepSeconds: TimeInterval = 0
            
            for sample in sleepSamples {
                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                
                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                     HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    totalSleepSeconds += duration
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    totalSleepSeconds += duration
                    deepSleepSeconds += duration
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    totalSleepSeconds += duration
                    remSleepSeconds += duration
                default:
                    break
                }
            }
            
            let totalHours = totalSleepSeconds / 3600.0
            let sleepQuality = totalSleepSeconds > 0 ? (deepSleepSeconds + remSleepSeconds) / totalSleepSeconds : 0
            
            let result: [String: Any] = [
                "total_hours": Double(String(format: "%.1f", totalHours)) ?? totalHours,
                "quality": Double(String(format: "%.2f", sleepQuality)) ?? sleepQuality
            ]
            
            completion(result)
        }
        
        healthStore.execute(query)
    }
    
    // Mindful minutes fetcher
    private func fetchMindfulMinutes(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            completion(0)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKSampleQuery(sampleType: mindfulType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            
            guard let mindfulSamples = samples as? [HKCategorySample] else {
                completion(0)
                return
            }
            
            var totalMinutes: TimeInterval = 0
            for sample in mindfulSamples {
                totalMinutes += sample.endDate.timeIntervalSince(sample.startDate)
            }
            
            completion(totalMinutes / 60.0) // Convert to minutes
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Header Stats Submission
    
    /// Submit header stats to Django API with collected health data
    private func submitHeaderStats() {
        guard !currentUsername.isEmpty,
              let healthData = lastHealthData else { return }
        
        Task {
            do {
                let emotionService = EmotionAnalysisService()
                
                // Extract key metrics for header stats
                let steps = healthData["steps_today"] as? Int ?? 0
                let heartRate = healthData["heart_rate_avg_today"] as? Int ?? 0
                let sleepHours = healthData["sleep_hours_last_night"] as? Double ?? 0
                let activeEnergy = healthData["active_calories_today"] as? Int ?? 0
                
                // Determine mood based on user analysis or default
                let mood = determineMoodFromHealthData(healthData)
                
                // Submit to Django API
                try await emotionService.submitHeaderStats(
                    username: currentUsername,
                    mood: mood,
                    energy: activeEnergy,
                    sleepHours: sleepHours,
                    heartRate: heartRate > 0 ? heartRate : nil,
                    steps: steps > 0 ? steps : nil
                )
                
                DispatchQueue.main.async {
                    print("✅ Header stats submitted successfully for user: \(self.currentUsername)")
                }
                
            } catch {
                DispatchQueue.main.async {
                    print("❌ Failed to submit header stats: \(error)")
                }
            }
        }
    }
    
    /// Force refresh header stats with today's latest data only
    public func refreshTodaysHeaderStats() {
        guard !currentUsername.isEmpty else {
            print("⚠️ Cannot refresh header stats: No username set")
            return
        }
        
        print("🔄 Refreshing today's header stats...")
        
        // Fetch only today's data (no aggregation)
        let group = DispatchGroup()
        var todaysHealthData: [String: Any] = [:]
        
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        // Fetch today's steps
        group.enter()
        fetchSteps(from: startOfToday, to: now) { steps in
            todaysHealthData["steps_today"] = steps
            group.leave()
        }
        
        // Fetch today's heart rate average
        group.enter()
        fetchHeartRateAverage(from: startOfToday, to: now) { heartRate in
            todaysHealthData["heart_rate_avg_today"] = Int(heartRate)
            group.leave()
        }
        
        // Fetch today's active calories
        group.enter()
        fetchQuantitySum(from: startOfToday, to: now, identifier: .activeEnergyBurned, unit: HKUnit.kilocalorie()) { calories in
            todaysHealthData["active_calories_today"] = Int(calories)
            group.leave()
        }
        
        // Fetch last night's sleep
        group.enter()
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday
        fetchSleepData(from: startOfYesterday, to: startOfToday) { sleepData in
            todaysHealthData["sleep_hours_last_night"] = sleepData["total_hours"]
            group.leave()
        }
        
        group.notify(queue: .main) {
            // Update the current health data with today's values
            self.lastHealthData = todaysHealthData
            self.healthStatus = "Today's data refreshed - \(todaysHealthData.count) metrics"
            
            // Submit fresh header stats
            Task {
                do {
                    let emotionService = EmotionAnalysisService()
                    
                    let steps = todaysHealthData["steps_today"] as? Int ?? 0
                    let heartRate = todaysHealthData["heart_rate_avg_today"] as? Int ?? 0
                    let sleepHours = todaysHealthData["sleep_hours_last_night"] as? Double ?? 0
                    let activeEnergy = todaysHealthData["active_calories_today"] as? Int ?? 0
                    
                    let mood = self.determineMoodFromHealthData(todaysHealthData)
                    
                    try await emotionService.submitHeaderStats(
                        username: self.currentUsername,
                        mood: mood,
                        energy: activeEnergy,
                        sleepHours: sleepHours,
                        heartRate: heartRate > 0 ? heartRate : nil,
                        steps: steps > 0 ? steps : nil
                    )
                    
                    DispatchQueue.main.async {
                        print("✅ Today's header stats refreshed and submitted")
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        print("❌ Failed to submit refreshed header stats: \(error)")
                    }
                }
            }
        }
    }
    
    /// Determine mood from health data patterns
    private func determineMoodFromHealthData(_ healthData: [String: Any]) -> String {
        let steps = healthData["steps_today"] as? Int ?? 0
        let activeCalories = healthData["active_calories_today"] as? Int ?? 0
        let sleepHours = healthData["sleep_hours_last_night"] as? Double ?? 0
        let heartRate = healthData["heart_rate_avg_today"] as? Int ?? 0
        
        // Simple mood determination logic based on health metrics
        if steps > 8000 && activeCalories > 300 && sleepHours > 7 {
            return "energetic"
        } else if steps > 5000 && sleepHours > 6 {
            return "balanced"
        } else if sleepHours < 5 || heartRate > 90 {
            return "tired"
        } else {
            return "neutral"
        }
    }
    
    // MARK: - API Communication (Centralized APIManager)
    private func sendHealthDataToAPI(_ healthData: [String: Any]) {
        let actualUsername = currentUsername.isEmpty ? "guest" : currentUsername
        
        DispatchQueue.main.async {
            self.healthStatus = "Sending health data to API..."
        }
        
        // Use the new logger API for health data
        apiManager.insertHealth(username: actualUsername, healthData: healthData) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.healthStatus = "Health data sent successfully: \(response.message)"
                case .failure(let error):
                    self?.healthStatus = "Error sending health data: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - User Analysis Methods
    func fetchUserAnalysis() {
        guard !currentUsername.isEmpty else {
            DispatchQueue.main.async {
                self.analysisStatus = "No username available"
            }
            return
        }
        
        isLoadingAnalysis = true
        analysisStatus = "Loading user analysis..."
        
        apiManager.fetchUserAnalysis(for: currentUsername) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingAnalysis = false
                
                switch result {
                case .success(let analysis):
                    self?.userAnalysis = analysis
                    self?.analysisStatus = "Analysis loaded successfully"
                case .failure(let error):
                    self?.analysisStatus = "Error loading analysis: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Combined Health Data and Analysis
    func fetchHealthDataAndAnalysis() {
        guard isAuthorized else {
            healthStatus = "Health access not authorized"
            return
        }
        
        // First fetch health data
        fetchEssentialHealthDataForAPI()
        
        // Then fetch user analysis
        fetchUserAnalysis()
    }
    
    // MARK: - Combined API Call (Send Health Data + Fetch Analysis)
    func sendHealthDataAndFetchAnalysis() {
        guard isAuthorized else {
            healthStatus = "Health access not authorized"
            return
        }
        
        guard !currentUsername.isEmpty else {
            analysisStatus = "No username available"
            return
        }
        
        // Get current health data
        guard let healthData = lastHealthData else {
            healthStatus = "No health data available"
            return
        }
        
        isLoadingAnalysis = true
        analysisStatus = "Sending health data and fetching analysis..."
        
        apiManager.sendHealthDataAndFetchAnalysis(username: currentUsername, healthData: healthData) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingAnalysis = false
                
                switch result {
                case .success(let analysis):
                    self?.userAnalysis = analysis
                    self?.analysisStatus = "Analysis loaded successfully"
                    self?.healthStatus = "Health data sent and analysis received"
                case .failure(let error):
                    self?.analysisStatus = "Error: \(error.localizedDescription)"
                    self?.healthStatus = "Error in combined operation"
                }
            }
        }
    }
    
    // MARK: - Test Data (Updated for new API format)
    func sendTestHealthData() {
        let testHealthData: [String: Any] = [
            "heart_rate": 72,
            "steps": 4000
        ]
        
        lastHealthData = testHealthData
        
        // Send on background thread
        DispatchQueue.global(qos: .background).async {
            self.sendHealthDataToAPI(testHealthData)
        }
    }
    
    // MARK: - Manual Health Data Log
    func logHealthDataNow() {
        guard isAuthorized else {
            healthStatus = "Health access not authorized"
            return
        }
        
        fetchEssentialHealthDataForAPI()
    }
    
    // MARK: - Comprehensive Test Method
    /// This method demonstrates the complete flow of the health data and analysis system
    /// It shows how the username is correctly used and how data flows between APIs
    func testCompleteHealthAndAnalysisFlow() {
        // Step 1: Verify we have a valid username
        guard !currentUsername.isEmpty else {
            healthStatus = "Cannot test: No username set"
            analysisStatus = "Cannot test: No username set"
            return
        }
        
        // Step 2: Test health data sending
        healthStatus = "Testing health data API..."
        let testHealthData: [String: Any] = [
            "heart_rate": 75,
            "steps": 8500,
            "active_calories": 320,
            "exercise_minutes": 45
        ]
        
        lastHealthData = testHealthData
        
        // Step 3: Send health data and fetch analysis in one call
        sendHealthDataAndFetchAnalysis()
    }
    
    // MARK: - Individual API Tests
    /// Test only the health data API (useful for debugging)
    func testHealthDataAPI() {
        guard !currentUsername.isEmpty else {
            healthStatus = "Cannot test: No username set"
            return
        }
        
        let testData: [String: Any] = [
            "heart_rate": 72,
            "steps": 4000
        ]
        
        sendHealthDataToAPI(testData)
    }
    
    /// Test only the user analysis API (useful for debugging)
    func testUserAnalysisAPI() {
        guard !currentUsername.isEmpty else {
            analysisStatus = "Cannot test: No username set"
            return
        }
        
        fetchUserAnalysis()
    }
} 
