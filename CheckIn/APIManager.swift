//
//  APIManager.swift
//  moodgpt
//
//  Created by Test on 5/31/25.
//

import Foundation

// MARK: - API Models
struct UserAnalysisRequest: Codable {
    let username: String
}

struct UserAnalysisResponse: Codable {
    let emojiId: Int
    let zingerCaption: String
    let socialVibe: String
    let mentalPulse: String
    let aiScoop: String
    let crispAnalyticsPoints: [String]
    
    // Additional property for compatibility
    var overall_mood: String? {
        return socialVibe
    }
    
    enum CodingKeys: String, CodingKey {
        case emojiId = "emoji_id"
        case zingerCaption = "zinger_caption"
        case socialVibe = "social_vibe"
        case mentalPulse = "mental_pulse"
        case aiScoop = "ai_scoop"
        case crispAnalyticsPoints = "crisp_analytics_points"
    }
}

// Note: Using InsertHealthRequest instead to avoid duplication

// MARK: - Activity Tracking Models
// Note: ActivityRequest is not used directly - we use direct JSON serialization for activity tracking

// MARK: - Location Models
struct LocationRequest: Codable {
    let username: String
    let longitude: Double
    let latitude: Double
}

// MARK: - Auth Models
struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct RegisterRequest: Codable {
    let username: String
    let password: String
}

struct SocialAuthRequest: Codable {
    let username: String
}

// MARK: - Contact & Phone Management Models
struct CheckPhoneRequest: Codable {
    let username: String
}

struct CheckPhoneResponse: Codable {
    let exists: Bool
    let phno: String?
}

struct UpdatePhoneRequest: Codable {
    let username: String
    let phno: String
}

struct UpdatePhoneResponse: Codable {
    let success: Bool
    let message: String
}

struct AddContactsRequest: Codable {
    let username: String
    let contacts: [String]
}

struct AddContactsResponse: Codable {
    let message: String
}

// MARK: - Logger API Models
struct ActivityData: Codable {
    let action: String
    let time: String
}

struct LogActivityRequest: Codable {
    let email: String
    let activity: ActivityData
}

struct LogActivityResponse: Codable {
    let message: String
}

struct InsertHealthRequest: Codable {
    let username: String
    let healthData: [String: AnyCodable]
    
    enum CodingKeys: String, CodingKey {
        case username
        case healthData = "health_data"
    }
}

struct InsertHealthResponse: Codable {
    let message: String
}

struct InsertLocationRequest: Codable {
    let username: String
    let longitude: Double
    let latitude: Double
}

struct InsertLocationResponse: Codable {
    let message: String
}

// MARK: - Follower API Models
struct FollowRequest: Codable {
    let user: String
    let follower: String
}

struct FollowResponse: Codable {
    let message: String
}

struct UnfollowRequest: Codable {
    let user: String
    let follower: String
}

struct UnfollowResponse: Codable {
    let message: String
}

struct GetFollowersRequest: Codable {
    let user: String
}

struct GetFollowersResponse: Codable {
    let user: String
    let followers: [String]
}

struct GetFollowingRequest: Codable {
    let user: String
}

struct GetFollowingResponse: Codable {
    let user: String
    let following: [String]
}

struct AuthResponse: Codable {
    let success: Bool
    let message: String?
}

// MARK: - Mood API Models
struct MoodResponse: Codable {
    let mood: String
    let confidence: Double
    let timestamp: Date
    let factors: [String]
}

struct MoodUpdateRequest: Codable {
    let mood: String
    let confidence: Double
    let factors: [String]
    let timestamp: Date
}

struct MoodUpdateResponse: Codable {
    let success: Bool
    let mood: String
    let timestamp: Date
    let message: String
}

struct CityMoodResponse: Codable {
    let city: String
    let averageMood: String
    let confidence: Double
    let sampleSize: Int
    let timestamp: Date
}

