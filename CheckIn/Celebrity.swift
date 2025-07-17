//
//  Celebrity.swift
//  moodgpt
//
//  Created by Test on 6/10/25.
//

import Foundation
import Combine
import SwiftUI

// MARK: - API Response Models
struct CelebrityAPIResponse: Codable {
    let createdAt: String
    let hype: Int
    let id: Int
    let image: String?
    let username: String
    let emotionString: String
    
    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case hype, id, image, username
        case emotionString = "emotion"
    }
    
    // Computed property to decode the emotion JSON string
    var emotion: CelebrityEmotionData? {
        guard let data = emotionString.data(using: .utf8) else {
            print("Failed to convert emotion string to data for \(username)")
            return nil
        }
        
        do {
            let emotionData = try JSONDecoder().decode(CelebrityEmotionData.self, from: data)
            return emotionData
        } catch {
            print("Failed to decode emotion data for \(username): \(error)")
            return nil
        }
    }
}

struct CelebrityEmotionData: Codable {
    let points: [String]?
    let context: String?
    let emotion: Int
    let references: [String]
}

// MARK: - Emoji Mapping
fileprivate let emojiMap: [Int: String] = [
    1:  "angry",
    2:  "anguished",
    3:  "anxios-with-sweat",
    4:  "astonished",
    5:  "bandage-face",
    6:  "big-frown",
    7:  "blush",
    8:  "cold-face",
    9:  "concerned",
    10: "cry",
    11: "cursing",
    12: "Diagonal-mouth",
    13: "distraught",
    14: "dizzy-face",
    15: "drool",
    16: "exhale",
    17: "expressionless",
    18: "flushed",
    19: "frown",
    20: "gasp",
    21: "grimacing",
    22: "grin-sweat",
    23: "grin",
    24: "grinning",
    25: "hand-over-mouth",
    26: "happy-cry",
    27: "head-nod",
    28: "head-shake",
    29: "heart-eyes",
    30: "heart-face",
    31: "holding-back-tears",
    32: "hot-face",
    33: "hug-face",
    34: "joy",
    35: "kissing-closed-eyes",
    36: "kissing-heart",
    37: "kissing-smile",
    38: "kissing",
    39: "laughing",
    40: "loudly-crying",
    41: "melting",
    42: "mind-blown",
    43: "monocle",
    44: "mouth-none",
    45: "mouth-open",
    46: "neutral-face",
    47: "partying-face",
    48: "peeking",
    49: "pensive",
    50: "pleading",
    51: "rage",
    52: "raised-eyebrow",
    53: "relieved",
    54: "rofl",
    55: "rolling-eyes",
    56: "sad",
    57: "scared",
    58: "screaming",
    59: "scrunched-eyes",
    60: "scrunched-mouth",
    61: "shaking-face",
    62: "shushing-face",
    63: "sick",
    64: "similing-eyes-with-hand-over-mouth",
    65: "sleep",
    66: "sleepy",
    67: "slightly-frowning",
    68: "slightly-happy",
    69: "smile-with-big-eyes",
    70: "smile",
    71: "smirk",
    72: "sneeze",
    73: "squinting-tongue",
    74: "star-struck",
    75: "stick-out-tounge",
    76: "surprised",
    77: "sweat",
    78: "thermometer-face",
    79: "thinking-face",
    80: "tired",
    81: "triumph",
    82: "unamused",
    83: "upside-down-face",
    84: "vomit",
    85: "warm-smile",
    86: "weary",
    87: "wink",
    88: "winky-tongue",
    89: "woozy",
    90: "worried",
    91: "x-eyes",
    92: "yawn",
    93: "yum",
    94: "zany-face",
    95: "zipper-face"
]

