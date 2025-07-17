import Foundation

struct ContactUpdateTest {
    
    static func runComprehensiveContactUpdateTest() {
        print("Running Comprehensive Contact Update Test")
        print("=" * 60)
        
        // Test 1: Verify API response is parseable
        testAPIResponseParsing()
        
        // Test 2: Verify emoji mapping is working
        testEmojiMappingFromAPI()
        
        // Test 3: Verify contact update logic
        testContactUpdateLogic()
        
        // Test 4: Verify SwiftUI change detection fix
        testSwiftUIChangeDetection()
        
        // Test 5: Verify user emotion API response
        testUserEmotionAPIResponse()
        
        print("=" * 60)
        print("Contact Update Test Complete!")
    }
    
    // MARK: - Test 1: API Response Parsing
    static func testAPIResponseParsing() {
        print("\nTest 1: API Response Parsing")
        print("-" * 30)
        
        let realAPIResponse = """
        {
            "contacts": {
                "Alice": {
                    "city": "",
                    "emotion": {
                        "behavior_factors": "Behavioral analysis data...",
                        "health_factors": "Health factors data...",
                        "predicted_emoji_id": 46,
                        "user_emotion_profile": "Neutral emotion profile..."
                    },
                    "number": "+1-555-123-4567"
                }
            }
        }
        """
        
        guard let data = realAPIResponse.data(using: .utf8) else {
            print("Failed to create test data")
            return
        }
        
        do {
            let response = try JSONDecoder().decode(EmotionContactsSentimentResponse.self, from: data)
            print("API response parsing successful")
            print("Contact count: \(response.contacts.count)")
            
            if let alice = response.contacts["Alice"] {
                print("Alice data parsed:")
                print("   - Emoji ID: \(alice.emotion.predictedEmojiId)")
                print("   - Has behavior data: \(!alice.emotion.behaviorFactors.isEmpty)")
                print("   - Has health data: \(!alice.emotion.healthFactors.isEmpty)")
            }
        } catch {
            print("API response parsing failed: \(error)")
        }
    }
    
    // MARK: - Test 2: Emoji Mapping from API
    static func testEmojiMappingFromAPI() {
        print("\n🎯 Test 2: Emoji Mapping from API")
        print("-" * 30)
        
        let testCases = [
            (46, "😐", "neutral-face"),
            (39, "😆", "laughing"),
            (61, "🫨", "shaking-face"),
            (27, "🙂", "head-nod")
        ]
        
        for (id, expectedEmoji, expectedName) in testCases {
            let actualEmoji = ContactProfileHelpers.emojiForID(id)
            let actualName = ContactProfileHelpers.emojiNameForID(id)
            
            if actualEmoji == expectedEmoji && actualName == expectedName {
                print("ID \(id): \(actualEmoji) (\(actualName))")
            } else {
                print("ID \(id): Expected \(expectedEmoji) (\(expectedName)), got \(actualEmoji) (\(actualName))")
            }
        }
    }
    
    // MARK: - Test 3: Contact Update Logic
    static func testContactUpdateLogic() {
        print("\n📱 Test 3: Contact Update Logic")
        print("-" * 30)
        
        // Create test contact
        var testContact = Contact(
            name: "Alice",
            location: "Test Location",
            mood: "🙂",
            moodText: "Neutral",
            phoneNumber: "+1-555-123-4567"
        )
        
        print("Before update: \(testContact.name) = \(testContact.mood) (\(testContact.moodText))")
        
        // Simulate emotion manager with test data
        let emotionManager = EmotionAnalysisManager.shared
        
        // Create test profile
        let testProfile = ContactProfile(
            contactName: "Alice",
            city: "Test City",
            emotion: ContactProfile.ContactEmotionDetail(
                behaviorFactors: "Test behavior",
                healthFactors: "Test health",
                predictedEmojiId: 46,
                userEmotionProfile: "Test emotion profile"
            ),
            phoneNumber: "+1-555-123-4567",
            lastUpdated: Date()
        )
        
        // Add to emotion manager
        emotionManager.contactProfiles["Alice"] = testProfile
        
        // Test the update method
        emotionManager.updateContact(&testContact)
        
        print("After update: \(testContact.name) = \(testContact.mood) (\(testContact.moodText))")
        print("Expected: Alice = 😐 (Neutral)")
        
        let success = testContact.mood == "😐" && testContact.predictedEmojiId == 46
        print(success ? "Contact update logic working!" : "Contact update logic failed!")
    }
    
