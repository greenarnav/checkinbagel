import Foundation

// MARK: - Follower Model
struct Follower: Identifiable {
    let id: UUID
    let name: String
    let phoneNumber: String
    let profileImageUrl: String?
    let isFollowingBack: Bool
    let followedSince: Date
    
    init(name: String, phoneNumber: String, profileImageUrl: String? = nil, isFollowingBack: Bool = false, followedSince: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.phoneNumber = phoneNumber
        self.profileImageUrl = profileImageUrl
        self.isFollowingBack = isFollowingBack
        self.followedSince = followedSince
    }
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first.map(String.init) ?? ""
        let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
        return firstInitial + lastInitial
    }
} 