// MARK: - Celebrity Model
struct Celebrity: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let profession: String
    let emoji: String
    let moodText: String
    let category: CelebrityCategory
    let lastUpdate: String
    let age: Int
    let bio: String
    let instagramHandle: String?
    let twitterHandle: String?
    let facebookHandle: String?
    
    // API-specific fields
    let apiId: Int?
    let hype: Int?
    let imageUrl: String?
    let emotionPoints: [String]
    let emotionReferences: [String]
    let rawEmotionId: Int?
    
    // Legacy emotional analysis fields (for backward compatibility)
    var healthFactors: String
    var behaviorFactors: String
    var emotionalProfile: String
    var moodTimeline: [MoodTimelinePoint]
    var context: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, profession, emoji, moodText, category, lastUpdate, age, bio
        case instagramHandle, twitterHandle, facebookHandle
        case apiId, hype, imageUrl, emotionPoints, emotionReferences, rawEmotionId
        case healthFactors, behaviorFactors, emotionalProfile, moodTimeline
    }
    
    // Initializer for API data
    init(from apiResponse: CelebrityAPIResponse) {
        self.id = UUID()
        self.name = Self.formatUsername(apiResponse.username)
        self.profession = Self.getProfessionForUsername(apiResponse.username)
        self.emoji = Self.getEmojiFromId(apiResponse.emotion?.emotion ?? 46)
        self.moodText = Self.getEmotionName(apiResponse.emotion?.emotion ?? 46)
        self.category = Self.getCategoryForUsername(apiResponse.username)
        self.lastUpdate = Self.formatDate(apiResponse.createdAt)
        self.age = 30 // Default age
        self.bio = Self.getBioForUsername(apiResponse.username)
        self.instagramHandle = apiResponse.username
        self.twitterHandle = apiResponse.username
        self.facebookHandle = nil
        
        // API-specific data
        self.apiId = apiResponse.id
        self.hype = apiResponse.hype
        self.imageUrl = apiResponse.image
        self.emotionPoints = apiResponse.emotion?.points ?? []
        self.emotionReferences = apiResponse.emotion?.references ?? []
        self.rawEmotionId = apiResponse.emotion?.emotion
        // Debug logging
        print("🌟 Celebrity: \(self.name)")
        print("🌟 Emotion Points Count: \(self.emotionPoints.count)")
        for (index, point) in self.emotionPoints.enumerated() {
            print("🌟 Point \(index + 1): \(point)")
        }
        self.context = apiResponse.emotion?.context ?? ""
        // Generate legacy fields
        self.healthFactors = "Real-time health monitoring through social media activity and public appearances."
        self.behaviorFactors = apiResponse.emotion?.points?.joined(separator: " ") ?? ""
        self.emotionalProfile = "Current emotional state based on recent social media analysis and public interactions."
        self.moodTimeline = Self.generateDefaultTimeline()
    }
    
    // Custom Codable implementation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.profession = try container.decode(String.self, forKey: .profession)
        self.emoji = try container.decode(String.self, forKey: .emoji)
        self.moodText = try container.decode(String.self, forKey: .moodText)
        self.category = try container.decode(CelebrityCategory.self, forKey: .category)
        self.lastUpdate = try container.decode(String.self, forKey: .lastUpdate)
        self.age = try container.decode(Int.self, forKey: .age)
        self.bio = try container.decode(String.self, forKey: .bio)
        self.instagramHandle = try container.decodeIfPresent(String.self, forKey: .instagramHandle)
        self.twitterHandle = try container.decodeIfPresent(String.self, forKey: .twitterHandle)
        self.facebookHandle = try container.decodeIfPresent(String.self, forKey: .facebookHandle)
        
        self.apiId = try container.decodeIfPresent(Int.self, forKey: .apiId)
        self.hype = try container.decodeIfPresent(Int.self, forKey: .hype)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.emotionPoints = try container.decodeIfPresent([String].self, forKey: .emotionPoints) ?? []
        self.emotionReferences = try container.decodeIfPresent([String].self, forKey: .emotionReferences) ?? []
        self.rawEmotionId = try container.decodeIfPresent(Int.self, forKey: .rawEmotionId)
        
        self.healthFactors = try container.decodeIfPresent(String.self, forKey: .healthFactors) ?? ""
        self.behaviorFactors = try container.decodeIfPresent(String.self, forKey: .behaviorFactors) ?? ""
        self.emotionalProfile = try container.decodeIfPresent(String.self, forKey: .emotionalProfile) ?? ""
        self.moodTimeline = try container.decodeIfPresent([MoodTimelinePoint].self, forKey: .moodTimeline) ?? []
    }
    
    // Legacy initializer (for backward compatibility)
    init(name: String, 
         profession: String, 
         emoji: String, 
         moodText: String, 
         category: CelebrityCategory, 
         age: Int = 25, 
         bio: String = "", 
         instagramHandle: String? = nil, 
         twitterHandle: String? = nil, 
         facebookHandle: String? = nil,
         healthFactors: String? = nil,
         behaviorFactors: String? = nil,
         emotionalProfile: String? = nil,
         moodTimeline: [MoodTimelinePoint]? = nil) {
        
        self.id = UUID()
        self.name = name
        self.profession = profession
        self.emoji = emoji
        self.moodText = moodText
        self.category = category
        self.lastUpdate = "2 hours ago"
        self.age = age
        self.bio = bio
        self.instagramHandle = instagramHandle
        self.twitterHandle = twitterHandle
        self.facebookHandle = facebookHandle
        
        // API fields as nil for legacy data
        self.apiId = nil
        self.hype = nil
        self.imageUrl = nil
        self.emotionPoints = []
        self.emotionReferences = []
        self.rawEmotionId = nil
        
        // Set default emotional analysis if not provided
        self.healthFactors = healthFactors ?? "Celebrity maintains a public lifestyle with varying health impacts, managing performance demands while balancing personal wellness."
        self.behaviorFactors = behaviorFactors ?? "Digital presence reflects professional image while managing public expectations and personal boundaries."
        self.emotionalProfile = emotionalProfile ?? "Balances public emotional expression with professional image, showing controlled vulnerability when appropriate."
        
        // Generate default timeline if not provided
        self.moodTimeline = moodTimeline ?? Self.generateDefaultTimeline()
    }
    
    // MARK: - Helper Methods
    
    static func getEmojiFromId(_ emotionId: Int) -> String {
        let emotionName = emojiMap[emotionId] ?? "neutral-face"
        return ContactProfileHelpers.emojiForID(Self.getEmojiIdForName(emotionName))
    }
    
    static func getEmojiIdForName(_ emotionName: String) -> Int {
        // Map emotion names to emoji IDs from the existing ContactProfileHelpers system
        switch emotionName {
        case "angry": return 1
        case "anguished": return 2
        case "anxios-with-sweat": return 3
        case "astonished": return 4
        case "bandage-face": return 5
        case "big-frown": return 6
        case "blush": return 7
        case "cold-face": return 8
        case "concerned": return 9
        case "cry": return 10
        case "cursing": return 11
        case "diagonal-mouth": return 12
        case "distraught": return 13
        case "dizzy-face": return 14
        case "drool": return 15
        case "exhale": return 16
        case "expressionless": return 17
        case "flushed": return 18
        case "frown": return 19
        case "gasp": return 20
        case "grimacing": return 21
        case "grin-sweat": return 22
        case "grin": return 23
        case "grinning": return 24
        case "hand-over-mouth": return 25
        case "happy-cry": return 26
        case "head-nod": return 27
        case "head-shake": return 28
        case "heart-eyes": return 29
        case "heart-face": return 30
        case "holding-back-tears": return 31
        case "hot-face": return 32
        case "hug-face": return 33
        case "joy": return 34
        case "kissing-closed-eyes": return 35
        case "kissing-heart": return 36
        case "kissing-smile": return 37
        case "kissing": return 38
        case "laughing": return 39
        case "loudly-crying": return 40
        case "melting": return 41
        case "mind-blown": return 42
        case "monocle": return 43
        case "mouth-none": return 44
        case "mouth-open": return 45
        case "neutral-face": return 46
        case "partying-face": return 47
        case "peeking": return 48
        case "pensive": return 49
        case "pleading": return 50
        case "rage": return 51
        case "raised-eyebrow": return 52
        case "relieved": return 53
        case "rofl": return 54
        case "rolling-eyes": return 55
        case "sad": return 56
        case "scared": return 57
        case "screaming": return 58
        case "scrunched-eyes": return 59
        case "scrunched-mouth": return 60
        case "shaking-face": return 61
        case "shushing-face": return 62
        case "sick": return 63
        case "similing-eyes-with-hand-over-mouth": return 64
        case "sleep": return 65
        case "sleepy": return 66
        case "slightly-frowning": return 67
        case "slightly-happy": return 68
        case "smile-with-big-eyes": return 69
        case "smile": return 70
        case "smirk": return 71
        case "sneeze": return 72
        case "squinting-tongue": return 73
        case "star-struck": return 74
        case "stick-out-tounge": return 75
        case "surprised": return 76
        case "sweat": return 77
        case "thermometer-face": return 78
        case "thinking-face": return 79
        case "tired": return 80
        case "triumph": return 81
        case "unamused": return 82
        case "upside-down-face": return 83
        case "vomit": return 84
        case "warm-smile": return 85
        case "weary": return 86
        case "wink": return 87
        case "winky-tongue": return 88
        case "woozy": return 89
        case "worried": return 90
        case "x-eyes": return 91
        case "yawn": return 92
        case "yum": return 93
        case "zany-face": return 94
        case "zipper-face": return 95
        default: return 46 // neutral-face
        }
    }
    
    static func getEmotionName(_ emotionId: Int) -> String {
        let emotionName = emojiMap[emotionId] ?? "neutral-face"
        return formatEmotionNameForDisplay(emotionName)
    }
    
    static func formatEmotionNameForDisplay(_ emotionName: String) -> String {
        switch emotionName {
        case "angry": return "Angry"
        case "anguished": return "Anguished"
        case "anxios-with-sweat": return "Anxious"
        case "astonished": return "Astonished"
        case "bandage-face": return "Hurt"
        case "big-frown": return "Very Sad"
        case "blush": return "Blushing"
        case "cold-face": return "Cold"
        case "concerned": return "Concerned"
        case "cry": return "Crying"
        case "cursing": return "Frustrated"
        case "Diagonal-mouth": return "Uncertain"
        case "distraught": return "Distraught"
        case "dizzy-face": return "Dizzy"
        case "drool": return "Drooling"
        case "exhale": return "Relieved"
        case "expressionless": return "Neutral"
        case "flushed": return "Embarrassed"
        case "frown": return "Sad"
        case "gasp": return "Surprised"
        case "grimacing": return "Awkward"
        case "grin-sweat": return "Nervous"
        case "grin": return "Grinning"
        case "grinning": return "Very Happy"
        case "hand-over-mouth": return "Shocked"
        case "happy-cry": return "Overjoyed"
        case "head-nod": return "Agreeing"
        case "head-shake": return "Disagreeing"
        case "heart-eyes": return "In Love"
        case "heart-face": return "Loving"
        case "holding-back-tears": return "Emotional"
        case "hot-face": return "Hot"
        case "hug-face": return "Affectionate"
        case "joy": return "Joyful"
        case "kissing-closed-eyes": return "Kiss"
        case "kissing-heart": return "Blowing Kiss"
        case "kissing-smile": return "Happy Kiss"
        case "kissing": return "Kissing"
        case "laughing": return "Laughing"
        case "loudly-crying": return "Sobbing"
        case "melting": return "Melting"
        case "mind-blown": return "Mind Blown"
        case "monocle": return "Curious"
        case "mouth-none": return "Speechless"
        case "mouth-open": return "Amazed"
        case "neutral-face": return "Neutral"
        case "partying-face": return "Partying"
        case "peeking": return "Peeking"
        case "pensive": return "Thoughtful"
        case "pleading": return "Pleading"
        case "rage": return "Furious"
        case "raised-eyebrow": return "Skeptical"
        case "relieved": return "Relieved"
        case "rofl": return "Rolling on Floor"
        case "rolling-eyes": return "Rolling Eyes"
        case "sad": return "Sad"
        case "scared": return "Scared"
        case "screaming": return "Screaming"
        case "scrunched-eyes": return "Squinting"
        case "scrunched-mouth": return "Disgusted"
        case "shaking-face": return "Shaking"
        case "shushing-face": return "Shushing"
        case "sick": return "Sick"
        case "similing-eyes-with-hand-over-mouth": return "Giggling"
        case "sleep": return "Sleeping"
        case "sleepy": return "Sleepy"
        case "slightly-frowning": return "Slightly Sad"
        case "slightly-happy": return "Content"
        case "smile-with-big-eyes": return "Beaming"
        case "smile": return "Smiling"
        case "smirk": return "Smirking"
        case "sneeze": return "Sneezing"
        case "squinting-tongue": return "Winking Tongue"
        case "star-struck": return "Starstruck"
        case "stick-out-tounge": return "Playful"
        case "surprised": return "Surprised"
        case "sweat": return "Sweating"
        case "thermometer-face": return "Feverish"
        case "thinking-face": return "Thinking"
        case "tired": return "Tired"
        case "triumph": return "Triumphant"
        case "unamused": return "Unamused"
        case "upside-down-face": return "Silly"
        case "vomit": return "Nauseous"
        case "warm-smile": return "Warm"
        case "weary": return "Weary"
        case "wink": return "Winking"
        case "winky-tongue": return "Cheeky"
        case "woozy": return "Woozy"
        case "worried": return "Worried"
        case "x-eyes": return "Knocked Out"
        case "yawn": return "Yawning"
        case "yum": return "Delicious"
        case "zany-face": return "Zany"
        case "zipper-face": return "Silent"
        default: return "Neutral"
        }
    }
    
    static func formatUsername(_ username: String) -> String {
        return username
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
    
    static func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        
        if let date = formatter.date(from: dateString) {
            let now = Date()
            let timeDifference = now.timeIntervalSince(date)
            
            if timeDifference < 3600 { // Less than 1 hour
                let minutes = Int(timeDifference / 60)
                return "\(minutes) minutes ago"
            } else if timeDifference < 86400 { // Less than 1 day
                let hours = Int(timeDifference / 3600)
                return "\(hours) hours ago"
            } else {
                let days = Int(timeDifference / 86400)
                return "\(days) days ago"
            }
        }
        
        return "Recently"
    }
    
    static func getProfessionForUsername(_ username: String) -> String {
        // Map usernames to professions based on known celebrities
        switch username.lowercased() {
        case "amy_schumer": return "Comedian & Actress"
        case "barack_obama": return "Former President"
        case "jennifer_lawrence": return "Actress"
        case "taylor_swift": return "Musician"
        case "ariana_grande": return "Singer"
        case "drake": return "Rapper"
        case "billie_eilish": return "Singer"
        case "dwayne_johnson": return "Actor"
        case "ryan_reynolds": return "Actor"
        case "kylie_jenner": return "Entrepreneur"
        case "kim_kardashian": return "Media Personality"
        case "cristiano_ronaldo": return "Footballer"
        case "lionel_messi": return "Footballer"
        case "lebron_james": return "Basketball Player"
        case "elon_musk": return "Entrepreneur"
        default: return "Celebrity"
        }
    }
    
    static func getCategoryForUsername(_ username: String) -> CelebrityCategory {
        switch username.lowercased() {
        case "amy_schumer": return .comedy
        case "barack_obama": return .politics
        case "jennifer_lawrence": return .acting
        case "taylor_swift", "ariana_grande", "drake", "billie_eilish": return .music
        case "dwayne_johnson", "ryan_reynolds": return .acting
        case "kylie_jenner", "kim_kardashian": return .social
        case "cristiano_ronaldo", "lionel_messi", "lebron_james": return .sports
        case "elon_musk": return .business
        default: return .social
        }
    }
    
    static func getBioForUsername(_ username: String) -> String {
        switch username.lowercased() {
        case "amy_schumer": return "Stand-up comedian, actress, and writer known for her bold humor and advocacy."
        case "barack_obama": return "44th President of the United States, author, and global leader."
        case "jennifer_lawrence": return "Academy Award-winning actress known for her versatile roles and down-to-earth personality."
        case "taylor_swift": return "Multi-Grammy winning singer-songwriter and global music icon."
        case "ariana_grande": return "Pop superstar and actress with a powerful vocal range."
        case "drake": return "Canadian rapper, singer, and entrepreneur."
        case "billie_eilish": return "Multi-Grammy winning artist known for her unique sound and style."
        default: return "Celebrity and public figure."
        }
    }
    
    static func generateDefaultTimeline() -> [MoodTimelinePoint] {
        let times = ["6AM", "9AM", "12PM", "3PM", "6PM", "9PM"]
        let moods = [
            ("😴", "Sleepy"),
            ("😊", "Happy"),
            ("🤔", "Focused"),
            ("😌", "Calm"),
            ("😄", "Energetic"),
            ("😊", "Content")
        ]
        
        return zip(times, moods).map { time, mood in
            MoodTimelinePoint(time: time, emoji: mood.0, mood: mood.1)
        }
    }
}

