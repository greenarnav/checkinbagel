import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var authorizationError: String?
    
    // Health data types we want to read
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        
        // Activity data
        if let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepCount)
        }
        if let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(distance)
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
        
        // Energy & Calories
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        if let restingEnergy = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) {
            types.insert(restingEnergy)
        }
        if let dietaryEnergy = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            types.insert(dietaryEnergy)
        }
        
        // Heart data
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let restingHeartRate = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHeartRate)
        }
        if let heartRateVariability = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(heartRateVariability)
        }
        
        // Blood Pressure
        if let systolic = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic) {
            types.insert(systolic)
        }
        if let diastolic = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) {
            types.insert(diastolic)
        }
        
        // Sleep & Mindfulness
        if let sleepAnalysis = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepAnalysis)
        }
        if let mindfulMinutes = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindfulMinutes)
        }
        
        // Body Measurements
        if let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(weight)
        }
        if let height = HKObjectType.quantityType(forIdentifier: .height) {
            types.insert(height)
        }
        if let bodyTemp = HKObjectType.quantityType(forIdentifier: .bodyTemperature) {
            types.insert(bodyTemp)
        }
        
        // Vitals
        if let bloodOxygen = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) {
            types.insert(bloodOxygen)
        }
        if let respiratoryRate = HKObjectType.quantityType(forIdentifier: .respiratoryRate) {
            types.insert(respiratoryRate)
        }
        
        // Environmental
        if let soundLevels = HKObjectType.quantityType(forIdentifier: .environmentalAudioExposure) {
            types.insert(soundLevels)
        }
        
        // Workouts & Exercise
        let workoutType = HKObjectType.workoutType()
        types.insert(workoutType)
        
        if let exerciseMinutes = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
            types.insert(exerciseMinutes)
        }
        
        // Personal Info
        if let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) {
            types.insert(dateOfBirth)
        }
        if let sex = HKObjectType.characteristicType(forIdentifier: .biologicalSex) {
            types.insert(sex)
        }
        
        return types
    }
    
    // Health data types we want to write (if any)
    private var writeTypes: Set<HKSampleType> {
        var types = Set<HKSampleType>()
        
        // Add mood as a custom type if needed in future
        // For now, we'll just read data
        
        return types
    }
    
    // Check if HealthKit is available
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    // Request authorization
    func requestAuthorization() {
        guard isHealthKitAvailable else {
            authorizationError = "HealthKit is not available on this device"
            return
        }
        
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if let error = error {
                    self?.authorizationError = error.localizedDescription
                } else if !success {
                    self?.authorizationError = "HealthKit authorization was denied"
                }
            }
        }
    }
    
    // Example: Get today's step count
    func getTodayStepCount(completion: @escaping (Double?) -> Void) {
        guard isAuthorized,
              let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsType, 
                                    quantitySamplePredicate: predicate, 
                                    options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    completion(nil)
                    return
                }
                
                let steps = sum.doubleValue(for: HKUnit.count())
                completion(steps)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Example: Get sleep data for last night
    func getLastNightSleep(completion: @escaping (TimeInterval?) -> Void) {
        guard isAuthorized,
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -1, to: endDate)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, 
                                predicate: predicate, 
                                limit: HKObjectQueryNoLimit, 
                                sortDescriptors: nil) { _, samples, error in
            DispatchQueue.main.async {
                guard let samples = samples as? [HKCategorySample] else {
                    completion(nil)
                    return
                }
                
                // Calculate total sleep duration
                var totalSleep: TimeInterval = 0
                for sample in samples {
                    if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue ||
                       sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                        totalSleep += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }
                
                completion(totalSleep)
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Enhanced Health Metrics for Top Bar
    
    // Get today's heart rate average
    func getTodayHeartRateAverage(completion: @escaping (Double?) -> Void) {
        guard isAuthorized,
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: heartRateType,
                                    quantitySamplePredicate: predicate,
                                    options: .discreteAverage) { _, result, error in
            DispatchQueue.main.async {
                guard let result = result,
                      let average = result.averageQuantity() else {
                    completion(nil)
                    return
                }
                
                let heartRate = average.doubleValue(for: HKUnit(from: "count/min"))
                completion(heartRate)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Get today's active calories
    func getTodayActiveCalories(completion: @escaping (Double?) -> Void) {
        guard isAuthorized,
              let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: activeEnergyType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    completion(nil)
                    return
                }
                
                let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                completion(calories)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Get today's walking distance
    func getTodayWalkingDistance(completion: @escaping (Double?) -> Void) {
        guard isAuthorized,
              let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: distanceType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    completion(nil)
                    return
                }
                
                let distance = sum.doubleValue(for: HKUnit.mile())
                completion(distance)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Get today's flights climbed
    func getTodayFlightsClimbed(completion: @escaping (Double?) -> Void) {
        guard isAuthorized,
              let flightsType = HKObjectType.quantityType(forIdentifier: .flightsClimbed) else {
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: flightsType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    completion(nil)
                    return
                }
                
                let flights = sum.doubleValue(for: HKUnit.count())
                completion(flights)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Get latest resting heart rate
    func getLatestRestingHeartRate(completion: @escaping (Double?) -> Void) {
        guard isAuthorized,
              let restingHeartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            completion(nil)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: restingHeartRateType,
                                predicate: nil,
                                limit: 1,
                                sortDescriptors: [sortDescriptor]) { _, samples, error in
            DispatchQueue.main.async {
                guard let sample = samples?.first as? HKQuantitySample else {
                    completion(nil)
                    return
                }
                
                let restingHR = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                completion(restingHR)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Get latest heart rate variability
    func getLatestHeartRateVariability(completion: @escaping (Double?) -> Void) {
        guard isAuthorized,
              let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            completion(nil)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: hrvType,
                                predicate: nil,
                                limit: 1,
                                sortDescriptors: [sortDescriptor]) { _, samples, error in
            DispatchQueue.main.async {
                guard let sample = samples?.first as? HKQuantitySample else {
                    completion(nil)
                    return
                }
                
                let hrv = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                completion(hrv)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Get today's exercise minutes
    func getTodayExerciseMinutes(completion: @escaping (Double?) -> Void) {
        guard isAuthorized,
              let exerciseType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) else {
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: exerciseType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    completion(nil)
                    return
                }
                
                let minutes = sum.doubleValue(for: HKUnit.minute())
                completion(minutes)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Get latest body temperature
    func getLatestBodyTemperature(completion: @escaping (Double?) -> Void) {
        guard isAuthorized,
              let bodyTempType = HKObjectType.quantityType(forIdentifier: .bodyTemperature) else {
            completion(nil)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: bodyTempType,
                                predicate: nil,
                                limit: 1,
                                sortDescriptors: [sortDescriptor]) { _, samples, error in
            DispatchQueue.main.async {
                guard let sample = samples?.first as? HKQuantitySample else {
                    completion(nil)
                    return
                }
                
                let temperature = sample.quantity.doubleValue(for: HKUnit.degreeFahrenheit())
                completion(temperature)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Get latest blood oxygen saturation
    func getLatestBloodOxygenSaturation(completion: @escaping (Double?) -> Void) {
        guard isAuthorized,
              let bloodOxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else {
            completion(nil)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: bloodOxygenType,
                                predicate: nil,
                                limit: 1,
                                sortDescriptors: [sortDescriptor]) { _, samples, error in
            DispatchQueue.main.async {
                guard let sample = samples?.first as? HKQuantitySample else {
                    completion(nil)
                    return
                }
                
                let oxygenSaturation = sample.quantity.doubleValue(for: HKUnit.percent()) * 100
                completion(oxygenSaturation)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Get latest respiratory rate
    func getLatestRespiratoryRate(completion: @escaping (Double?) -> Void) {
        guard isAuthorized,
              let respiratoryRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate) else {
            completion(nil)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: respiratoryRateType,
                                predicate: nil,
                                limit: 1,
                                sortDescriptors: [sortDescriptor]) { _, samples, error in
            DispatchQueue.main.async {
                guard let sample = samples?.first as? HKQuantitySample else {
                    completion(nil)
                    return
                }
                
                let respiratoryRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                completion(respiratoryRate)
            }
        }
        
        healthStore.execute(query)
    }
    

} 