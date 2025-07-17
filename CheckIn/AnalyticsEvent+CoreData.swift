//
//  AnalyticsEvent+CoreData.swift
//  CheckIn
//
//  Created by Analytics System on 2025-07-05.
//

import Foundation
import CoreData
import UIKit

// MARK: - Core Data Extensions for AnalyticsEvent

extension AnalyticsEvent {
    
    /// Fetch all unsent events ordered by timestamp
    static func fetchUnsent(in context: NSManagedObjectContext) -> [AnalyticsEvent] {
        let request: NSFetchRequest<AnalyticsEvent> = AnalyticsEvent.fetchRequest()
        request.predicate = NSPredicate(format: "sent == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AnalyticsEvent.timestamp, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch unsent analytics events: \(error)")
            return []
        }
    }
    
    /// Fetch events count for specific criteria
    static func count(sent: Bool? = nil, in context: NSManagedObjectContext) -> Int {
        let request: NSFetchRequest<AnalyticsEvent> = AnalyticsEvent.fetchRequest()
        
        if let sent = sent {
            request.predicate = NSPredicate(format: "sent == %@", NSNumber(value: sent))
        }
        
        do {
            return try context.count(for: request)
        } catch {
            print("Failed to count analytics events: \(error)")
            return 0
        }
    }
    
    /// Mark events as sent
    static func markAsSent(_ events: [AnalyticsEvent], in context: NSManagedObjectContext) {
        events.forEach { $0.sent = true }
        
        do {
            try context.save()
        } catch {
            print("Failed to mark events as sent: \(error)")
        }
    }
    
    /// Delete old sent events (cleanup)
    static func deleteOldSentEvents(olderThan days: Int, in context: NSManagedObjectContext) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let request: NSFetchRequest<NSFetchRequestResult> = AnalyticsEvent.fetchRequest()
        request.predicate = NSPredicate(format: "sent == YES AND timestamp < %@", cutoffDate as NSDate)
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("Deleted old sent analytics events older than \(days) days")
        } catch {
            print("Failed to delete old analytics events: \(error)")
        }
    }
    
    /// Create a new analytics event
    static func create(
        type: String,
        payload: [String: Any],
        in context: NSManagedObjectContext
    ) -> AnalyticsEvent {
        let event = AnalyticsEvent(context: context)
        event.timestamp = Date()
        event.type = type
        event.sent = false
        
        // Encode payload as JSON Data
        do {
            event.payload = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Failed to encode analytics payload: \(error)")
            event.payload = nil
        }
        
        return event
    }
    
    /// Decode payload from Data to Dictionary
    var decodedPayload: [String: Any]? {
        guard let payload = payload else { return nil }
        
        do {
            return try JSONSerialization.jsonObject(with: payload, options: []) as? [String: Any]
        } catch {
            print("Failed to decode analytics payload: \(error)")
            return nil
        }
    }
}

// MARK: - Analytics Event Types

struct AnalyticsEventType {
    static let tabSwitch = "tab_switch"
    static let buttonTap = "button_tap"
    static let swipeGesture = "swipe_gesture"
    static let longPress = "long_press"
    static let textInput = "text_input"
    static let screenView = "screen_view"
    static let appLaunch = "app_launch"
    static let appBackground = "app_background"
    static let appForeground = "app_foreground"
    static let userLogin = "user_login"
    static let userLogout = "user_logout"
}

// MARK: - Event Payload Builders

struct EventPayloadBuilder {
    
    static func tabSwitch(from fromTab: String, to toTab: String, tabIndex: Int) -> [String: Any] {
        return [
            "from_tab": fromTab,
            "to_tab": toTab,
            "tab_index": tabIndex,
            "timestamp": Date().timeIntervalSince1970
        ]
    }
    
    static func buttonTap(buttonName: String, screenName: String, coordinates: CGPoint? = nil) -> [String: Any] {
        var payload: [String: Any] = [
            "button_name": buttonName,
            "screen_name": screenName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let coordinates = coordinates {
            payload["coordinates"] = [
                "x": coordinates.x,
                "y": coordinates.y
            ]
        }
        
        return payload
    }
    
    static func swipeGesture(direction: String, startPoint: CGPoint, endPoint: CGPoint, screenName: String) -> [String: Any] {
        return [
            "direction": direction,
            "start_point": [
                "x": startPoint.x,
                "y": startPoint.y
            ],
            "end_point": [
                "x": endPoint.x,
                "y": endPoint.y
            ],
            "screen_name": screenName,
            "timestamp": Date().timeIntervalSince1970
        ]
    }
    
    static func screenView(screenName: String, duration: TimeInterval? = nil) -> [String: Any] {
        var payload: [String: Any] = [
            "screen_name": screenName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let duration = duration {
            payload["duration"] = duration
        }
        
        return payload
    }
    
    static func appLifecycle(state: String, previousState: String? = nil) -> [String: Any] {
        var payload: [String: Any] = [
            "state": state,
            "timestamp": Date().timeIntervalSince1970,
            "device_model": UIDevice.current.model,
            "system_version": UIDevice.current.systemVersion
        ]
        
        if let previousState = previousState {
            payload["previous_state"] = previousState
        }
        
        return payload
    }
} 