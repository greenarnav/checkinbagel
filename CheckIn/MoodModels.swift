//
//  MoodModels.swift
//  moodgpt
//
//  Created by Test on 5/27/25.
//

import SwiftUI
import MapKit

// MARK: - Contact Model
struct Contact: Identifiable, Hashable, Codable {
    let id = UUID()
    let name: String
    let location: String
    var mood: String
    var moodText: String
    let phoneNumber: String
    
    // Enhanced fields for sentiment analysis
    var city: String? = nil
    var behaviorFactors: String? = nil
    var healthFactors: String? = nil
    var predictedEmojiId: Int? = nil
    var userEmotionProfile: String? = nil
    var lastSentimentUpdate: Date? = nil
    
    init(name: String, location: String, mood: String, moodText: String, phoneNumber: String) {
        self.name = name
        self.location = location
        self.mood = mood
        self.moodText = moodText
        self.phoneNumber = phoneNumber
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Contact Profile System
struct ContactProfile: Codable, Identifiable {
    let id = UUID()
    let contactName: String
    let city: String?
    let emotion: ContactEmotionDetail?
    let phoneNumber: String?
    let lastUpdated: Date
    
    struct ContactEmotionDetail: Codable {
        let behaviorFactors: String?
        let healthFactors: String?
        let predictedEmojiId: Int?
        let userEmotionProfile: String?
        
        // Computed properties for easier access
        var emoji: String {
            return ContactProfileHelpers.emojiForID(predictedEmojiId)
        }
        
        var emotionText: String {
            return ContactProfileHelpers.extractEmotionText(from: userEmotionProfile)
        }
    }
}

// MARK: - Contact Header Stats Model
struct ContactHeaderStats: Codable {
    let status: String
    let data: HeaderStatsData?
    
    struct HeaderStatsData: Codable {
        let username: String
        let mood: String?
        let energy: Int?
        let sleepHours: Double?
        let heartRate: Int?
        let steps: Int?
        let timestamp: String?
        
        enum CodingKeys: String, CodingKey {
            case username, mood, energy, timestamp
            case sleepHours = "sleep_hours"
            case heartRate = "heart_rate"
            case steps
        }
    }
}

// MARK: - Contact Profile Helpers
struct ContactProfileHelpers {
    
    // Enhanced EMOJI_MAP based on user requirements
    static let EMOJI_MAP: [Int: String] = [
        1: "😠", 2: "😧", 3: "😰", 4: "😲", 5: "🤕",
        6: "☹️", 7: "😊", 8: "🥶", 9: "😟", 10: "😢",
        11: "🤬", 12: "😕", 13: "😩", 14: "😵", 15: "🤤",
        16: "😮‍💨", 17: "😑", 18: "😳", 19: "🙁", 20: "😱",
        21: "😬", 22: "😅", 23: "😁", 24: "😀", 25: "🤭",
        26: "😂", 27: "🙂", 28: "🙃", 29: "😍", 30: "🥰",
        31: "🥺", 32: "🥵", 33: "🤗", 34: "😄", 35: "😚",
        36: "😘", 37: "☺️", 38: "😗", 39: "😆", 40: "😭",
        41: "🫠", 42: "🤯", 43: "🧐", 44: "😶", 45: "😮",
        46: "😐", 47: "🥳", 48: "🫣", 49: "😔", 50: "🥺",
        51: "😡", 52: "🤨", 53: "😌", 54: "🤣", 55: "🙄",
        56: "😞", 57: "😨", 58: "😱", 59: "😣", 60: "😖",
        61: "🫨", 62: "🤫", 63: "🤢", 64: "😄", 65: "😴",
        66: "😪", 67: "🙁", 68: "🙂", 69: "😃", 70: "😊",
        71: "😏", 72: "🤧", 73: "😝", 74: "🤩", 75: "😛",
        76: "😯", 77: "😓", 78: "🤒", 79: "🤔", 80: "😫",
        81: "😤", 82: "😒", 83: "🙃", 84: "🤮", 85: "😊",
        86: "😩", 87: "😉", 88: "😜", 89: "🥴", 90: "😰",
        91: "😵", 92: "🥱", 93: "😋", 94: "🤪", 95: "🤐"
    ]
    
    static let EMOJI_NAME_MAP: [Int: String] = [
        1: "angry", 2: "anguished", 3: "anxios-with-sweat", 4: "astonished", 5: "bandage-face",
        6: "big-frown", 7: "blush", 8: "cold-face", 9: "concerned", 10: "cry",
        11: "cursing", 12: "Diagonal-mouth", 13: "distraught", 14: "dizzy-face", 15: "drool",
        16: "exhale", 17: "expressionless", 18: "flushed", 19: "frown", 20: "gasp",
        21: "grimacing", 22: "grin-sweat", 23: "grin", 24: "grinning", 25: "hand-over-mouth",
        26: "happy-cry", 27: "head-nod", 28: "head-shake", 29: "heart-eyes", 30: "heart-face",
        31: "holding-back-tears", 32: "hot-face", 33: "hug-face", 34: "joy", 35: "kissing-closed-eyes",
        36: "kissing-heart", 37: "kissing-smile", 38: "kissing", 39: "laughing", 40: "loudly-crying",
        41: "melting", 42: "mind-blown", 43: "monocle", 44: "mouth-none", 45: "mouth-open",
        46: "neutral-face", 47: "partying-face", 48: "peeking", 49: "pensive", 50: "pleading",
        51: "rage", 52: "raised-eyebrow", 53: "relieved", 54: "rofl", 55: "rolling-eyes",
        56: "sad", 57: "scared", 58: "screaming", 59: "scrunched-eyes", 60: "scrunched-mouth",
        61: "shaking-face", 62: "shushing-face", 63: "sick", 64: "similing-eyes-with-hand-over-mouth", 65: "sleep",
        66: "sleepy", 67: "slightly-frowning", 68: "slightly-happy", 69: "smile-with-big-eyes", 70: "smile",
        71: "smirk", 72: "sneeze", 73: "squinting-tongue", 74: "star-struck", 75: "stick-out-tounge",
        76: "surprised", 77: "sweat", 78: "thermometer-face", 79: "thinking-face", 80: "tired",
        81: "triumph", 82: "unamused", 83: "upside-down-face", 84: "vomit", 85: "warm-smile",
        86: "weary", 87: "wink", 88: "winky-tongue", 89: "woozy", 90: "worried",
        91: "x-eyes", 92: "yawn", 93: "yum", 94: "zany-face", 95: "zipper-face"
    ]
    
    // Map predicted_emoji_id to actual emoji
    static func emojiForID(_ id: Int?) -> String {
        guard let id = id else { return "😊" }
        return EMOJI_MAP[id] ?? "😊"
    }
    
    // Map predicted_emoji_id to emoji name
    static func emojiNameForID(_ id: Int?) -> String {
        guard let id = id else { return "neutral-face" }
        return EMOJI_NAME_MAP[id] ?? "neutral-face"
    }
    
    // Map emoji name to ID
    static func emojiIDForName(_ name: String) -> Int {
        // Find the ID for the given emoji name
        for (id, emojiName) in EMOJI_NAME_MAP {
            if emojiName == name {
                return id
            }
        }
        // Default to neutral-face (ID 46)
        return 46
    }
    
    // Extract emotion text from user_emotion_profile
    static func extractEmotionText(from profile: String?) -> String {
        guard let profile = profile else { return "Neutral" }
        
        let lowercased = profile.lowercased()
        
        if lowercased.contains("joy") || lowercased.contains("happy") || lowercased.contains("joyful") {
            return "Joyful"
        } else if lowercased.contains("excited") || lowercased.contains("energetic") {
            return "Excited"
        } else if lowercased.contains("calm") || lowercased.contains("peaceful") || lowercased.contains("relaxed") {
            return "Calm"
        } else if lowercased.contains("focused") || lowercased.contains("engaged") {
            return "Focused"
        } else if lowercased.contains("stressed") || lowercased.contains("anxious") {
            return "Stressed"
        } else if lowercased.contains("sad") || lowercased.contains("down") {
            return "Sad"
        } else if lowercased.contains("confident") || lowercased.contains("determined") {
            return "Confident"
        } else if lowercased.contains("tired") || lowercased.contains("exhausted") {
            return "Tired"
        } else if lowercased.contains("neutral") {
            return "Neutral"
        } else {
            return "Neutral"
        }
    }
    
    // Generate comprehensive contact profile based on API data
    static func generateContactProfile(from contact: Contact, apiData: ContactProfile.ContactEmotionDetail?) -> String {
        guard let apiData = apiData else {
            return generateFallbackProfile(for: contact)
        }
        
        let emoji = emojiForID(apiData.predictedEmojiId)
        let emojiName = emojiNameForID(apiData.predictedEmojiId)
        let emotionText = extractEmotionText(from: apiData.userEmotionProfile)
        
        let profile = """
        **Contact Emotion Profile for \(contact.name)**
        
        **Current Emotional State:** \(emoji) \(emotionText) (\(emojiName))
        **Phone:** \(contact.phoneNumber)
        **Location:** \(contact.location)
        
        **Behavioral Analysis:**
        \(apiData.behaviorFactors?.isEmpty == false ? apiData.behaviorFactors! : "Behavioral analysis data is being processed...")
        
        **Health & Wellness Factors:**
        \(apiData.healthFactors?.isEmpty == false ? apiData.healthFactors! : "Health analysis data is being processed...")
        
        **Emotion Profile Summary:**
        \(apiData.userEmotionProfile?.isEmpty == false ? apiData.userEmotionProfile! : "Detailed emotion profile is being generated...")
        
        **Analysis Metadata:**
        • Predicted Emoji ID: \(apiData.predictedEmojiId ?? 0)
        • Emotion Classification: \(emotionText)
        • Profile Last Updated: \(Date().formatted(date: .abbreviated, time: .shortened))
        
        *This analysis is generated using advanced sentiment analysis algorithms and should be used as a guide for understanding emotional patterns.*
        """
        
        return profile
    }
    
    private static func generateFallbackProfile(for contact: Contact) -> String {
        return """
        **Contact Profile for \(contact.name)**
        
        **Current Emotional State:** \(contact.mood) \(contact.moodText)
        **Phone:** \(contact.phoneNumber)
        **Location:** \(contact.location)
        
        **Status:** Awaiting sentiment analysis data...
        
        This contact's detailed emotional profile will be available once the sentiment analysis is complete. Please check back in a few moments.
        """
    }
    
    // MARK: - Phone Number Formatting
    static func cleanPhoneNumber(_ phoneNumber: String) -> String {
        // Remove all non-numeric characters
        let cleaned = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return cleaned
    }
}

// MARK: - City Models
struct FavoriteCity {
    let name: String
    let mood: String
}

// MARK: - Timeline Models
struct MoodTimelineItem {
    let time: String
    let mood: String
    let description: String
}

struct MoodForecastItem {
    let period: String
    let mood: String
    let description: String
}

struct EmotionalTimelineItem {
    let time: String
    let mood: String
    let description: String
    let isCurrentTime: Bool
}

// MARK: - Journal Models
struct JournalEntry: Identifiable {
    let id = UUID()
    let time: String
    let activity: String
    let emotion: String
    let meetingName: String?
    
    var displayText: String {
        if let meeting = meetingName {
            return "\(activity): \(meeting)"
        } else {
            return activity
        }
    }
}

// MARK: - Behavior Models
struct BehaviorPattern {
    let icon: String
    let title: String
    let frequency: String
    let description: String
    let tags: [String]
}

struct MoodChange {
    let id = UUID()
    let fromMood: String
    let toMood: String
    let timeAgo: String
    let reason: String?
}

struct SecondaryEmotion {
    let emotion: String
    let emoji: String
    let percentage: Int
}

// MARK: - Map Models
struct MoodLocation: Identifiable, Hashable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let mood: String
    let moodText: String
    var isCurrentUser: Bool = false
    var isAppUser: Bool = false
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MoodLocation, rhs: MoodLocation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Reply Context Model
struct ReplyContext {
    let type: ReplyType
    let content: String
    let emoji: String?
    
    enum ReplyType {
        case emotion
        case timeline
        case analysis
    }
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let replyContext: String?
    let timestamp: Date
}

// MARK: - Pinned Contacts Manager
class PinnedContactsManager: ObservableObject {
    @Published var pinnedContacts: [Contact] = [] {
        didSet {
            saveContactsSync()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let pinnedContactsKey = "PinnedContactsKey"
    private var saveTask: Task<Void, Never>?
    
    init() {
        loadContacts()
        print("PinnedContactsManager initialized with \(pinnedContacts.count) saved contacts")
        
        // Listen for user authentication to trigger sync
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserAuthentication),
            name: NSNotification.Name("UserAuthenticated"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleUserAuthentication(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let username = userInfo["username"] as? String,
              !username.isEmpty else { return }
        
        print("📱 User authenticated, triggering following list sync...")
        FollowingSyncManager.shared.syncFollowingList(
            username: username,
            pinnedContactsManager: self
        )
    }
    
    func pinContact(_ contact: Contact) {
        print("ATTEMPTING to pin contact: \(contact.name)")
        print("Current pinned count: \(pinnedContacts.count)")
        print("Already pinned? \(pinnedContacts.contains(where: { $0.id == contact.id }))")
        
        if !pinnedContacts.contains(where: { $0.id == contact.id }) && pinnedContacts.count < 12 {
            pinnedContacts.append(contact)
            print("SUCCESSFULLY pinned contact: \(contact.name) (Total: \(pinnedContacts.count))")
            
            // FORCE immediate save verification
            saveContactsSync()
            
            // Verify save worked
            if let data = userDefaults.data(forKey: pinnedContactsKey),
               let loaded = try? JSONDecoder().decode([Contact].self, from: data) {
                print("VERIFIED: \(loaded.count) contacts saved to disk")
            } else {
                print("FAILED to verify save")
            }
        } else {
            print("Cannot pin contact: \(contact.name) - already pinned or limit reached")
        }
    }
    
    func unpinContact(_ contact: Contact) {
        let initialCount = pinnedContacts.count
        pinnedContacts.removeAll { $0.id == contact.id }
        if pinnedContacts.count < initialCount {
            print("Unpinned contact: \(contact.name) (Total: \(pinnedContacts.count))")
        }
    }
    
    func unpinContact(by name: String) {
        let initialCount = pinnedContacts.count
        pinnedContacts.removeAll { $0.name == name }
        if pinnedContacts.count < initialCount {
            print("Unpinned contact by name: \(name) (Total: \(pinnedContacts.count))")
        }
    }
    
    func unpinContactByPhone(_ phoneNumber: String) {
        let initialCount = pinnedContacts.count
        pinnedContacts.removeAll { $0.phoneNumber == phoneNumber }
        if pinnedContacts.count < initialCount {
            print("Unpinned contact by phone: \(phoneNumber) (Total: \(pinnedContacts.count))")
        }
    }
    
    func isPinned(_ contact: Contact) -> Bool {
        pinnedContacts.contains { $0.id == contact.id }
    }
    
    func clearAllContacts() {
        pinnedContacts.removeAll()
        userDefaults.removeObject(forKey: pinnedContactsKey)
        userDefaults.synchronize()
        print("Cleared all pinned contacts")
    }
    

    
    // MARK: - FIXED Instant Persistence
    private func saveContactsSync() {
        print("💾 ATTEMPTING to save \(pinnedContacts.count) contacts...")
        
        let encoder = JSONEncoder()
        
        do {
            let encoded = try encoder.encode(pinnedContacts)
            userDefaults.set(encoded, forKey: pinnedContactsKey)
            userDefaults.synchronize() // FORCE IMMEDIATE SAVE
            print("SUCCESSFULLY saved \(pinnedContacts.count) contacts to UserDefaults")
            
            // Double-check the save worked
            if let retrievedData = userDefaults.data(forKey: pinnedContactsKey) {
                print("VERIFIED: Data exists in UserDefaults (\(retrievedData.count) bytes)")
                
                if let decodedContacts = try? JSONDecoder().decode([Contact].self, from: retrievedData) {
                    print("VERIFIED: Can decode \(decodedContacts.count) contacts from saved data")
                    for contact in decodedContacts {
                        print("   - \(contact.name)")
                    }
                } else {
                    print("ERROR: Cannot decode saved data")
                }
            } else {
                print("ERROR: No data found in UserDefaults after save")
            }
        } catch {
            print("ENCODING FAILED: \(error)")
        }
    }
    
    @MainActor
    private func saveContactsInstantly() async {
        // Cancel any pending save task to avoid redundant writes
        saveTask?.cancel()
        
        saveTask = Task {
            let encoder = JSONEncoder()
            
            if let encoded = try? encoder.encode(pinnedContacts) {
                userDefaults.set(encoded, forKey: pinnedContactsKey)
                print("Instantly saved \(pinnedContacts.count) contacts")
            } else {
                print("Failed to encode contacts")
            }
        }
        
        await saveTask?.value
    }
    
    // Legacy method for compatibility
    private func saveContacts() {
        saveContactsSync()
    }
    
    private func loadContacts() {
        print("ATTEMPTING to load contacts from UserDefaults...")
        
        guard let data = userDefaults.data(forKey: pinnedContactsKey) else { 
            print("No saved contacts found - starting fresh")
            return 
        }
        
        print("Found \(data.count) bytes of contact data")
        
        // Instant decoding with optimized decoder
        let decoder = JSONDecoder()
        
        do {
            let decoded = try decoder.decode([Contact].self, from: data)
            pinnedContacts = decoded
            print("SUCCESSFULLY loaded \(decoded.count) contacts:")
            for contact in decoded {
                print("   - \(contact.name) (\(contact.phoneNumber))")
            }
            return
        } catch {
            print("Migration needed: \(error.localizedDescription)")
            handleLegacyMigration(data: data, decoder: decoder)
        }
    }
    
    private func handleLegacyMigration(data: Data, decoder: JSONDecoder) {
        struct OldContact: Codable {
            let name: String
            let location: String
            var mood: String
            var moodText: String
        }
        
        do {
            let oldContacts = try decoder.decode([OldContact].self, from: data)
            pinnedContacts = oldContacts.map { oldContact in
                Contact(
                    name: oldContact.name,
                    location: oldContact.location,
                    mood: oldContact.mood,
                    moodText: oldContact.moodText,
                    phoneNumber: ""
                )
            }
            saveContactsSync() // FIXED - use sync save
            print("Instantly migrated \(oldContacts.count) contacts")
        } catch {
            print("Contact data corrupted, cleared: \(error.localizedDescription)")
            userDefaults.removeObject(forKey: pinnedContactsKey)
        }
    }
} 

// MARK: - Emotional Timeline Response Models
struct EmotionalTimelineResponse: Codable {
    let username: String
    let predictions: [String: EmotionalTimelineEntry]
    
    private enum CodingKeys: String, CodingKey {
        case username, predictions
    }
}

struct EmotionalTimelineEntry: Codable {
    let emoji_id: Int
    let mental_pulse: String?
    let ai_scoop: String
    let social_vibe: String
    let zinger_caption: String
    
    private enum CodingKeys: String, CodingKey {
        case emoji_id, mental_pulse, ai_scoop, social_vibe, zinger_caption
    }
}

// MARK: - Prediction Response Models
struct PredictionResponse: Codable {
    let username: String
    let predictions: [String: PredictionEntry]
    
    private enum CodingKeys: String, CodingKey {
        case username, predictions
    }
}

struct PredictionEntry: Codable {
    let emoji_id: Int
    let mental_pulse: String?
    let ai_scoop: String
    let social_vibe: String
    let zinger_caption: String
    
    private enum CodingKeys: String, CodingKey {
        case emoji_id, mental_pulse, ai_scoop, social_vibe, zinger_caption
    }
} 