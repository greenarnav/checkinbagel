import SwiftUI
import Contacts

// MARK: - New Contact Analysis API Models
struct ContactAnalysisRequest: Codable {
    let username: String
    let phone_number: String
}

struct ContactAnalysisResponse: Codable {
    let city: String
    let emotion: ContactEmotionDetails
    let phonenumber: String
    let username: String
    
    struct ContactEmotionDetails: Codable {
        let behavior_factors: String
        let health_factors: String
        let predicted_emoji_id: Int
        let user_emotion_profile: String
    }
}

// MARK: - Sequential Contact Emotion Model for API Integration
struct SequentialContactEmotion: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let phoneNumber: String
    let city: String
    let emoji: String
    let emotionProfile: String
    let healthFactors: String
    let behaviorFactors: String
    let lastUpdated: Date
    let isApiUser: Bool // NEW: Track if user was found in API
    
    // API-based initializer for real users found in the API
    init(name: String, phoneNumber: String, apiData: ContactEmotionData) {
        self.id = UUID()
        self.name = name
        self.phoneNumber = phoneNumber
        self.city = apiData.city
        self.emoji = ContactProfileHelpers.emojiForID(apiData.emotion.predictedEmojiId)
        self.emotionProfile = apiData.emotion.userEmotionProfile
        self.healthFactors = apiData.emotion.healthFactors
        self.behaviorFactors = apiData.emotion.behaviorFactors
        self.lastUpdated = Date()
        self.isApiUser = true
    }
    
    // Non-user initializer for contacts not found in API
    init(name: String, phoneNumber: String) {
        self.id = UUID()
        self.name = name
        self.phoneNumber = phoneNumber
        self.city = "Location Unknown"
        self.emoji = "neutral-face" // Neutral emoji for non-users
        self.emotionProfile = "Not a user - This contact is not registered on the platform"
        self.healthFactors = "Not a user"
        self.behaviorFactors = "Not a user"
        self.lastUpdated = Date()
        self.isApiUser = false
    }

    // Equatable implementation
    static func == (lhs: SequentialContactEmotion, rhs: SequentialContactEmotion) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.phoneNumber == rhs.phoneNumber
    }
}

// MARK: - Contact Analysis Service with Real API Integration
class SequentialContactAnalysisService: ObservableObject {
    static let shared = SequentialContactAnalysisService()
    
    @Published var contactEmotions: [SequentialContactEmotion] = []
    @Published var isAnalyzing = false
    @Published var currentlyAnalyzing: String? = nil
    @Published var errorMessage: String? = nil
    
    private init() {}
    
    // MARK: - Contact Management
    func updateSelectedContacts(_ contacts: [Contact]) {
        // Clear existing emotions when contacts change
        contactEmotions = []
        errorMessage = nil
        
        // Auto-start API analysis for new contacts
        if !contacts.isEmpty && !isAnalyzing {
            startSequentialAnalysis(for: contacts)
        }
    }
    
    func startSequentialAnalysis(for contacts: [Contact]) {
        guard !contacts.isEmpty && !isAnalyzing else { return }
        
        // Clear existing emotions
        contactEmotions = []
        errorMessage = nil
        
        // Start API-based analysis
        analyzeContactsWithAPI(contacts)
    }
    
    private func analyzeContactsWithAPI(_ contacts: [Contact]) {
        guard !contacts.isEmpty else {
            isAnalyzing = false
            currentlyAnalyzing = nil
            return
        }
        
        isAnalyzing = true
        
        Task {
            var newEmotions: [SequentialContactEmotion] = []
            let emotionService = EmotionAnalysisService()
            
            // Analyze each contact individually using the new API
            for contact in contacts {
                await MainActor.run {
                    self.currentlyAnalyzing = contact.name
                }
                
                do {
                    // Call the new single contact API
                    let emotionData = try await emotionService.analyzeContactByPhone(phone: contact.phoneNumber)
                    
                    // Use the API-based initializer
                    let contactEmotion = SequentialContactEmotion(
                        name: contact.name,
                        phoneNumber: contact.phoneNumber,
                        apiData: emotionData
                    )
                    
                    newEmotions.append(contactEmotion)
                } catch {
                    print("❌ Failed to analyze contact \(contact.name): \(error)")
                    
                    // Add fallback emotion data using the non-user initializer
                    let fallbackEmotion = SequentialContactEmotion(
                        name: contact.name,
                        phoneNumber: contact.phoneNumber
                    )
                    
                    newEmotions.append(fallbackEmotion)
                }
            }
            
            // Sort contacts by name
            let sortedEmotions = newEmotions.sorted { $0.name < $1.name }
            
            await MainActor.run {
                self.contactEmotions = sortedEmotions
                self.currentlyAnalyzing = nil
                self.isAnalyzing = false
                self.errorMessage = nil
                
                print("✅ Contact analysis completed for \(contacts.count) contacts")
            }
        }
    }
}