struct ContactMoodResponse: Codable {
    let contactId: String
    let mood: String
    let confidence: Double
    let lastUpdate: Date
}

struct EmotionalPatternResponse: Codable {
    let patterns: [PatternData]
    let insights: [String]
    let recommendations: [String]
}

struct PatternData: Codable {
    let timeRange: String
    let dominantMood: String
    let frequency: Int
    let correlation: Double
}

struct TimeRange: Codable {
    let startDate: Date
    let endDate: Date
    let granularity: String
}

// MARK: - Spotify Models
struct SpotifyPlaylistResponse: Codable {
    let items: [SpotifyPlaylist]
}

struct SpotifyPlaylist: Codable {
    let name: String
    let id: String
    let images: [SpotifyImage]
    let description: String?
}

struct SpotifyImage: Codable {
    let url: String
}

struct SpotifyTracksResponse: Codable {
    let items: [SpotifyPlaylistItem]
}

struct SpotifyPlaylistItem: Codable {
    let track: SpotifyTrack
}

struct SpotifyTrack: Codable {
    let name: String
    let uri: String
    let artists: [SpotifyArtist]
}

struct SpotifyArtist: Codable {
    let name: String
}

struct SpotifyRecentlyPlayedResponse: Codable {
    let items: [SpotifyRecentItem]
}

// MARK: - Additional Models for Compatibility
struct ContactSentiment: Codable {
    let contactName: String
    let sentiment: String
    let confidence: Double
    let timestamp: Date
}

struct UserAnalysis: Codable {
    let username: String
    let overallMood: String
    let insights: [String]
    let recommendations: [String]
    let timestamp: Date
}

struct HealthData: Codable {
    let heartRate: Double?
    let steps: Int?
    let sleepHours: Double?
    let weight: Double?
    let bloodPressure: String?
}

struct GenericResponse: Codable {
    let success: Bool
    let message: String?
}

struct SpotifyRecentItem: Codable {
    let track: SpotifyTrack
    let playedAt: String
    
    enum CodingKeys: String, CodingKey {
        case track
        case playedAt = "played_at"
    }
}

// MARK: - Celebrity Models
struct CelebrityScoopRequest: Codable {
    let name: String
}

struct CelebrityScoopResponse: Codable {
    let name: String
    let scoop: String
    let timestamp: String
}

// Celebrity list model for the GET celebrities endpoint
// The API returns a raw array, so we'll use a custom decoder
struct CelebrityListResponse: Codable {
    let celebrities: [CelebrityData]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawArrays = try container.decode([[AnyCodable]].self)
        
        celebrities = rawArrays.compactMap { array in
            guard array.count >= 6 else { return nil }
            return CelebrityData(
                id: array[0].value as? Int ?? 0,
                name: array[1].value as? String ?? "",
                contextData: array[2].value as? String ?? "",
                timestamp: array[3].value as? String ?? "",
                imageURL: array[4].value as? String ?? "",
                status: array[5].value as? Int ?? 0
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let rawArrays = celebrities.map { celebrity in
            [
                AnyCodable(celebrity.id),
                AnyCodable(celebrity.name),
                AnyCodable(celebrity.contextData),
                AnyCodable(celebrity.timestamp),
                AnyCodable(celebrity.imageURL),
                AnyCodable(celebrity.status)
            ]
        }
        try container.encode(rawArrays)
    }
}

// Structured celebrity data model for easier use
struct CelebrityData {
    let id: Int
    let name: String
    let contextData: String
    let timestamp: String
    let imageURL: String
    let status: Int
    
    init(id: Int, name: String, contextData: String, timestamp: String, imageURL: String, status: Int) {
        self.id = id
        self.name = name
        self.contextData = contextData
        self.timestamp = timestamp
        self.imageURL = imageURL
        self.status = status
    }
}

// HTTP Method enum
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// Helper struct to handle Any type in JSON
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

// MARK: - API Errors
enum APIError: Error {
    case invalidURL
    case noData
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Centralized API Manager
class APIManager: ObservableObject {
    static let shared = APIManager()
    
