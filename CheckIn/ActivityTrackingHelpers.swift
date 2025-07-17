//
//  ActivityTrackingHelpers.swift
//  moodgpt
//
//  Created by Test on 6/1/25.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Activity Tracking View Modifiers

struct TouchTrackingViewModifier: ViewModifier {
    let activityTracker: ActivityTrackingManager
    let currentTab: String
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onEnded { value in
                        // Track tap/touch events with coordinates
                        activityTracker.trackTouchEvent(
                            at: value.location,
                            action: "touch_interaction",
                            elementType: currentTab
                        )
                    }
            )
    }
}

// MARK: - Universal Tap Tracking Extension

struct UniversalTapTracker: ViewModifier {
    let activityTracker: ActivityTrackingManager
    
    func body(content: Content) -> some View {
        content
            .background(
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .global)
                            .onChanged { value in
                                // Track drag start (touch down)
                                if value.translation == .zero {
                                    activityTracker.trackTouchEvent(
                                        at: value.startLocation,
                                        action: "touch_down",
                                        elementType: "background"
                                    )
                                }
                            }
                            .onEnded { value in
                                let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                                
                                if distance < 10 {
                                    // This was a tap
                                    activityTracker.trackTouchEvent(
                                        at: value.location,
                                        action: "tap",
                                        elementType: "background"
                                    )
                                } else {
                                    // This was a swipe/drag
                                    let direction = getSwipeDirection(value.translation)
                                    activityTracker.trackSwipeGesture(
                                        direction: direction,
                                        startPoint: value.startLocation,
                                        endPoint: value.location,
                                        velocity: Double(distance)
                                    )
                                }
                            }
                    )
            )
    }
    
    private func getSwipeDirection(_ translation: CGSize) -> String {
        if abs(translation.width) > abs(translation.height) {
            return translation.width > 0 ? "right" : "left"
        } else {
            return translation.height > 0 ? "down" : "up"
        }
    }
}

// MARK: - Button Tracking Extension

struct ActivityButtonTrackingModifier: ViewModifier {
    let activityTracker: ActivityTrackingManager
    let buttonName: String
    let buttonType: String
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onEnded { value in
                        activityTracker.trackButtonClick(
                            buttonName,
                            buttonType: buttonType,
                            coordinates: value.location
                        )
                    }
            )
    }
}

// MARK: - Text Field Tracking Extension

struct TextFieldTrackingModifier: ViewModifier {
    let activityTracker: ActivityTrackingManager
    let fieldName: String
    @State private var isFirstResponder = false
    
    func body(content: Content) -> some View {
        content
            .onTapGesture(coordinateSpace: .global) { location in
                if !isFirstResponder {
                    isFirstResponder = true
                    activityTracker.trackTextInput(
                        fieldName: fieldName,
                        fieldType: "textfield",
                        coordinates: location
                    )
                }
            }
            .onChange(of: isFirstResponder) { _, newValue in
                if !newValue {
                    activityTracker.logBehavior(
                        action: "textfield_blur",
                        additionalData: [
                            "field_name": fieldName,
                            "field_type": "textfield"
                        ]
                    )
                }
            }
    }
}

// MARK: - Scroll Tracking Extension

struct ScrollTrackingModifier: ViewModifier {
    let activityTracker: ActivityTrackingManager
    @State private var lastScrollOffset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                lastScrollOffset = 0
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            let currentOffset = geometry.frame(in: .global).minY
                            let offset = currentOffset - lastScrollOffset
                            
                            if abs(offset) > 10 {
                                activityTracker.trackScrollBehavior(
                                    direction: offset > 0 ? "up" : "down", 
                                    distance: abs(Double(offset)),
                                    startPoint: CGPoint(x: geometry.frame(in: .global).midX, y: geometry.frame(in: .global).midY)
                                )
                                lastScrollOffset = currentOffset
                            }
                        }
                }
            )
    }
}

// MARK: - Long Press Tracking Extension

struct LongPressTrackingViewModifier: ViewModifier {
    let activityTracker: ActivityTrackingManager
    let currentTab: String
    
    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: 0.5) {
                // Track long press without location since onLongPressGesture doesn't provide it
                activityTracker.logBehavior(
                    action: "long_press",
                    additionalData: [
                        "tab": currentTab,
                        "timestamp": Date().timeIntervalSince1970,
                        "press_duration": 0.5
                    ]
                )
            }
    }
}

// MARK: - Sentiment Reaction Tracking