// MARK: - Celebrity Categories
enum CelebrityCategory: String, CaseIterable, Codable {
    case music = "Music"
    case sports = "Sports" 
    case acting = "Acting"
    case social = "Social Media"
    case business = "Business"
    case comedy = "Comedy"
    case politics = "Politics"
}

// MARK: - Mood Timeline Point
struct MoodTimelinePoint: Codable, Hashable {
    let time: String
    let emoji: String
    let mood: String
}

// MARK: - Celebrity API Service
class CelebrityAPIService {
    static let shared = CelebrityAPIService()
    private let session = URLSession.shared
    
    private init() {}
    
    func fetchCelebrities() async throws -> [Celebrity] {
        guard let url = URL(string: "https://user-login-register-d6yw.onrender.com/user_emotions/celebs") else {
            throw URLError(.badURL)
        }
        
        print("🌟 Fetching celebrity data from API...")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let apiResponses = try JSONDecoder().decode([CelebrityAPIResponse].self, from: data)
        let celebrities = apiResponses.map { Celebrity(from: $0) }
        
        print("🌟 Successfully fetched \(celebrities.count) celebrities from API")
        return celebrities
    }
}

// MARK: - Celebrity Data Manager
@MainActor
class CelebrityDataManager: ObservableObject {
    @Published var celebrities: [Celebrity] = []
    @Published var isLoading = false
    @Published var hasError = false
    