    // MARK: - Test 4: SwiftUI Change Detection Fix
    static func testSwiftUIChangeDetection() {
        print("\n🔄 Test 4: SwiftUI Change Detection Fix")
        print("-" * 30)
        
        // Test the new getUpdatedContacts method
        let originalContacts = [
            Contact(name: "Alice", location: "Test", mood: "🙂", moodText: "Default", phoneNumber: "+1-555-123-4567"),
            Contact(name: "Bob", location: "Test", mood: "🙂", moodText: "Default", phoneNumber: "+1-310-987-6543")
        ]
        
        print("Original contacts created: \(originalContacts.count)")
        
        // Setup test profiles in emotion manager
        let emotionManager = EmotionAnalysisManager.shared
        emotionManager.contactProfiles["Alice"] = ContactProfile(
            contactName: "Alice",
            city: "",
            emotion: ContactProfile.ContactEmotionDetail(
                behaviorFactors: "Test",
                healthFactors: "Test",
                predictedEmojiId: 46,
                userEmotionProfile: "Neutral"
            ),
            phoneNumber: "+1-555-123-4567",
            lastUpdated: Date()
        )
        
        emotionManager.contactProfiles["Bob"] = ContactProfile(
            contactName: "Bob",
            city: "",
            emotion: ContactProfile.ContactEmotionDetail(
                behaviorFactors: "Test",
                healthFactors: "Test",
                predictedEmojiId: 39,
                userEmotionProfile: "Laughing"
            ),
            phoneNumber: "+1-310-987-6543",
            lastUpdated: Date()
        )
        
        // Test the new method
        let updatedContacts = emotionManager.getUpdatedContacts(from: originalContacts)
        
        print("Updated contacts: \(updatedContacts.count)")
        for (index, contact) in updatedContacts.enumerated() {
            print("   [\(index)]: \(contact.name) = \(contact.mood) (\(contact.moodText))")
        }
        
        // Verify the method returns new instances (not modifies in place)
        let aliceOriginal = originalContacts.first { $0.name == "Alice" }
        let aliceUpdated = updatedContacts.first { $0.name == "Alice" }
        
        if let orig = aliceOriginal, let updated = aliceUpdated {
            let changeDetected = orig.mood != updated.mood || orig.moodText != updated.moodText
            print(changeDetected ? "Change detection should work!" : "No changes detected!")
        }
    }
    
    // MARK: - Test 5: User Emotion API Response
    static func testUserEmotionAPIResponse() {
        print("\n🤗 Test 5: User Emotion API Response")
        print("-" * 30)
        
        // Test that emoji ID 33 maps to hug-face emoji as expected from API
        let emojiId33 = 33
        let expectedEmoji = "🤗"
        let expectedName = "hug-face"
        
        let actualEmoji = ContactProfileHelpers.emojiForID(emojiId33)
        let actualName = ContactProfileHelpers.emojiNameForID(emojiId33)
        
        print("Testing User Emotion API Response Mapping:")
        print("Emoji ID 33 -> Emoji: \(actualEmoji) (expected: \(expectedEmoji))")
        print("Emoji ID 33 -> Name: \(actualName) (expected: \(expectedName))")
        
        // Simple assertion logic instead of XCTAssertEqual
        if actualEmoji == expectedEmoji {
            print("Emoji ID 33 correctly maps to hug-face emoji 🤗")
        } else {
            print("Emoji ID 33 mapping failed: expected \(expectedEmoji), got \(actualEmoji)")
        }
        
        if actualName == expectedName {
            print("Emoji ID 33 correctly maps to 'hug-face' name")
        } else {
            print("Emoji name ID 33 mapping failed: expected \(expectedName), got \(actualName)")
        }
        
        // Test some other key emoji mappings
        let testCases: [(Int, String, String)] = [
            (46, "😐", "neutral-face"),
            (34, "😄", "joy"),
            (29, "😍", "heart-eyes"),
            (49, "😔", "pensive"),
            (70, "😊", "smile")
        ]
        
        print("\nTesting additional emoji mappings:")
        for (id, expectedEmoji, expectedName) in testCases {
            let emoji = ContactProfileHelpers.emojiForID(id)
            let name = ContactProfileHelpers.emojiNameForID(id)
            
            let emojiMatch = emoji == expectedEmoji
            let nameMatch = name == expectedName
            
            let status = (emojiMatch && nameMatch) ? "✅" : "❌"
            print("\(status) ID \(id) -> \(emoji) (\(name))")
            
            if !emojiMatch {
                print("   Emoji mismatch: expected \(expectedEmoji), got \(emoji)")
            }
            if !nameMatch {
                print("   Name mismatch: expected \(expectedName), got \(name)")
            }
        }
        
        print("User emotion API response mapping test completed")
    }
}

// String extension for repeat
extension String {
    static func * (string: String, count: Int) -> String {
        return String(repeating: string, count: count)
    }
} 