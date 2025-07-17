//
//  AuthManager.swift
//  moodgpt
//
//  Created by Test on 5/31/25.
//

import Foundation
import Combine
import GoogleSignIn
import AuthenticationServices

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUsername: String = ""
    @Published var currentName: String = ""
    @Published var authStatus = "Not logged in"
    @Published var isLoading = false
    @Published var isFirstTimeUser = true
    @Published var isGuestMode = false
    @Published var lastUsernameChange: Date?
    @Published var takePhoneNumber: Bool = false
    @Published var hasPhoneNumber: Bool = false
    var onPhoneNumberNeeded: (() -> Void)?

    private let apiManager = APIManager.shared
    
    // URL references for testing (kept for compatibility)
    private let loginURL = "https://user-login-register-d6yw.onrender.com/login"
    private let registerURL = "https://user-login-register-d6yw.onrender.com/register"
    
    // Try different possible passwords that might work with the backend
    private let possiblePasswords = ["12345678", "123456", "password", "12345", ""]
    
    init() {
        // Load last username change date
        if let lastChangeDate = UserDefaults.standard.object(forKey: "LastUsernameChange") as? Date {
            lastUsernameChange = lastChangeDate
        }
        
        // Check if user was previously logged in
        if let savedUsername = UserDefaults.standard.string(forKey: "LoggedInUsername"),
           let savedName = UserDefaults.standard.string(forKey: "LoggedInName") {
            currentUsername = savedUsername
            currentName = savedName
            isAuthenticated = true
            authStatus = "Logged in as \(savedName)"
            isFirstTimeUser = false
        } else if UserDefaults.standard.bool(forKey: "IsGuestMode") {
            // Check if user is in guest mode
            isGuestMode = true
            isAuthenticated = true
            currentUsername = UserDefaults.standard.string(forKey: "GuestUsername") ?? generateGuestUsername()
            currentName = UserDefaults.standard.string(forKey: "GuestName") ?? "Guest User"
            authStatus = "Guest mode"
            isFirstTimeUser = false
        } else {
            // Check if app has been used before (even if not currently logged in)
            isFirstTimeUser = !UserDefaults.standard.bool(forKey: "HasUsedAppBefore")
        }
    }
    
    // MARK: - Authentication Methods
    
    func loginUserInstantly(username: String, name: String) {
        guard !username.isEmpty else {
            authStatus = "Username cannot be empty"
            return
        }
        
        guard !name.isEmpty else {
            authStatus = "Name cannot be empty"
            return
        }
        
        print("⚡ Instant login for: \(name) (@\(username))")
        
        // Authenticate immediately without API calls
        currentUsername = username
        currentName = name
        isAuthenticated = true
        authStatus = "Welcome to CheckIn, \(name)!"
        isFirstTimeUser = false
        isGuestMode = false
        
        // Save login state locally
        UserDefaults.standard.set(username, forKey: "LoggedInUsername")
        UserDefaults.standard.set(name, forKey: "LoggedInName")
        UserDefaults.standard.set(true, forKey: "HasUsedAppBefore")
        UserDefaults.standard.set(false, forKey: "IsGuestMode")
        
        print("User instantly authenticated: \(name) (@\(username))")
        
        // Trigger header stats submission for instant authenticated user
        triggerHeaderStatsSubmission(username: username)
        
        // Post notification for following list sync
        NotificationCenter.default.post(
            name: NSNotification.Name("UserAuthenticated"),
            object: nil,
            userInfo: ["username": username]
        )
        
        // Later, sync with API in background (optional)
        DispatchQueue.global(qos: .background).async {
            self.syncUserWithAPIInBackground(username: username, name: name)
        }
    }
    
    /// Trigger health data manager to submit header stats for authenticated user
    private func triggerHeaderStatsSubmission(username: String) {
        // Find and notify the health data manager to update username and submit stats
        DispatchQueue.global(qos: .background).async {
            NotificationCenter.default.post(
                name: NSNotification.Name("UserAuthenticatedForHeaderStats"),
                object: nil,
                userInfo: ["username": username]
            )
        }
    }
    
    private func syncUserWithAPIInBackground(username: String, name: String) {
        print("🔄 Background sync: Registering user with API...")
        
        // Try to register user in background using centralized APIManager
        apiManager.register(username: username, password: "12345678") { result in
            switch result {
            case .success(let response):
                if response.success {
                    print("Background sync: User registered with API successfully")
                } else {
                    print("⚠️ Background sync: API registration failed - \(response.message ?? "Unknown error")")
                }
            case .failure(let error):
                print("⚠️ Background sync: Network error - \(error.localizedDescription)")
            }
            // Don't update UI or show errors - this is background sync
        }
    }
    
    func loginUser(username: String, name: String) {
        guard !username.isEmpty else {
            authStatus = "Username cannot be empty"
            return
        }
        
        guard !name.isEmpty else {
            authStatus = "Name cannot be empty"
            return
        }
        
        isLoading = true
        authStatus = "Checking in..."
        
        // Try login with the first password option
        tryLoginWithPassword(username: username, name: name, passwordIndex: 0)
    }
    
    private func tryLoginWithPassword(username: String, name: String, passwordIndex: Int) {
        // If we've tried all passwords, try social auth
        if passwordIndex >= possiblePasswords.count {
            trySocialAuth(username: username, name: name)
            return
        }
        
        let password = possiblePasswords[passwordIndex]
        print("🔐 Trying login with password approach #\(passwordIndex + 1): '\(password.isEmpty ? "(empty)" : password)'")
        
        // Skip empty passwords since the new API requires a password
        if password.isEmpty {
            tryLoginWithPassword(username: username, name: name, passwordIndex: passwordIndex + 1)
            return
        }
        
        apiManager.login(username: username, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        print("Login successful with password approach #\(passwordIndex + 1)")
                        self?.isLoading = false
                        self?.handleSuccessfulAuth(username: username, name: name, message: response.message ?? "Login successful")
                    } else {
                        print("Login failed with password approach #\(passwordIndex + 1): \(response.message ?? "Unknown error")")
                        // Try next password
                        self?.tryLoginWithPassword(username: username, name: name, passwordIndex: passwordIndex + 1)
                    }
                case .failure(let error):
                    print("Login failed with password approach #\(passwordIndex + 1): \(error.localizedDescription)")
                    // Try next password
                    self?.tryLoginWithPassword(username: username, name: name, passwordIndex: passwordIndex + 1)
                }
            }
        }
    }
    
    private func trySocialAuth(username: String, name: String) {
        print("🔐 Trying social auth")
        
        apiManager.socialAuth(username: username) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        print("Social auth successful")
                        self?.isLoading = false
                        self?.handleSuccessfulAuth(username: username, name: name, message: response.message ?? "Login successful")
                    } else {
                        print("Social auth failed: \(response.message ?? "Unknown error")")
                        // Try registration
                        self?.registerUser(username: username, name: name)
                    }
                case .failure(let error):
                    print("Social auth failed: \(error.localizedDescription)")
                    // Try registration
                    self?.registerUser(username: username, name: name)
                }
            }
        }
    }
    
    private func registerUser(username: String, name: String) {
        isLoading = true
        authStatus = "Creating your account..."
        
        // Try registration with different password approaches
        tryRegisterWithPassword(username: username, name: name, passwordIndex: 0)
    }
    
    private func tryRegisterWithPassword(username: String, name: String, passwordIndex: Int) {
        // If we've tried all passwords, fail registration
        if passwordIndex >= possiblePasswords.count {
            DispatchQueue.main.async {
                self.isLoading = false
                self.authStatus = "Registration failed - unable to create account"
            }
            return
        }
        
        let password = possiblePasswords[passwordIndex]
        print("🔐 Trying registration with password approach #\(passwordIndex + 1): '\(password.isEmpty ? "(empty)" : password)'")
        
        // Skip empty passwords since the new API requires a password
        if password.isEmpty {
            tryRegisterWithPassword(username: username, name: name, passwordIndex: passwordIndex + 1)
            return
        }
        
        apiManager.register(username: username, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        print("Registration successful with password approach #\(passwordIndex + 1)")
                        self?.isLoading = false
                        self?.handleSuccessfulAuth(username: username, name: name, message: "Welcome to CheckIn, \(name)!")
                    } else {
                        print("Registration failed with password approach #\(passwordIndex + 1): \(response.message ?? "Unknown error")")
                        // Try next password
                        self?.tryRegisterWithPassword(username: username, name: name, passwordIndex: passwordIndex + 1)
                    }
                case .failure(let error):
                    print("Registration failed with password approach #\(passwordIndex + 1): \(error.localizedDescription)")
                    // Try next password
                    self?.tryRegisterWithPassword(username: username, name: name, passwordIndex: passwordIndex + 1)
                }
            }
        }
    }
    
    // Method removed - registration now requires password
    
    private func handleSuccessfulAuth(username: String, name: String, message: String) {
        currentUsername = username
        currentName = name
        isAuthenticated = true
        authStatus = message
        isFirstTimeUser = false
        
        // Save login state
        UserDefaults.standard.set(username, forKey: "LoggedInUsername")
        UserDefaults.standard.set(name, forKey: "LoggedInName")
        UserDefaults.standard.set(true, forKey: "HasUsedAppBefore")
        
        print("User authenticated: \(name) (@\(username))")
        
        // Trigger header stats submission for new authenticated user
        triggerHeaderStatsSubmission(username: username)
        
        // Post notification for following list sync
        NotificationCenter.default.post(
            name: NSNotification.Name("UserAuthenticated"),
            object: nil,
            userInfo: ["username": username]
        )
    }
    
    // Public method for new authentication views
    func handleSuccessfulLogin(username: String, name: String) {
        currentUsername = username
        currentName = name
        isAuthenticated = true
        authStatus = "Welcome back, \(name)!"
        isFirstTimeUser = false
        isGuestMode = false
        
        // Save login state
        UserDefaults.standard.set(username, forKey: "LoggedInUsername")
        UserDefaults.standard.set(name, forKey: "LoggedInName")
        UserDefaults.standard.set(true, forKey: "HasUsedAppBefore")
        UserDefaults.standard.set(false, forKey: "IsGuestMode")
        
        print("User successfully logged in: \(name) (@\(username))")
        
        // Trigger header stats submission for authenticated user
        triggerHeaderStatsSubmission(username: username)
        
        // Post notification for following list sync
        NotificationCenter.default.post(
            name: NSNotification.Name("UserAuthenticated"),
            object: nil,
            userInfo: ["username": username]
        )
    }
    
    func logout() {
        // Clear user cache before logging out
        CacheManager.shared.clearUserCache(for: currentUsername)
        
        currentUsername = ""
        currentName = ""
        isAuthenticated = false
        authStatus = "Logged out"
        isGuestMode = false
        
        // Clear saved login state
        UserDefaults.standard.removeObject(forKey: "LoggedInUsername")
        UserDefaults.standard.removeObject(forKey: "LoggedInName")
        UserDefaults.standard.removeObject(forKey: "IsGuestMode")
        
        print("👋 User logged out")
    }
    
    // MARK: - Network Request Helper
    
    private func performRequest(url: String, data: [String: String], isLogin: Bool, completion: @escaping (Bool, String) -> Void) {
        guard let requestURL = URL(string: url) else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0 // Increased timeout
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            request.httpBody = jsonData
            
            // Print the exact request being sent
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("🔐 Sending \(isLogin ? "login" : "register") request:")
                print("   URL: \(url)")
                print("   Method: POST")
                print("   Headers: \(request.allHTTPHeaderFields ?? [:])")
                print("   JSON Body: \(jsonString)")
                print("   Body Size: \(jsonData.count) bytes")
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Auth Network Error: \(error.localizedDescription)")
                    completion(false, "Network error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📥 Auth API Response:")
                    print("   Status Code: \(httpResponse.statusCode)")
                    print("   Headers: \(httpResponse.allHeaderFields)")
                    
                    var responseBody = "No response body"
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        responseBody = responseString
                        print("   Response Body: \(responseString)")
                        print("   Response Size: \(data.count) bytes")
                    }
                    
                    switch httpResponse.statusCode {
                    case 200...299:
                        print("Auth API Success: \(httpResponse.statusCode)")
                        completion(true, isLogin ? "Login successful" : "Registration successful")
                    case 400:
                        print("Auth API Bad Request (400): \(responseBody)")
                        completion(false, isLogin ? "Invalid credentials or bad request" : "Username already exists or bad request")
                    case 401:
                        print("Auth API Unauthorized (401): \(responseBody)")
                        completion(false, "Authentication failed - invalid credentials")
                    case 403:
                        print("Auth API Forbidden (403): \(responseBody)")
                        completion(false, "Access denied")
                    case 404:
                        print("Auth API Not Found (404): \(responseBody)")
                        completion(false, "Auth endpoint not found")
                    case 500...599:
                        print("Auth API Server Error (\(httpResponse.statusCode)): \(responseBody)")
                        completion(false, "Server error (\(httpResponse.statusCode))")
                    default:
                        print("Auth API Unknown Status (\(httpResponse.statusCode)): \(responseBody)")
                        completion(false, "Unknown error (Code: \(httpResponse.statusCode))")
                    }
                } else {
                    print("Auth API: Invalid response object")
                    completion(false, "Invalid response from server")
                }
            }.resume()
            
        } catch {
            print("Failed to encode auth data: \(error)")
            completion(false, "Failed to encode request data: \(error.localizedDescription)")
        }
    }

    func performRequest<T: Decodable>(url: String, data: [String: String], responseType: T.Type) async -> Result<T?, Error> {
        guard let requestURL = URL(string: url) else {
            return .failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil))
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0 // Increased timeout
        
        do {
            // Convert dictionary to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            request.httpBody = jsonData
            
            // Print the exact request being sent
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("   URL: \(url)")
                print("   Method: POST")
                print("   Headers: \(request.allHTTPHeaderFields ?? [:])")
                print("   JSON Body: \(jsonString)")
                print("   Body Size: \(jsonData.count) bytes")
            }
            
            // Perform the network request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Auth API Response:")
                print("   Status Code: \(httpResponse.statusCode)")
                print("   Headers: \(httpResponse.allHeaderFields)")
                
                var responseBody = "No response body"
                if let responseString = String(data: data, encoding: .utf8) {
                    responseBody = responseString
                    print("   Response Body: \(responseString)")
                    print("   Response Size: \(data.count) bytes")
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    print("Auth API Success: \(httpResponse.statusCode)")
                    
                    // Try decoding the response body into the expected object type
                    do {
                        let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                        return .success(decodedResponse)
                    } catch {
                        print("Failed to decode response: \(error.localizedDescription)")
                        return .failure(error)
                    }
                    
                case 400:
                    print("Auth API Bad Request (400): \(responseBody)")
                    return .failure(NSError(domain: "Bad request", code: 400, userInfo: nil))
                case 401:
                    print("Auth API Unauthorized (401): \(responseBody)")
                    return .failure(NSError(domain: "Authentication failed - invalid credentials", code: 401, userInfo: nil))
                case 403:
                    print("Auth API Forbidden (403): \(responseBody)")
                    return .failure(NSError(domain: "Access denied", code: 403, userInfo: nil))
                case 404:
                    print("Auth API Not Found (404): \(responseBody)")
                    return .failure(NSError(domain: "Auth endpoint not found", code: 404, userInfo: nil))
                case 500...599:
                    print("Auth API Server Error (\(httpResponse.statusCode)): \(responseBody)")
                    return .failure(NSError(domain: "Server error", code: httpResponse.statusCode, userInfo: nil))
                default:
                    print("Auth API Unknown Status (\(httpResponse.statusCode)): \(responseBody)")
                    return .failure(NSError(domain: "Unknown error", code: httpResponse.statusCode, userInfo: nil))
                }
            } else {
                return .failure(NSError(domain: "Invalid response object", code: 500, userInfo: nil))
            }
        } catch {
            print("Failed to encode auth data: \(error)")
            return .failure(error)
        }
    }


    
    // MARK: - Debug Methods
    
    func testAuthEndpoints() {
        print("Testing authentication endpoints...")
        
        // Test with a simple curl-equivalent request
        testEndpoint(url: loginURL, data: ["username": "testuser", "password": "12345678"], name: "Login")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.testEndpoint(url: self.registerURL, data: ["username": "testuser123", "password": "12345678"], name: "Register")
        }
    }
    
    private func testEndpoint(url: String, data: [String: String], name: String) {
        print("Testing \(name) endpoint: \(url)")
        
        performRequest(url: url, data: data, isLogin: name == "Login") { success, message in
            print("\(name) test result: \(success ? "SUCCESS" : "FAILED") - \(message)")
        }
    }
    
    // MARK: - Skip/Random User Generation
    
    func generateRandomUser() -> (username: String, name: String) {
        let adjectives = ["Cool", "Smart", "Happy", "Bright", "Swift", "Bold", "Calm", "Nice", "Kind", "Wise", 
                         "Epic", "Quick", "Zen", "Prime", "Pure", "Super", "Ultra", "Mega", "Stellar", "Cosmic"]
        let nouns = ["Tiger", "Eagle", "Lion", "Fox", "Wolf", "Bear", "Star", "Moon", "Sun", "River", 
                    "Ocean", "Storm", "Fire", "Lightning", "Thunder", "Wind", "Galaxy", "Comet", "Phoenix", "Dragon"]
        
        // Use timestamp for better uniqueness
        let timestamp = String(Int(Date().timeIntervalSince1970) % 10000)
        
        let randomAdjective = adjectives.randomElement() ?? "Cool"
        let randomNoun = nouns.randomElement() ?? "User"
        
        let username = "\(randomAdjective.lowercased())\(randomNoun.lowercased())\(timestamp)"
        let name = "\(randomAdjective) \(randomNoun)"
        
        return (username: username, name: name)
    }
    
    func skipOnboardingWithRandomUser() {
        let randomUser = generateRandomUser()
        
        isLoading = true
        authStatus = "Creating \(randomUser.name) (@\(randomUser.username))..."
        
        print("🎲 Generating random user: \(randomUser.name) (@\(randomUser.username))")
        
        // Try to register the random user (skip login attempt since it's new)
        registerUser(username: randomUser.username, name: randomUser.name)
    }
    
    // MARK: - Guest Mode
    
    func enterGuestMode() {
        print("👤 Entering guest mode - no authentication required")
        
        let guestUsername = generateGuestUsername()
        let guestName = "Guest User"
        
        isGuestMode = true
        isAuthenticated = true
        currentUsername = guestUsername
        currentName = guestName
        authStatus = "Guest mode - no account needed"
        isFirstTimeUser = false
        
        // Save guest mode state
        UserDefaults.standard.set(true, forKey: "IsGuestMode")
        UserDefaults.standard.set(guestUsername, forKey: "GuestUsername")
        UserDefaults.standard.set(guestName, forKey: "GuestName")
        UserDefaults.standard.set(true, forKey: "HasUsedAppBefore")
        
        print("Guest mode activated with username: \(guestUsername)")
    }
    
    // MARK: - Guest Username Generation
    
    private func generateGuestUsername() -> String {
        // Generate a number between 000001 and 999999 for guest users
        let guestNumber = Int.random(in: 1...999999)
        let paddedNumber = String(format: "%06d", guestNumber)
        return "guest\(paddedNumber)"
    }
    
    // MARK: - Username Management
    
    func canChangeUsername() -> Bool {
        guard let lastChange = lastUsernameChange else { return true }
        let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        return lastChange < fourteenDaysAgo
    }
    
    func daysUntilUsernameChange() -> Int {
        guard let lastChange = lastUsernameChange else { return 0 }
        let fourteenDaysLater = Calendar.current.date(byAdding: .day, value: 14, to: lastChange) ?? Date()
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: fourteenDaysLater).day ?? 0
        return max(0, daysLeft)
    }
    
    func updateUsername(_ newUsername: String, completion: @escaping (Bool, String) -> Void) {
        guard canChangeUsername() else {
            let daysLeft = daysUntilUsernameChange()
            completion(false, "You can change your username again in \(daysLeft) days")
            return
        }
        
        guard !newUsername.isEmpty && newUsername.count >= 3 && newUsername.count <= 20 else {
            completion(false, "Username must be between 3-20 characters")
            return
        }
        
        // Check for valid characters
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
        guard newUsername.rangeOfCharacter(from: allowedCharacters.inverted) == nil else {
            completion(false, "Username can only contain letters, numbers, and underscores")
            return
        }
        
        // For guest users, just update locally
        if isGuestMode {
            currentUsername = newUsername
            lastUsernameChange = Date()
            
            UserDefaults.standard.set(newUsername, forKey: "GuestUsername")
            UserDefaults.standard.set(lastUsernameChange, forKey: "LastUsernameChange")
            
            completion(true, "Username updated successfully!")
            return
        }
        
        // For real users, we would typically make an API call here
        // For now, just update locally
        currentUsername = newUsername
        lastUsernameChange = Date()
        
        UserDefaults.standard.set(newUsername, forKey: "LoggedInUsername")
        UserDefaults.standard.set(lastUsernameChange, forKey: "LastUsernameChange")
        
        completion(true, "Username updated successfully!")
    }
    
    func updateName(_ newName: String, completion: @escaping (Bool, String) -> Void) {
        guard !newName.isEmpty && newName.count >= 2 && newName.count <= 50 else {
            completion(false, "Name must be between 2-50 characters")
            return
        }
        
        currentName = newName
        
        if isGuestMode {
            UserDefaults.standard.set(newName, forKey: "GuestName")
        } else {
            UserDefaults.standard.set(newName, forKey: "LoggedInName")
        }
        
        completion(true, "Name updated successfully!")
    }
} 