    static let shared = CelebrityDataManager()
    private let cacheManager = CacheManager.shared
    
    private init() {
        // Load cached data immediately on init
        loadCachedCelebrities()
        // Then fetch fresh data in background
        Task {
            await loadCelebrities()
        }
    }
    
    /// Load cached celebrities immediately
    private func loadCachedCelebrities() {
        if let cachedCelebrities = cacheManager.getCachedCelebrityList() {
            self.celebrities = cachedCelebrities
            print("🌟 Loaded \(cachedCelebrities.count) cached celebrities")
        }
    }
    
    func loadCelebrities() async {
        // Don't show loading if we already have cached data
        if celebrities.isEmpty {
            isLoading = true
        }
        hasError = false
        
        do {
            let fetchedCelebrities = try await CelebrityAPIService.shared.fetchCelebrities()
            celebrities = fetchedCelebrities
            hasError = false
            
            // Cache the fetched celebrities - this automatically replaces old cache
            cacheManager.cacheCelebrityList(fetchedCelebrities)
            print("🌟 Cached \(fetchedCelebrities.count) celebrities")
        } catch {
            print("❌ Error loading celebrities: \(error)")
            hasError = true
            // Keep cached data if API fails - don't clear it
        }
        
        isLoading = false
    }
}

// MARK: - Celebrity Manager (UI Layer)
@MainActor
class CelebrityManager: ObservableObject {
    @Published var allCelebrities: [Celebrity] = []
    @Published var searchText = ""
    @Published var selectedCategory: CelebrityCategory? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // Pagination
    @Published var currentPage = 0
    let itemsPerPage = 20
    