// MARK: - Contacts Manager (instant emotions + real device contacts)
class ContactsManager: ObservableObject {
    @Published var allContacts: [DeviceContact] = []
    @Published var groupedContacts: [GroupedContact] = []
    @Published var permissionError: String? = nil
    @Published var isLoading: Bool = false
    
    // Sequential contact analysis - NOW INSTANT!
    @Published var selectedContacts: [String: String] = [:] // Name: Phone
    @Published var contactEmotions: [SequentialContactEmotion] = [] {
        didSet {
    
        }
    }
    @Published var isAnalyzing = false
    @Published var currentlyAnalyzing: String? = nil
    @Published var errorMessage: String? = nil
    
    // MARK: - Header Stats Management
    @Published var contactHeaderStats: [String: ContactHeaderStats] = [:] // Phone: HeaderStats
    @Published var isLoadingHeaderStats = false
    @Published var headerStatsError: String? = nil
    
    private let maxContacts = 12
    
    var hasMaxContacts: Bool {
        selectedContacts.count >= maxContacts
    }
    
    // MARK: – Real Device Contacts API
    func refreshContactsIfPermitted() {
        loadRealDeviceContacts()
    }
    
    private func loadRealDeviceContacts() {
        isLoading = true
        permissionError = nil
        
        // Add safety check for contacts framework availability
        guard CNContactStore.authorizationStatus(for: .contacts) != .restricted else {
            DispatchQueue.main.async {
                self.permissionError = "Contacts access is restricted on this device."
                self.isLoading = false
            }
            return
        }
        
        let contactStore = CNContactStore()
        
        // Check permission
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            fetchContacts(from: contactStore)
        case .notDetermined:
            contactStore.requestAccess(for: .contacts) { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        self.fetchContacts(from: contactStore)
                    } else {
                        self.permissionError = "Contacts access denied. Please enable in Settings."
                        self.isLoading = false
                    }
                }
            }
        case .denied, .restricted:
            self.permissionError = "Contacts access denied. Please enable in Settings > Privacy > Contacts."
            self.isLoading = false
        case .limited:
            // iOS 14+ limited contacts access
            fetchContacts(from: contactStore)
        @unknown default:
            self.permissionError = "Unknown contacts permission status."
            self.isLoading = false
        }
    }
    
    private func fetchContacts(from store: CNContactStore) {
        let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        
        var deviceContacts: [DeviceContact] = []
        
        do {
            try store.enumerateContacts(with: request) { contact, stop in
                // Add safety checks for contact data
                guard !contact.givenName.isEmpty || !contact.familyName.isEmpty else {
                    return // Skip contacts without names
                }
                
                let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                
                // Skip contacts without names
                guard !fullName.isEmpty else { return }
                
                // Extract phone number (use first available phone number)
                let rawPhoneNumber = contact.phoneNumbers.first?.value.stringValue ?? ""
                
                // Skip contacts without phone numbers (API requires phone numbers)
                guard !rawPhoneNumber.isEmpty else { return }
                
                // Clean the phone number
                let phoneNumber = ContactProfileHelpers.cleanPhoneNumber(rawPhoneNumber)
                
                // Create initials safely
                let names = fullName.components(separatedBy: " ").filter { !$0.isEmpty }
                let initials = names.compactMap { $0.first }.map { String($0) }.joined()
                
                let deviceContact = DeviceContact(
                    name: fullName,
                    initials: String(initials.prefix(2)).uppercased(),
                    phoneNumber: phoneNumber
                )
                
                deviceContacts.append(deviceContact)
                
                // Stop enumeration if we have too many contacts (prevent memory issues)
                if deviceContacts.count >= 1000 {
                    stop.pointee = true
                }
            }
            
            DispatchQueue.main.async {
                // Sort contacts alphabetically
                self.allContacts = deviceContacts.sorted { $0.name < $1.name }
                
                // Create grouped contacts
                self.groupedContacts = self.createGroupedContacts(from: self.allContacts)
                
                self.isLoading = false

            }
            
        } catch {
            DispatchQueue.main.async {
                self.permissionError = "Failed to load contacts: \(error.localizedDescription)"
                self.isLoading = false

            }
        }
    }
    
    // MARK: - INSTANT Contact Analysis
    
    func removeContact(name: String) {
        selectedContacts.removeValue(forKey: name)
        contactEmotions.removeAll { $0.name == name }
    }
    
    // MARK: - Header Stats Management
    
    /// Fetch header stats for a specific contact
    func fetchHeaderStats(for contact: Contact) {
        fetchHeaderStats(for: contact.phoneNumber)
    }
    
    /// Fetch header stats for a contact by phone number
    func fetchHeaderStats(for phoneNumber: String) {
        guard !phoneNumber.isEmpty else { return }
        
        Task {
            do {
                let emotionService = EmotionAnalysisService()
                let headerStats = try await emotionService.getLatestHeaderStats(for: phoneNumber)
                
                await MainActor.run {
                    self.contactHeaderStats[phoneNumber] = headerStats
                    self.headerStatsError = nil
                }
            } catch {
                await MainActor.run {
                    self.headerStatsError = "Failed to fetch header stats: \(error.localizedDescription)"
                    print("❌ Error fetching header stats for \(phoneNumber): \(error)")
                }
            }
        }
    }
    
    /// Fetch header stats for multiple contacts
    func fetchHeaderStats(for contacts: [Contact]) {
        isLoadingHeaderStats = true
        headerStatsError = nil
        
        Task {
            let emotionService = EmotionAnalysisService()
            var fetchedStats: [String: ContactHeaderStats] = [:]
            var errors: [String] = []
            
            // Process contacts sequentially to avoid concurrency issues
            for contact in contacts {
                do {
                    let stats = try await emotionService.getLatestHeaderStats(for: contact.phoneNumber)
                    fetchedStats[contact.phoneNumber] = stats
                } catch {
                    errors.append("Failed to fetch stats for \(contact.phoneNumber): \(error.localizedDescription)")
                }
            }
            
            // Update UI on main thread
            await MainActor.run {
                self.contactHeaderStats.merge(fetchedStats) { _, new in new }
                self.headerStatsError = errors.isEmpty ? nil : errors.joined(separator: "\n")
                self.isLoadingHeaderStats = false
            }
        }
    }
    
    /// Get header stats for a specific phone number
    func getHeaderStats(for phoneNumber: String) -> ContactHeaderStats? {
        return contactHeaderStats[phoneNumber]
    }
    
    /// Check if header stats are available for a contact
    func hasHeaderStats(for phoneNumber: String) -> Bool {
        return contactHeaderStats[phoneNumber] != nil
    }
    
    // MARK: - Grouped Contacts Management
    
    /// Groups contacts by name and combines phone numbers for same person
    private func createGroupedContacts(from contacts: [DeviceContact]) -> [GroupedContact] {
        var grouped: [String: [String]] = [:]
        
        // Group contacts by name
        for contact in contacts {
            if grouped[contact.name] != nil {
                grouped[contact.name]?.append(contact.phoneNumber)
            } else {
                grouped[contact.name] = [contact.phoneNumber]
            }
        }
        
        // Create GroupedContact objects
        let groupedContacts = grouped.map { name, phoneNumbers in
            GroupedContact(name: name, phoneNumbers: phoneNumbers)
        }
        
        return groupedContacts.sorted { $0.name < $1.name }
    }
    
    /// Update a contact's name (for when same name refers to different people)
    func updateContactName(contactId: UUID, newName: String) {
        if let index = groupedContacts.firstIndex(where: { $0.id == contactId }) {
            // Update grouped contact
            var updatedContact = groupedContacts[index]
            updatedContact.name = newName
            
            // Recreate initials
            let names = newName.components(separatedBy: " ").filter { !$0.isEmpty }
            let initials = names.compactMap { $0.first }.map { String($0) }.joined()
            updatedContact.initials = String(initials.prefix(2)).uppercased()
            
            groupedContacts[index] = updatedContact
            
            // Also update the original allContacts array
            updateOriginalContacts(oldName: updatedContact.name, newName: newName)
        }
    }
    
    /// Split a contact with multiple numbers into separate contacts
    func splitContact(contactId: UUID, keepNumbers: [String], newName: String, newNumbers: [String]) {
        guard let index = groupedContacts.firstIndex(where: { $0.id == contactId }) else { return }
        
        // Update existing contact with kept numbers
        var existingContact = groupedContacts[index]
        existingContact.phoneNumbers = keepNumbers
        groupedContacts[index] = existingContact
        
        // Create new contact with new name and numbers
        let newContact = GroupedContact(name: newName, phoneNumbers: newNumbers)
        groupedContacts.append(newContact)
        
        // Sort again
        groupedContacts.sort { $0.name < $1.name }
    }
    
    private func updateOriginalContacts(oldName: String, newName: String) {
        for i in allContacts.indices {
            if allContacts[i].name == oldName {
                allContacts[i].name = newName
                
                // Update initials
                let names = newName.components(separatedBy: " ").filter { !$0.isEmpty }
                let initials = names.compactMap { $0.first }.map { String($0) }.joined()
                allContacts[i].initials = String(initials.prefix(2)).uppercased()
            }
        }
    }
    
    /// Split a contact with multiple numbers into separate individual contacts
    func splitContactIntoSeparateContacts(contactId: UUID) {
        guard let index = groupedContacts.firstIndex(where: { $0.id == contactId }) else { return }
        
        let contactToSplit = groupedContacts[index]
        
        // Only split if there are multiple numbers
        guard contactToSplit.hasMultipleNumbers else { return }
        
        // Remove the original grouped contact
        groupedContacts.remove(at: index)
        
        // Create separate contacts for each phone number
        for (numberIndex, phoneNumber) in contactToSplit.phoneNumbers.enumerated() {
            let newName = if numberIndex == 0 {
                contactToSplit.name // Keep original name for first number
            } else {
                "\(contactToSplit.name) (\(numberIndex + 1))" // Add number suffix for others
            }
            
            let newContact = GroupedContact(name: newName, phoneNumbers: [phoneNumber])
            groupedContacts.append(newContact)
        }
        
        // Sort contacts alphabetically
        groupedContacts.sort { $0.name < $1.name }
        
        // Also update the original allContacts array
        updateOriginalContactsAfterSplit(originalName: contactToSplit.name, phoneNumbers: contactToSplit.phoneNumbers)
        

    }
    
    /// Merge contacts with similar names (e.g., "Alex", "Alex (2)", "Alex (3)") back into one contact
    func mergeSimilarContacts(baseName: String) {
        let baseNameOnly = baseName.components(separatedBy: " (").first ?? baseName
        
        // Find all contacts with the same base name
        let contactsToMerge = groupedContacts.filter { contact in
            let contactBaseName = contact.name.components(separatedBy: " (").first ?? contact.name
            return contactBaseName == baseNameOnly
        }
        
        guard contactsToMerge.count > 1 else {
            return
        }
        
        // Collect all phone numbers
        var allPhoneNumbers: [String] = []
        for contact in contactsToMerge {
            allPhoneNumbers.append(contentsOf: contact.phoneNumbers)
        }
        
        // Remove duplicates
        allPhoneNumbers = Array(Set(allPhoneNumbers))
        
        // Remove all the separate contacts
        for contact in contactsToMerge {
            if let index = groupedContacts.firstIndex(where: { $0.id == contact.id }) {
                groupedContacts.remove(at: index)
            }
        }
        
        // Create new merged contact with original base name
        let mergedContact = GroupedContact(name: baseNameOnly, phoneNumbers: allPhoneNumbers)
        groupedContacts.append(mergedContact)
        
        // Sort contacts alphabetically
        groupedContacts.sort { $0.name < $1.name }
        
        // Also update the original allContacts array
        updateOriginalContactsAfterMerge(baseName: baseNameOnly, phoneNumbers: allPhoneNumbers, contactsToMerge: contactsToMerge)
        

    }
    
    private func updateOriginalContactsAfterMerge(baseName: String, phoneNumbers: [String], contactsToMerge: [GroupedContact]) {
        // Remove all the split contacts from allContacts
        for contact in contactsToMerge {
            for phoneNumber in contact.phoneNumbers {
                allContacts.removeAll { $0.phoneNumber == phoneNumber }
            }
        }
        
        // Add back as merged contacts
        for (_, phoneNumber) in phoneNumbers.enumerated() {
            let deviceContact = DeviceContact(
                name: baseName,
                initials: String(baseName.prefix(2)).uppercased(),
                phoneNumber: phoneNumber
            )
            allContacts.append(deviceContact)
        }
        
        // Sort contacts alphabetically
        allContacts.sort { $0.name < $1.name }
    }
    
    private func updateOriginalContactsAfterSplit(originalName: String, phoneNumbers: [String]) {
        // Find all DeviceContacts with this name and update their names to match the split
        for i in allContacts.indices {
            if allContacts[i].name == originalName {
                if let phoneIndex = phoneNumbers.firstIndex(of: allContacts[i].phoneNumber) {
                    if phoneIndex > 0 {
                        // Update name for non-first numbers
                        let newName = "\(originalName) (\(phoneIndex + 1))"
                        allContacts[i].name = newName
                        
                        // Update initials
                        let names = newName.components(separatedBy: " ").filter { !$0.isEmpty }
                        let initials = names.compactMap { $0.first }.map { String($0) }.joined()
                        allContacts[i].initials = String(initials.prefix(2)).uppercased()
                    }
                    // First contact keeps the original name
                }
            }
        }
    }
    
}

