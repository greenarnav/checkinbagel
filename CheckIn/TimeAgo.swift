import Foundation

// MARK: - Time Formatting Utilities
struct TimeAgo {
    static func text(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
    
    static func followerText(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 86400 {
            return "today"
        } else if interval < 86400 * 7 {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        } else if interval < 86400 * 30 {
            let weeks = Int(interval / (86400 * 7))
            return "\(weeks)w ago"
        } else {
            let months = Int(interval / (86400 * 30))
            return "\(months)mo ago"
        }
    }
} 