    private let dataManager = CelebrityDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to data manager updates
        dataManager.$celebrities
            .receive(on: DispatchQueue.main)
            .assign(to: &$allCelebrities)
        
        dataManager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        dataManager.$hasError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasError in
                self?.errorMessage = hasError ? "Failed to load celebrity data" : nil
            }
            .store(in: &cancellables)
    }
    
    var filteredCelebrities: [Celebrity] {
        var filtered = allCelebrities
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { celebrity in
                celebrity.name.localizedCaseInsensitiveContains(searchText) ||
                celebrity.profession.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        return filtered
    }
    
    var paginatedCelebrities: [Celebrity] {
        let startIndex = currentPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, filteredCelebrities.count)
        
        guard startIndex < filteredCelebrities.count else { return [] }
        return Array(filteredCelebrities[startIndex..<endIndex])
    }
    
    var hasMorePages: Bool {
        return (currentPage + 1) * itemsPerPage < filteredCelebrities.count
    }
    
    // Get suggested celebrities for the horizontal bar (top trending ones)
    var suggestedCelebrities: [Celebrity] {
        // Return top 8 celebrities with highest hype score
        return allCelebrities
            .sorted { ($0.hype ?? 0) > ($1.hype ?? 0) }
            .prefix(8)
            .map { $0 }
    }
    
    func loadNextPage() {
        if hasMorePages {
            currentPage += 1
        }
    }
    
    func resetPagination() {
        currentPage = 0
    }
    
    func refreshData() {
        Task {
            await dataManager.loadCelebrities()
        }
    }
} 