// MARK: - Following Sync Manager
class FollowingSyncManager: ObservableObject {
    static let shared = FollowingSyncManager()
    
    @Published var isSyncing = false
    @Published var syncStatus = "Not synced"
    @Published var lastSyncTime: Date?
    @Published var syncError: String?
    
    private let apiManager = APIManager.shared
    private let syncKey = "LastFollowingSyncTime"
    
    private init() {}
    
    // MARK: - Main Sync Method
    func syncFollowingList(username: String, pinnedContactsManager: PinnedContactsManager) {
        guard !username.isEmpty else {
            syncStatus = "No username provided"
            return
        }
        
        guard !isSyncing else {
            print("⚠️ Sync already in progress")
            return
        }
        
        isSyncing = true
        syncStatus = "Syncing..."
        syncError = nil
        
        print("🔄 Starting following list sync for user: \(username)")
        
        // Get local following list
        let localFollowing = pinnedContactsManager.pinnedContacts.map { $0.phoneNumber }
        print("📱 Local following list: \(localFollowing.count) contacts")
        
        // Fetch backend following list
        apiManager.getFollowing(user: username) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("☁️ Backend following list: \(response.following.count) contacts")
                    self?.reconcileFollowingLists(
                        username: username,
                        localFollowing: localFollowing,
                        backendFollowing: response.following,
                        pinnedContactsManager: pinnedContactsManager
                    )
                    
                case .failure(let error):
                    print("❌ Failed to fetch following list: \(error.localizedDescription)")
                    self?.syncError = error.localizedDescription
                    self?.syncStatus = "Sync failed"
                    self?.isSyncing = false
                    
                    // If API fails, continue with local data
                    if error.localizedDescription.contains("404") {
                        // User might not exist on backend yet, upload local data
                        self?.uploadLocalToBackend(username: username, localFollowing: localFollowing)
                    }
                }
            }
        }
    }
    
    // MARK: - Reconciliation Logic
    private func reconcileFollowingLists(
        username: String,
        localFollowing: [String],
        backendFollowing: [String],
        pinnedContactsManager: PinnedContactsManager
    ) {
        let localSet = Set(localFollowing)
        let backendSet = Set(backendFollowing)
        
        // Find differences
        let onlyInLocal = localSet.subtracting(backendSet)
        let onlyInBackend = backendSet.subtracting(localSet)
        
        print("📊 Sync Analysis:")
        print("   - Only in local: \(onlyInLocal.count) contacts")
        print("   - Only in backend: \(onlyInBackend.count) contacts")
        
        // Strategy: Merge both lists (union of both sets)
        // This ensures we don't lose any data from either side
        
        var syncOperations: [(String, Bool)] = [] // (phoneNumber, isFollow)
        
        // Add contacts that are only in backend to local
        for phoneNumber in onlyInBackend {
            // Check if we can still add more contacts (limit of 12)
            if pinnedContactsManager.pinnedContacts.count < 12 {
                let contact = Contact(
                    name: "Synced Contact", // We'll need to fetch actual names later
                    location: "Unknown",
                    mood: "neutral-face",
                    moodText: "Neutral",
                    phoneNumber: phoneNumber
                )
                pinnedContactsManager.pinContact(contact)
                print("➕ Added from backend: \(phoneNumber)")
            }
        }
        
        // Add contacts that are only in local to backend
        for phoneNumber in onlyInLocal {
            syncOperations.append((phoneNumber, true))
        }
        
        // Execute backend sync operations
        if !syncOperations.isEmpty {
            performBackendSyncOperations(username: username, operations: syncOperations)
        } else {
            completeSyncSuccess()
        }
    }
    
    // MARK: - Backend Operations
    private func performBackendSyncOperations(username: String, operations: [(String, Bool)]) {
        let group = DispatchGroup()
        var successCount = 0
        var failureCount = 0
        
        for (phoneNumber, isFollow) in operations {
            group.enter()
            
            if isFollow {
                apiManager.followUser(user: phoneNumber, follower: username) { result in
                    switch result {
                    case .success:
                        successCount += 1
                        print("✅ Synced to backend: following \(phoneNumber)")
                    case .failure(let error):
                        failureCount += 1
                        print("❌ Failed to sync: \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            print("🎯 Backend sync complete: \(successCount) succeeded, \(failureCount) failed")
            self?.completeSyncSuccess()
        }
    }
    
    // MARK: - Upload Local to Backend (for new users)
    private func uploadLocalToBackend(username: String, localFollowing: [String]) {
        guard !localFollowing.isEmpty else {
            completeSyncSuccess()
            return
        }
        
        print("📤 Uploading local following list to backend...")
        
        let group = DispatchGroup()
        var successCount = 0
        
        for phoneNumber in localFollowing {
            group.enter()
            
            apiManager.followUser(user: phoneNumber, follower: username) { result in
                if case .success = result {
                    successCount += 1
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            print("✅ Uploaded \(successCount)/\(localFollowing.count) contacts to backend")
            self?.completeSyncSuccess()
        }
    }
    
    // MARK: - Completion
    private func completeSyncSuccess() {
        lastSyncTime = Date()
        UserDefaults.standard.set(lastSyncTime, forKey: syncKey)
        syncStatus = "Synced successfully"
        isSyncing = false
        
        print("✅ Following list sync completed at \(lastSyncTime!)")
    }
    
    // MARK: - Helper Methods
    func shouldSync() -> Bool {
        // Sync if never synced or last sync was more than 1 hour ago
        guard let lastSync = UserDefaults.standard.object(forKey: syncKey) as? Date else {
            return true
        }
        
        let hoursSinceLastSync = Date().timeIntervalSince(lastSync) / 3600
        return hoursSinceLastSync > 1
    }
    
    func clearSyncData() {
        UserDefaults.standard.removeObject(forKey: syncKey)
        lastSyncTime = nil
        syncStatus = "Not synced"
        syncError = nil
    }
}