extension AuthManager {
    @MainActor
    func handleAuthorization(_ authorization: ASAuthorization, completion: @escaping ((_ email: String?, _ name: String?) -> Void)) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }
        
        // Handle the Apple ID credential here
        let userID = appleIDCredential.user
        let fullName = appleIDCredential.fullName
        let email = appleIDCredential.email
        
        // Example: Store these values in your app or use them for further authentication
        print("User ID: \(userID)")
        print("Full Name: \(fullName?.givenName ?? "") \(fullName?.familyName ?? "")")
        print("Email: \(email ?? "No email provided")")
        completion(email,fullName?.givenName ?? "" )
    }
    
    @MainActor
    func authenticateUsingGoogle(completion: @escaping ((_ email: String?, _ name: String?) -> Void)) {
        let config = GIDConfiguration(clientID: Constants.googleAPIKey)
        
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
            .first else {
            print("No root view controller")
            return
        }
        self.isLoading = true
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {

                self.isLoading = false
                return
            }
            guard
                let email = result?.user.profile?.email,
                let name = result?.user.profile?.name else {
                return
            }
            completion(email, name)
        }
    }
    
    @MainActor
    func trySocialLogin(email: String, name: String) {
        performRequest(
            url: "https://user-login-register-d6yw.onrender.com/social_auth",
            data: ["username": email],
            isLogin: true) { [weak self] success, message in
                if success == false && message.lowercased().contains("User not found".lowercased()) {
                    self?.trySocialRegister(email: email, name: name)
                } else {
                    self?.userAuthenticatedSocial(email: email, name: name)
                }
            }
    }
    @MainActor
    private func trySocialRegister(email: String, name: String) {
        performRequest(
            url: "https://user-login-register-d6yw.onrender.com/social_register",
            data: ["username": email],
            isLogin: false) { [weak self] success, message in

                if success {
                    self?.userAuthenticatedSocial(email: email, name: name)
                }
            }
    }
    
    private func userAuthenticatedSuccessfully(email: String, name: String) {
        
        checkPhoneNumber(username: email) { hasPhone in
            if hasPhone {
                DispatchQueue.main.async { [weak self] in
                    self?.currentUsername = email
                    self?.currentName = name
                    self?.isAuthenticated = true
                    self?.authStatus = "Welcome back, \(email)!"
                    self?.isFirstTimeUser = false
                    self?.isGuestMode = false
                    self?.isLoading = false
                    // Save login state
                    UserDefaults.standard.set(email, forKey: "LoggedInUsername")
                    UserDefaults.standard.set(name, forKey: "LoggedInName")
                    UserDefaults.standard.set(true, forKey: "HasUsedAppBefore")
                    UserDefaults.standard.set(false, forKey: "IsGuestMode")
                    
                    print("User successfully logged in: \(name) (@\(email))")
                    
                    // Post notification for following list sync
                    NotificationCenter.default.post(
                        name: NSNotification.Name("UserAuthenticated"),
                        object: nil,
                        userInfo: ["username": email]
                    )
                }
                // User has phone number, proceed with normal login
            } else {
                DispatchQueue.main.async {
                    self.onPhoneNumberNeeded?()
                }
            }
        }
        
        
    }
    
    private func userAuthenticatedSocial(email: String, name: String) {
        DispatchQueue.main.async { [weak self] in
            self?.currentUsername = email
            self?.currentName = name
            self?.isAuthenticated = true
            self?.authStatus = "Welcome back, \(email)!"
            self?.isFirstTimeUser = false
            self?.isGuestMode = false
            self?.isLoading = false
            // Save login state
            UserDefaults.standard.set(email, forKey: "LoggedInUsername")
            UserDefaults.standard.set(name, forKey: "LoggedInName")
            UserDefaults.standard.set(true, forKey: "HasUsedAppBefore")
            UserDefaults.standard.set(false, forKey: "IsGuestMode")
            
            print("User successfully logged in: \(name) (@\(email))")
            
            // Trigger header stats submission for social authenticated user
            self?.triggerHeaderStatsSubmission(username: email)
            
            // Post notification for following list sync
            NotificationCenter.default.post(
                name: NSNotification.Name("UserAuthenticated"),
                object: nil,
                userInfo: ["username": email]
            )
        }
    }
    
    
    private func checkPhoneNumber(username: String, completion: @escaping (Bool) -> Void) {
        apiManager.checkPhone(username: username) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    completion(response.exists)
                case .failure:
                    completion(false)
                }
            }
        }
    }
}

