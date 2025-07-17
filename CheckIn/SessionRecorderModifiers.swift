//
//  SessionRecorderModifiers.swift
//  CheckIn
//
//  Created by Session Recorder on 2025-07-05.
//

import SwiftUI
import UIKit

// MARK: - Universal Session Recording Modifiers

/// Captures all UI interactions automatically
struct SessionRecorderModifier: ViewModifier {
    let screenName: String
    let analytics = Analytics.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                analytics.logScreenEnter(screenName: screenName)
            }
            .onDisappear {
                analytics.logScreenExit(screenName)
            }
            .simultaneousGesture(
                // Capture all gestures without interfering - exclude tab bar area
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        // Only track touches that are not in the tab bar area
                        let screenHeight = UIScreen.main.bounds.height
                        let tabBarHeight: CGFloat = 83 // Standard tab bar height with safe area
                        let tabBarArea = screenHeight - tabBarHeight
                        
                        // Skip tracking touches in the tab bar area
                        guard value.startLocation.y < tabBarArea else { return }
                        
                        // Track initial touch (drag start)
                        if value.translation == .zero {
                            analytics.log(type: "touch_down", payload: [
                                "coordinates": [
                                    "x": value.startLocation.x,
                                    "y": value.startLocation.y
                                ],
                                "screen_name": screenName,
                                "timestamp": Date().timeIntervalSince1970
                            ])
                        }
                    }
                    .onEnded { value in
                        // Only track touches that are not in the tab bar area
                        let screenHeight = UIScreen.main.bounds.height
                        let tabBarHeight: CGFloat = 83
                        let tabBarArea = screenHeight - tabBarHeight
                        
                        // Skip tracking touches in the tab bar area
                        guard value.startLocation.y < tabBarArea else { return }
                        
                        // Track touch end
                        analytics.log(type: "touch_up", payload: [
                            "coordinates": [
                                "x": value.location.x,
                                "y": value.location.y
                            ],
                            "screen_name": screenName,
                            "timestamp": Date().timeIntervalSince1970
                        ])
                    }
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

// MARK: - Screen Tracking

struct ScreenTracker: ViewModifier {
    let screenName: String
    let analytics = Analytics.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                analytics.logScreenEnter(screenName: screenName)
            }
            .onDisappear {
                analytics.logScreenExit(screenName)
            }
    }
}

// MARK: - Button Tracking

struct ButtonTrackingModifier: ViewModifier {
    let buttonName: String
    let buttonType: String
    let analytics = Analytics.shared
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onEnded { value in
                        analytics.logButtonTap(
                            buttonName: buttonName,
                            coordinates: value.location
                        )
                    }
            )
    }
}

// MARK: - Tab Switch Tracking

struct TabSwitchTracker: ViewModifier {
    let tabName: String
    let tabIndex: Int
    @State private var previousTab: String = ""
    let analytics = Analytics.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !previousTab.isEmpty {
                    analytics.logTabSwitch(from: previousTab, to: tabName, tabIndex: tabIndex)
                }
                previousTab = tabName
            }
    }
}

// MARK: - Text Input Tracking

struct TextInputTracker: ViewModifier {
    let fieldName: String
    let fieldType: String
    @State private var textLength: Int = 0
    let analytics = Analytics.shared
    
    func body(content: Content) -> some View {
        content
            .onTapGesture(coordinateSpace: .global) { location in
                analytics.log(type: "text_field_focus", payload: [
                    "field_name": fieldName,
                    "field_type": fieldType,
                    "coordinates": [
                        "x": location.x,
                        "y": location.y
                    ],
                    "timestamp": Date().timeIntervalSince1970
                ])
            }
    }
}

// MARK: - Long Press Tracking

struct LongPressTracker: ViewModifier {
    let elementName: String?
    let analytics = Analytics.shared
    
    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: 0.5) {
                analytics.logLongPress(elementName: elementName)
            }
    }
}

// MARK: - Scroll Tracking

