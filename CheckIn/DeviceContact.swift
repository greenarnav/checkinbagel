import Foundation

// MARK: - DeviceContact (Address-book contact we import into the app)
struct DeviceContact: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var initials: String
    var phoneNumber: String
}

// MARK: - GroupedContact (For handling same person with multiple numbers)
struct GroupedContact: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var initials: String
    var phoneNumbers: [String]
    var isEditingName: Bool = false
    
    init(name: String, phoneNumbers: [String]) {
        self.name = name
        self.phoneNumbers = phoneNumbers
        
        // Create initials safely
        let names = name.components(separatedBy: " ").filter { !$0.isEmpty }
        let initials = names.compactMap { $0.first }.map { String($0) }.joined()
        self.initials = String(initials.prefix(2)).uppercased()
    }
    
    // Create from DeviceContact
    init(from contact: DeviceContact) {
        self.name = contact.name
        self.initials = contact.initials
        self.phoneNumbers = [contact.phoneNumber]
    }
    
    // Primary phone number (first one)
    var primaryPhoneNumber: String {
        return phoneNumbers.first ?? ""
    }
    
    // Additional phone numbers (all except first)
    var additionalPhoneNumbers: [String] {
        return Array(phoneNumbers.dropFirst())
    }
    
    // Check if contact has multiple numbers
    var hasMultipleNumbers: Bool {
        return phoneNumbers.count > 1
    }
} 