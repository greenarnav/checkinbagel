import SpotifyiOS

class SpotifyAuthManager: NSObject, SPTSessionManagerDelegate {
    
    static let shared = SpotifyAuthManager()
    
    var sessionManager: SPTSessionManager?
    var accessToken: String?
    
    // Use centralized APIManager
    private let apiManager = APIManager.shared
    
    // Completion block to return session data or error
    var sessionCompletion: ((Result<Bool, Error>) -> Void)?
    
    // Initialize the session manager
    func configureSpotify(completion: @escaping (Result<Bool, Error>) -> Void) {
        let redirectURL = URL(string: "com.arnav.moody23.moodgpt://callback")!
        let clientID = "828489b0a84149cda135b1cf81c1a91c"
        let scope: SPTScope = [.appRemoteControl, .userLibraryRead, .userReadPrivate, .userReadRecentlyPlayed, .userTopRead]
        
        let configuration = SPTConfiguration(clientID: clientID, redirectURL: redirectURL)
        sessionManager = SPTSessionManager(configuration: configuration, delegate: self)
        sessionCompletion = completion
        sessionManager?.initiateSession(with: scope, options: .default, campaign: nil)
    }
    
    // SPTSessionManagerDelegate methods
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("Spotify session initiated successfully!")
        accessToken = session.accessToken
        print("Granted scopes: \(session.scope)")
        if session.scope.contains(SPTScope.userReadRecentlyPlayed) {
            print("userReadRecentlyPlayed scope is granted")
        }
        sessionCompletion?(.success(true))  // Return session data via the completion block
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("Error initiating session: \(error.localizedDescription)")
        sessionCompletion?(.failure(error))  // Return error via the completion block
    }
}

extension SpotifyAuthManager {
    // Fetch all playlists using centralized APIManager
    func fetchAllPlaylists(completion: @escaping (Result<[SpotifyPlaylist], Error>) -> Void) {
        guard let accessToken = accessToken else {
            completion(.failure(NSError(domain: "SpotifyAuthManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Access token is missing."])))
            return
        }
        
        apiManager.fetchSpotifyPlaylists(accessToken: accessToken) { result in
            switch result {
            case .success(let response):
                completion(.success(response.items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Fetch tracks for a specific playlist using centralized APIManager
    func fetchPlaylistTracks(playlistID: String, completion: @escaping (Result<[SpotifyTrack], Error>) -> Void) {
        guard let accessToken = accessToken else {
            completion(.failure(NSError(domain: "SpotifyAuthManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Access token is missing."])))
            return
        }
        
        apiManager.fetchSpotifyPlaylistTracks(playlistId: playlistID, accessToken: accessToken) { result in
            switch result {
            case .success(let response):
                completion(.success(response.items.map { $0.track }))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Fetch recently played tracks using centralized APIManager
    func fetchRecentlyPlayedList(completion: @escaping (Result<[SpotifyRecentItem], Error>) -> Void) {
        guard let accessToken = accessToken else {
            completion(.failure(NSError(domain: "SpotifyAuthManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Access token is missing."])))
            return
        }
        
        apiManager.fetchSpotifyRecentlyPlayed(accessToken: accessToken) { result in
            switch result {
            case .success(let response):
                completion(.success(response.items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Fetch saved tracks (Note: Not implemented in centralized APIManager yet)
    func fetchSavedTracks(completion: @escaping (Result<[SpotifyTrack], Error>) -> Void) {
        guard let accessToken = accessToken else {
            completion(.failure(NSError(domain: "SpotifyAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing token."])))
            return
        }

        // This endpoint is not yet implemented in centralized APIManager
        // For now, return empty array
        completion(.success([]))
    }
    
    // Fetch top tracks (Note: Not implemented in centralized APIManager yet)  
    func fetchTopTracks(completion: @escaping (Result<[SpotifyTrack], Error>) -> Void) {
        guard let accessToken = accessToken else {
            completion(.failure(NSError(domain: "SpotifyAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing token."])))
            return
        }
        
        // This endpoint is not yet implemented in centralized APIManager
        // For now, return empty array
        completion(.success([]))
    }
}

// MARK: - Legacy Spotify Models (Updated to match centralized APIManager)

// Update type aliases to match centralized APIManager models
typealias SPTPlaylist = SpotifyPlaylist
typealias SPTImage = SpotifyImage  
typealias SPTTrack = SpotifyTrack
typealias SPTArtist = SpotifyArtist
typealias RecentItem = SpotifyRecentItem

// Additional models that may be needed for backward compatibility
struct SPTAlbum: Codable {
    let name: String
    let images: [SpotifyImage]
}

struct SavedTracksResponse: Codable {
    let items: [SavedTrackItem]
}

struct SavedTrackItem: Codable {
    let track: SpotifyTrack
}

struct TopTracksResponse: Codable {
    let items: [SpotifyTrack]
}

// Legacy models for backward compatibility
struct PlaylistResponse: Codable {
    let items: [SpotifyPlaylist]
}

struct TracksResponse: Codable {
    let items: [PlaylistItem]
}

struct PlaylistItem: Codable {
    let track: SpotifyTrack
}

struct RecentlyPlayedResponse: Codable {
    let items: [SpotifyRecentItem]
}

// Keep Artist as an alias since it's used in other places
typealias Artist = SpotifyArtist