struct ScrollTracker: ViewModifier {
    @State private var lastScrollOffset: CGFloat = 0
    let analytics = Analytics.shared
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            lastScrollOffset = geometry.frame(in: .global).minY
                        }
                        .onChange(of: geometry.frame(in: .global).minY) { _, newOffset in
                            let offset = newOffset - lastScrollOffset
                            
                            if abs(offset) > 20 { // Only track significant scrolls
                                analytics.log(type: "scroll", payload: [
                                    "direction": offset > 0 ? "up" : "down",
                                    "distance": abs(Double(offset)),
                                    "coordinates": [
                                        "x": geometry.frame(in: .global).midX,
                                        "y": geometry.frame(in: .global).midY
                                    ],
                                    "timestamp": Date().timeIntervalSince1970
                                ])
                                lastScrollOffset = newOffset
                            }
                        }
                }
            )
    }
}

// MARK: - View Extensions for Easy Usage

extension View {
    /// Apply session recording to any view
    func recordSession(screenName: String) -> some View {
        self.modifier(SessionRecorderModifier(screenName: screenName))
    }
    
    /// Track button interactions
    func trackButton(name: String, type: String = "button") -> some View {
        self.modifier(ButtonTrackingModifier(buttonName: name, buttonType: type))
    }
    
    /// Track tab switches
    func trackTab(name: String, index: Int) -> some View {
        self.modifier(TabSwitchTracker(tabName: name, tabIndex: index))
    }
    
    /// Track text input fields
    func trackTextInput(fieldName: String, fieldType: String = "textfield") -> some View {
        self.modifier(TextInputTracker(fieldName: fieldName, fieldType: fieldType))
    }
    
    /// Track long press gestures
    func trackLongPress(elementName: String? = nil) -> some View {
        self.modifier(LongPressTracker(elementName: elementName))
    }
    
    /// Track scroll interactions
    func trackScrolling() -> some View {
        self.modifier(ScrollTracker())
    }
}

// MARK: - Content View Tab Tracking Helper

struct TabViewTracker: ViewModifier {
    @Binding var selectedTab: Int
    let tabNames: [String]
    @State private var previousTab: Int = 0
    let analytics = Analytics.shared
    
    func body(content: Content) -> some View {
        content
            .onChange(of: selectedTab) { _, newTab in
                if newTab != previousTab && newTab < tabNames.count && previousTab < tabNames.count {
                    analytics.logTabSwitch(
                        from: tabNames[previousTab],
                        to: tabNames[newTab],
                        tabIndex: newTab
                    )
                }
                previousTab = newTab
            }
            .onAppear {
                if selectedTab < tabNames.count {
                    analytics.logTabSwitch(
                        from: "",
                        to: tabNames[selectedTab],
                        tabIndex: selectedTab
                    )
                    previousTab = selectedTab
                }
            }
    }
}

extension View {
    /// Track tab view changes
    func trackTabView(selectedTab: Binding<Int>, tabNames: [String]) -> some View {
        self.modifier(TabViewTracker(selectedTab: selectedTab, tabNames: tabNames))
    }
}

// MARK: - Authentication Tracking

struct AuthenticationTracker {
    static let analytics = Analytics.shared
    
    static func trackLogin(username: String, method: String = "standard") {
        analytics.logUserLogin(username: username, loginMethod: method)
        
        // Post notification for login state change
        NotificationCenter.default.post(
            name: .init("UserLoginStateChanged"),
            object: true
        )
    }
    
    static func trackLogout() {
        analytics.logUserLogout()
        
        // Post notification for login state change  
        NotificationCenter.default.post(
            name: .init("UserLoginStateChanged"),
            object: false
        )
    }
    
    static func trackSignup(username: String, method: String = "standard") {
        analytics.log(type: "user_signup", payload: [
            "username": username,
            "signup_method": method,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
}

// MARK: - Settings and Preferences Tracking

struct SettingsTracker {
    static let analytics = Analytics.shared
    
    static func trackSettingChange(settingName: String, oldValue: Any?, newValue: Any) {
        analytics.log(type: "setting_change", payload: [
            "setting_name": settingName,
            "old_value": String(describing: oldValue),
            "new_value": String(describing: newValue),
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    static func trackThemeChange(oldTheme: String, newTheme: String) {
        analytics.log(type: "theme_change", payload: [
            "old_theme": oldTheme,
            "new_theme": newTheme,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
} 