struct SentimentReactionTracker {
    let activityTracker: ActivityTrackingManager
    
    func trackSentimentReaction(emotion: String, intensity: Double, context: String, coordinates: CGPoint? = nil) {
        let details: [String: Any] = [
            "emotion": emotion,
            "intensity": intensity,
            "context": context,
            "reaction_type": "sentiment"
        ]
        
        activityTracker.logBehavior(
            action: "sentiment_reaction_detailed",
            coordinates: coordinates,
            additionalData: details
        )
    }
}

// MARK: - Text Input Tracking Helpers

struct ActivityTextInputTracker {
    static func trackTextFieldStart(activityTracker: ActivityTrackingManager, fieldName: String, textField: UITextField) {
        activityTracker.trackTextInput(
            fieldName: fieldName,
            fieldType: "textfield"
        )
    }
    
    static func trackTextFieldEdit(activityTracker: ActivityTrackingManager, fieldName: String, textField: UITextField) {
        activityTracker.trackTextInput(
            fieldName: fieldName,
            fieldType: "textfield",
            textLength: textField.text?.count
        )
    }
    
    static func trackTextFieldSubmit(activityTracker: ActivityTrackingManager, fieldName: String, textField: UITextField) {
        activityTracker.logBehavior(
            action: "textfield_submit",
            additionalData: [
                "field_name": fieldName,
                "text_length": textField.text?.count ?? 0,
                "field_type": "textfield"
            ]
        )
    }
}

// MARK: - View Extensions

extension View {
    func withBehaviorTracking(_ activityTracker: ActivityTrackingManager, currentTab: String) -> some View {
        self.modifier(TouchTrackingViewModifier(activityTracker: activityTracker, currentTab: currentTab))
    }
    
    func withUniversalTapTracking(_ activityTracker: ActivityTrackingManager) -> some View {
        self.modifier(UniversalTapTracker(activityTracker: activityTracker))
    }
    
    func withActivityButtonTracking(_ activityTracker: ActivityTrackingManager, buttonName: String, buttonType: String) -> some View {
        self.modifier(ActivityButtonTrackingModifier(activityTracker: activityTracker, buttonName: buttonName, buttonType: buttonType))
    }
    
    func withTextFieldTracking(_ activityTracker: ActivityTrackingManager, fieldName: String) -> some View {
        self.modifier(TextFieldTrackingModifier(activityTracker: activityTracker, fieldName: fieldName))
    }
    
    func withScrollTracking(_ activityTracker: ActivityTrackingManager) -> some View {
        self.modifier(ScrollTrackingModifier(activityTracker: activityTracker))
    }
    
    func withLongPressTracking(
        activityTracker: ActivityTrackingManager,
        currentTab: String
    ) -> some View {
        self.modifier(LongPressTrackingViewModifier(
            activityTracker: activityTracker,
            currentTab: currentTab
        ))
    }
}

// MARK: - Analytics Data Processing

extension ActivityTrackingManager {
    func getActivitySummary() -> [String: Any] {
        return [
            "total_activities": activitiesLogged,
            "tracking_status": trackingStatus,
            "is_tracking": isTracking,
            "user_email": currentUserEmail
        ]
    }
    
    func exportActivityData() -> String {
        let summary = getActivitySummary()
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: summary, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? "Failed to encode data"
        } catch {
            return "Error generating export: \(error.localizedDescription)"
        }
    }
}

// MARK: - Screen Time Tracking

struct ScreenTimeTracker: ViewModifier {
    let activityTracker: ActivityTrackingManager
    let screenName: String
    @State private var startTime: Date?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                startTime = Date()
                activityTracker.logBehavior(
                    action: "screen_enter",
                    additionalData: [
                        "screen": screenName,
                        "timestamp": Date().timeIntervalSince1970
                    ]
                )
            }
            .onDisappear {
                if let start = startTime {
                    let duration = Date().timeIntervalSince(start)
                    activityTracker.logBehavior(
                        action: "screen_exit",
                        additionalData: [
                            "screen": screenName,
                            "duration": duration,
                            "timestamp": Date().timeIntervalSince1970
                        ]
                    )
                }
            }
    }
}

extension View {
    func trackScreenTime(
        with activityTracker: ActivityTrackingManager,
        screenName: String
    ) -> some View {
        self.modifier(ScreenTimeTracker(
            activityTracker: activityTracker,
            screenName: screenName
        ))
    }
} 
