//
//  File.swift
//  CheckIn
//
//  Created by Masroor Elahi on 23/06/2025.
//

import SwiftUI
import FirebaseAnalytics

struct ScreenTrackingModifier: ViewModifier {
    let screenName: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                FirebaseAnalytics.Analytics.logEvent(AnalyticsEventScreenView,
                                   parameters: [
                                       AnalyticsParameterScreenName: screenName,
                                       AnalyticsParameterScreenClass: screenName
                                   ])
            }
    }
}

struct CustomAnalyticsModifier: ViewModifier {
    let eventName: String
    let parameters: [String: Any]?

    func body(content: Content) -> some View {
        content
            .onAppear {
                logCustomEvent(name: eventName, parameters: parameters)
            }
    }
    
    func logCustomEvent(name: String, parameters: [String: Any]? = nil) {
        FirebaseAnalytics.Analytics.logEvent(name, parameters: parameters)
    }
}

extension View {
    func logAnalyticsEvent(_ name: String, parameters: [String: Any]? = nil) -> some View {
        self.modifier(CustomAnalyticsModifier(eventName: name, parameters: parameters))
    }
}


fileprivate extension View {
    func trackScreen(_ name: String) -> some View {
        self.modifier(ScreenTrackingModifier(screenName: name))
    }
}

extension View {
    func trackScreenAuto<T>(_ type: T.Type) -> some View {
        self.trackScreen(String(describing: type))
    }
}