extension AuthManager {
    func checkPhoneNumberExist() {
        guard let userName = UserDefaults.standard.string(forKey: "LoggedInUsername") else { return }
        
        apiManager.checkPhone(username: userName) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.exists {
                        print("Phone Number Exist")
                        self?.hasPhoneNumber = true
                    } else {
                        print("Phone Number not found - user can add it in settings")
                        self?.hasPhoneNumber = false
                        // Removed automatic popup trigger - phone number is now optional and accessible via settings
                    }
                case .failure(let error):
                    print("Phone Number check failed: \(error.localizedDescription)")
                    self?.hasPhoneNumber = false
                    // Removed automatic popup trigger - phone number is now optional and accessible via settings
                }
            }
        }
    }
    
    
    func checkPhoneNumberExist(username: String, completion:@escaping ((Bool) -> Void)) {
        apiManager.checkPhone(username: username) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.exists {
                        print("Phone Number Exist")
                        completion(true)
                    } else {
                        print("Phone Number not found - user can add it in settings")
                        completion(false)
                        // Removed automatic popup trigger - phone number is now optional and accessible via settings
                    }
                case .failure(let error):
                    print("Phone Number check failed: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    func savePhoneNumber(phoneNumber: String, completion: @escaping (Bool) -> Void) {
        guard let userName = UserDefaults.standard.string(forKey: "LoggedInUsername") else { return }
        
        // Clean the phone number before sending to API
        let cleanedNumber = ContactProfileHelpers.cleanPhoneNumber(phoneNumber)
        
        apiManager.updatePhone(username: userName, phone: cleanedNumber) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        self?.hasPhoneNumber = true
                        completion(true)
                    } else {
                        completion(false)
                        print("Phone update failed: \(response.message)")
                    }
                case .failure(let error):
                    completion(false)
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func savePhoneNumber(username: String, phoneNumber: String, completion: @escaping (Bool) -> Void) {
        // Clean the phone number before sending to API
        let cleanedNumber = ContactProfileHelpers.cleanPhoneNumber(phoneNumber)
        
        apiManager.updatePhone(username: username, phone: cleanedNumber) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.success {
                        self?.hasPhoneNumber = true
                        completion(true)
                    } else {
                        completion(false)
                        print("Phone update failed: \(response.message)")
                    }
                case .failure(let error):
                    completion(false)
                    print(error.localizedDescription)
                }
            }
        }
    }
}