    // UPDATED: Unified Base URL for all APIs
    private let baseURL = "https://django-api-test-rubo.onrender.com"
    // Keep Spotify separate (third-party API)
    private let spotifyBaseURL = "https://api.spotify.com/v1"
    
    // JSON Encoder/Decoder
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    private init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Generic Request Method
    private func performRequest<T: Codable>(
        url: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String] = ["Content-Type": "application/json"],
        responseType: T.Type,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        guard let requestURL = URL(string: url) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 30.0
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                completion(.failure(.httpError(httpResponse.statusCode)))
                return
            }
            
            do {
                let decodedResponse = try self.decoder.decode(responseType, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
    
    // MARK: - Health Data & User Analysis APIs
    func fetchUserAnalysis(for username: String, completion: @escaping (Result<UserAnalysisResponse, APIError>) -> Void) {
        let requestBody = UserAnalysisRequest(username: username)
        
        do {
            let jsonData = try encoder.encode(requestBody)
            performRequest(
                url: "\(baseURL)/api/user_analysis/analyze_user/",
                method: .POST,
                body: jsonData,
                responseType: UserAnalysisResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    func sendHealthData(username: String, healthData: [String: Any], completion: @escaping (Result<InsertHealthResponse, APIError>) -> Void) {
        let codableHealthData = healthData.mapValues { AnyCodable($0) }
        let requestBody = InsertHealthRequest(username: username, healthData: codableHealthData)
        
        do {
            let jsonData = try encoder.encode(requestBody)
            performRequest(
                url: "\(baseURL)/api/logger/insert_health/",
                method: .POST,
                body: jsonData,
                responseType: InsertHealthResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    func sendHealthDataAndFetchAnalysis(username: String, healthData: [String: Any], completion: @escaping (Result<UserAnalysisResponse, APIError>) -> Void) {
        sendHealthData(username: username, healthData: healthData) { [weak self] result in
            switch result {
            case .success(_):
                self?.fetchUserAnalysis(for: username, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Authentication APIs
    func login(username: String, password: String, completion: @escaping (Result<AuthResponse, APIError>) -> Void) {
        let requestBody = LoginRequest(username: username, password: password)
        
        do {
            let jsonData = try encoder.encode(requestBody)
            performRequest(
                url: "\(baseURL)/api/auth/login/",
                method: .POST,
                body: jsonData,
                responseType: AuthResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    func register(username: String, password: String, completion: @escaping (Result<AuthResponse, APIError>) -> Void) {
        let requestBody = RegisterRequest(username: username, password: password)
        
        do {
            let jsonData = try encoder.encode(requestBody)
            performRequest(
                url: "\(baseURL)/api/auth/register/",
                method: .POST,
                body: jsonData,
                responseType: AuthResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    func socialAuth(username: String, completion: @escaping (Result<AuthResponse, APIError>) -> Void) {
        let requestBody = SocialAuthRequest(username: username)
        
        do {
            let jsonData = try encoder.encode(requestBody)
            performRequest(
                url: "\(baseURL)/api/auth/social_auth/",
                method: .POST,
                body: jsonData,
                responseType: AuthResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    // MARK: - Contact & Phone Management APIs
    func checkPhone(username: String, completion: @escaping (Result<CheckPhoneResponse, APIError>) -> Void) {
        let requestBody = CheckPhoneRequest(username: username)
        
        do {
            let jsonData = try encoder.encode(requestBody)
            performRequest(
                url: "\(baseURL)/api/contacts/check_phno/",
                method: .POST,
                body: jsonData,
                responseType: CheckPhoneResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    func updatePhone(username: String, phone: String, completion: @escaping (Result<UpdatePhoneResponse, APIError>) -> Void) {
        let requestBody = UpdatePhoneRequest(username: username, phno: phone)
        
        do {
            let jsonData = try encoder.encode(requestBody)
            performRequest(
                url: "\(baseURL)/api/contacts/update_phno/",
                method: .POST,
                body: jsonData,
                responseType: UpdatePhoneResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    func addContacts(username: String, contacts: [String], completion: @escaping (Result<AddContactsResponse, APIError>) -> Void) {
        let requestBody = AddContactsRequest(username: username, contacts: contacts)
        
        do {
            let jsonData = try encoder.encode(requestBody)
            performRequest(
                url: "\(baseURL)/api/contacts/add_contact/",
                method: .POST,
                body: jsonData,
                responseType: AddContactsResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    // MARK: - Follower API Methods
    func followUser(user: String, follower: String, completion: @escaping (Result<FollowResponse, APIError>) -> Void) {
        let requestBody = FollowRequest(user: user, follower: follower)
        
        do {
            let jsonData = try encoder.encode(requestBody)
            performRequest(
                url: "\(baseURL)/api/followers/follow/",
                method: .POST,
                body: jsonData,
                responseType: FollowResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    func unfollowUser(user: String, follower: String, completion: @escaping (Result<UnfollowResponse, APIError>) -> Void) {
        let requestBody = UnfollowRequest(user: user, follower: follower)
        
        do {
            let jsonData = try encoder.encode(requestBody)
            performRequest(
                url: "\(baseURL)/api/followers/unfollow/",
                method: .POST,
                body: jsonData,
                responseType: UnfollowResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    func getFollowers(user: String, completion: @escaping (Result<GetFollowersResponse, APIError>) -> Void) {
        let requestBody = GetFollowersRequest(user: user)
        
        do {
            let jsonData = try encoder.encode(requestBody)
            performRequest(
                url: "\(baseURL)/api/followers/get_followers/",
                method: .POST,
                body: jsonData,
                responseType: GetFollowersResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    // New method to get the user's following list
    func getFollowing(user: String, completion: @escaping (Result<GetFollowingResponse, APIError>) -> Void) {
        let requestBody = GetFollowingRequest(user: user)
        
        do {
            let jsonData = try encoder.encode(requestBody)
            performRequest(
                url: "\(baseURL)/api/followers/get_following/",
                method: .POST,
                body: jsonData,
                responseType: GetFollowingResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    // MARK: - Legacy Compatibility Methods
    func followUserWithCleanedPhone(phoneNumber: String, followerUsername: String) {
        // For backward compatibility - use the new follow API
        followUser(user: phoneNumber, follower: followerUsername) { result in
            switch result {
            case .success(let response):
                print("Follow successful: \(response.message)")
            case .failure(let error):
                print("Follow failed: \(error.localizedDescription)")
            }
        }
    }
    
    func unfollowUserWithCleanedPhone(phoneNumber: String, followerUsername: String) {
        // For backward compatibility - use the new unfollow API
        unfollowUser(user: phoneNumber, follower: followerUsername) { result in
            switch result {
            case .success(let response):
                print("Unfollow successful: \(response.message)")
            case .failure(let error):
                print("Unfollow failed: \(error.localizedDescription)")
            }
        }
    }
    
    func getFollowersWithErrorHandling(username: String) {
        // For backward compatibility - use the new get followers API
        getFollowers(user: username) { result in
            switch result {
            case .success(let response):
                print("Followers retrieved: \(response.followers)")
            case .failure(let error):
                print("Get followers failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Logger API Methods
    func logActivity(email: String, action: String, time: String, completion: @escaping (Result<LogActivityResponse, APIError>) -> Void) {
        let activityData = ActivityData(action: action, time: time)
        let requestBody = LogActivityRequest(email: email, activity: activityData)
        
        do {
            let jsonData = try encoder.encode(requestBody)
            performRequest(
                url: "\(baseURL)/api/logger/log-activity/",
                method: .POST,
                body: jsonData,
                responseType: LogActivityResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    func insertHealth(username: String, healthData: [String: Any], completion: @escaping (Result<InsertHealthResponse, APIError>) -> Void) {
        // Convert [String: Any] to [String: AnyCodable]
        let encodableHealthData = healthData.mapValues { AnyCodable($0) }
        let requestBody = InsertHealthRequest(username: username, healthData: encodableHealthData)
        
        do {
            let jsonData = try encoder.encode(requestBody)
            performRequest(
                url: "\(baseURL)/api/logger/insert_health/",
                method: .POST,
                body: jsonData,
                responseType: InsertHealthResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    func insertLocation(username: String, longitude: Double, latitude: Double, completion: @escaping (Result<InsertLocationResponse, APIError>) -> Void) {
        let requestBody = InsertLocationRequest(username: username, longitude: longitude, latitude: latitude)
        
        do {
            let jsonData = try encoder.encode(requestBody)
            performRequest(
                url: "\(baseURL)/api/logger/insert_location/",
                method: .POST,
                body: jsonData,
                responseType: InsertLocationResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    // MARK: - Activity Tracking APIs
    // Note: logActivity is now handled by the Logger API method above
    
    // MARK: - Location APIs
    // Note: insertLocation is now handled by the Logger API method above
    
    // MARK: - Mood APIs
    func fetchUserMood(userId: String, completion: @escaping (Result<MoodResponse, APIError>) -> Void) {
        performRequest(
            url: "\(baseURL)/users/\(userId)/mood",
            method: .GET,
            responseType: MoodResponse.self,
            completion: completion
        )
    }
    
    func updateUserMood(userId: String, mood: MoodUpdateRequest, completion: @escaping (Result<MoodUpdateResponse, APIError>) -> Void) {
        do {
            let jsonData = try encoder.encode(mood)
            performRequest(
                url: "\(baseURL)/users/\(userId)/mood",
                method: .PUT,
                body: jsonData,
                responseType: MoodUpdateResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    func fetchCityMood(city: String, completion: @escaping (Result<CityMoodResponse, APIError>) -> Void) {
        performRequest(
            url: "\(baseURL)/cities/\(city)/mood",
            method: .GET,
            responseType: CityMoodResponse.self,
            completion: completion
        )
    }
    
    func fetchContactsMoods(contactIds: [String], completion: @escaping (Result<[ContactMoodResponse], APIError>) -> Void) {
        let idsString = contactIds.joined(separator: ",")
        performRequest(
            url: "\(baseURL)/contacts/moods?ids=\(idsString)",
            method: .GET,
            responseType: [ContactMoodResponse].self,
            completion: completion
        )
    }
    
    func analyzeEmotionalPattern(userId: String, timeRange: TimeRange, completion: @escaping (Result<EmotionalPatternResponse, APIError>) -> Void) {
        do {
            let jsonData = try encoder.encode(timeRange)
            performRequest(
                url: "\(baseURL)/users/\(userId)/patterns",
                method: .POST,
                body: jsonData,
                responseType: EmotionalPatternResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    // MARK: - Spotify APIs
    func fetchSpotifyPlaylists(accessToken: String, completion: @escaping (Result<SpotifyPlaylistResponse, APIError>) -> Void) {
        performRequest(
            url: "\(spotifyBaseURL)/me/playlists",
            method: .GET,
            headers: ["Authorization": "Bearer \(accessToken)"],
            responseType: SpotifyPlaylistResponse.self,
            completion: completion
        )
    }
    
    func fetchSpotifyPlaylistTracks(playlistId: String, accessToken: String, completion: @escaping (Result<SpotifyTracksResponse, APIError>) -> Void) {
        performRequest(
            url: "\(spotifyBaseURL)/playlists/\(playlistId)/tracks",
            method: .GET,
            headers: ["Authorization": "Bearer \(accessToken)"],
            responseType: SpotifyTracksResponse.self,
            completion: completion
        )
    }
    
    func fetchSpotifyRecentlyPlayed(accessToken: String, completion: @escaping (Result<SpotifyRecentlyPlayedResponse, APIError>) -> Void) {
        performRequest(
            url: "\(spotifyBaseURL)/me/player/recently-played?limit=50",
            method: .GET,
            headers: ["Authorization": "Bearer \(accessToken)"],
            responseType: SpotifyRecentlyPlayedResponse.self,
            completion: completion
        )
    }
    
    // MARK: - Celebrity APIs
    func fetchCelebrityList(completion: @escaping (Result<CelebrityListResponse, APIError>) -> Void) {
        performRequest(
            url: "\(baseURL)/api/celebrity/user_emotions/celebs/",
            method: .GET,
            responseType: CelebrityListResponse.self,
            completion: completion
        )
    }
    
    func fetchCelebrityScoop(celebrityName: String, completion: @escaping (Result<CelebrityScoopResponse, APIError>) -> Void) {
        let requestBody = CelebrityScoopRequest(name: celebrityName)
        
        do {
            let jsonData = try encoder.encode(requestBody)
            performRequest(
                url: "\(baseURL)/api/celebrity/get_latest_scoop/",
                method: .POST,
                body: jsonData,
                responseType: CelebrityScoopResponse.self,
                completion: completion
            )
        } catch {
            completion(.failure(.encodingError(error)))
        }
    }
    
    // MARK: - Additional API Methods for Compatibility
    
    // Alias for sendHealthData for backward compatibility
    func insertHealthData(username: String, healthData: HealthData, completion: @escaping (Result<InsertHealthResponse, APIError>) -> Void) {
        let healthDict: [String: Any] = [
            "heart_rate": healthData.heartRate ?? 0,
            "steps": healthData.steps ?? 0,
            "sleep_hours": healthData.sleepHours ?? 0,
            "weight": healthData.weight ?? 0,
            "blood_pressure": healthData.bloodPressure ?? ""
        ]
        sendHealthData(username: username, healthData: healthDict, completion: completion)
    }
    
    // Analytics tracking methods (stub implementations)
    func logScreenView(email: String, screenName: String, completion: @escaping (Result<LogActivityResponse, APIError>) -> Void = { _ in }) {
        let currentTime = ISO8601DateFormatter().string(from: Date())
        logActivity(email: email, action: "screen_view_\(screenName)", time: currentTime, completion: completion)
    }
    
    func logButtonTap(email: String, buttonName: String, screenName: String, completion: @escaping (Result<LogActivityResponse, APIError>) -> Void = { _ in }) {
        let currentTime = ISO8601DateFormatter().string(from: Date())
        logActivity(email: email, action: "button_tap_\(buttonName)_on_\(screenName)", time: currentTime, completion: completion)
    }
    
    func logTimeSpent(email: String, screenName: String, duration: Double, completion: @escaping (Result<LogActivityResponse, APIError>) -> Void = { _ in }) {
        let currentTime = ISO8601DateFormatter().string(from: Date())
        logActivity(email: email, action: "time_spent_\(screenName)_\(Int(duration))s", time: currentTime, completion: completion)
    }
    
    // User analysis alias for backward compatibility
    func analyzeUser(username: String, completion: @escaping (Result<UserAnalysis, APIError>) -> Void) {
        fetchUserAnalysis(for: username) { result in
            switch result {
            case .success(let response):
                let analysis = UserAnalysis(
                    username: username,
                    overallMood: response.socialVibe, // Using socialVibe as overall mood
                    insights: [response.aiScoop, response.mentalPulse],
                    recommendations: response.crispAnalyticsPoints,
                    timestamp: Date()
                )
                completion(.success(analysis))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
} 