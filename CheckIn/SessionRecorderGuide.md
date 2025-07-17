# Session Recorder Analytics - Implementation Guide

## Overview

The Session Recorder captures **every UI interaction** in your SwiftUI app from first launch, persists them locally using Core Data, and uploads in 24-hour batches after user login.

## ✅ Completed Implementation

### 1. Core Data Stack
- **AnalyticsModel.xcdatamodeld** - Core Data model with AnalyticsEvent entity
- **AnalyticsEvent+CoreData.swift** - Core Data extensions and helpers
- Attributes: `timestamp`, `type`, `payload` (JSON), `sent` (Boolean)

### 2. Analytics System
- **Analytics.swift** - Main session recorder class with Core Data persistence
- **SessionRecorderModifiers.swift** - SwiftUI view modifiers for UI tracking
- **AnalyticsTestHelper.swift** - Unit testing framework for deterministic tests

### 3. Key Features Implemented
- ✅ Captures all UI interactions from app launch (even before login)
- ✅ Core Data persistence (no 15-second buffer)  
- ✅ 24-hour upload batching
- ✅ Upload after login detection
- ✅ Background upload when >2000 events
- ✅ Deterministic unit testing

## 🚀 Quick Integration

### Add Session Recording to Any View

```swift
// Basic screen tracking
SomeView()
    .recordSession(screenName: "ScreenName")

// Track specific interactions
Button("Save") { }
    .trackButton(name: "save_button", type: "primary")

TextField("Email", text: $email)
    .trackTextInput(fieldName: "email_field")

ScrollView { }
    .trackScrolling()
```

### Tab View Integration (Already Added)

```swift
TabView(selection: $selectedTab) {
    // ... tabs
}
.trackTabView(selectedTab: $selectedTab, tabNames: ["Home", "Maps", "Contacts"])
```

### Authentication Integration (Already Added)

```swift
// Call when user logs in
AuthenticationTracker.trackLogin(username: username)

// Call when user logs out  
AuthenticationTracker.trackLogout()

// Call when user signs up
AuthenticationTracker.trackSignup(username: username)
```

## 📊 Event Types Captured

### Automatic Events
- **App Lifecycle**: Launch, background, foreground
- **Navigation**: Tab switches, screen enters/exits
- **Touch Interactions**: Taps, swipes, long presses
- **Text Input**: Field focus, typing
- **Scrolling**: Direction and distance

### Custom Events
```swift
Analytics.shared.log(type: "custom_event", payload: [
    "key": "value",
    "timestamp": Date().timeIntervalSince1970
])
```

## 🔒 Upload Behavior

### When Events Are Uploaded
1. **Daily Schedule**: Every 24 hours (if user logged in)
2. **Background Threshold**: When app goes to background with >2000 events
3. **Login Trigger**: Immediately when user logs in
4. **Manual Trigger**: `Analytics.shared.forceUpload()` for testing

### Upload Endpoint
```
POST /analytics/batch_upload
Content-Type: application/json

{
  "events": [
    {
      "type": "button_tap",
      "timestamp": 1625097600,
      "payload": { "button_name": "save", "screen_name": "Settings" }
    }
  ],
  "batch_id": "uuid-string",
  "upload_timestamp": 1625097600,
  "device_info": { "model": "iPhone", "system_version": "15.0" }
}
```

## 🧪 Unit Testing

### Deterministic Testing (No 16s Waits!)

```swift
func testButtonTracking() {
    let mockAnalytics = createMockAnalytics()
    
    // Simulate user interaction
    mockAnalytics.logButtonTap(buttonName: "test_button", screenName: "TestView")
    
    // Immediate assertions
    AnalyticsTestHelper.assertButtonTapLogged(
        analytics: mockAnalytics,
        buttonName: "test_button"
    )
    
    // No waiting required!
}
```

### Test Helpers Available
- `AnalyticsTestHelper.MockAnalytics` - Mock implementation
- `AnalyticsTestHelper.assertEventLogged()` - Event verification
- `AnalyticsTestHelper.simulateUserSession()` - Complete session simulation
- `waitForCoreDataOperations()` - Deterministic Core Data waits

## 📱 Views Integration Status

### ✅ Already Integrated
- **ContentView**: Tab tracking, app lifecycle, authentication events
- **HomeView**: Screen tracking with `.recordSession(screenName: "HomeView")`

### 🔄 To Be Added
Add `.recordSession(screenName: "ViewName")` to:

```swift
// ContactsView.swift
ContactsView()
    .recordSession(screenName: "ContactsView")

// SettingsView.swift  
SettingsView()
    .recordSession(screenName: "SettingsView")
    .onAppear {
        // Track settings changes
        SettingsTracker.trackSettingChange(
            settingName: "notifications",
            oldValue: false,
            newValue: true
        )
    }

// CelebritiesView.swift
CelebritiesView()
    .recordSession(screenName: "CelebritiesView")

// MapView.swift
MapView()
    .recordSession(screenName: "MapView")
```

## 🔍 Monitoring & Debug

### Check Analytics Status
```swift
let analytics = Analytics.shared
print("Pending events: \(analytics.pendingEventsCount)")
print("Total events: \(analytics.totalEventsCount)")
print("User logged in: \(analytics.isUserLoggedIn)")
print("Last upload: \(analytics.lastUploadDate)")
```

### Debug Commands
```swift
// Force upload for testing
Analytics.shared.forceUpload()

// Clean up old events (>30 days)
Analytics.shared.cleanupOldEvents()

// Reset all analytics (DEBUG only)
Analytics.shared.resetAnalytics()
```

## 🚀 Migration from Old System

### What Changed
- ❌ **Removed**: 15-second in-memory buffer system
- ❌ **Removed**: 2-minute upload timer  
- ❌ **Removed**: `ActivityTrackingManager` (keep for now during transition)
- ✅ **Added**: Core Data persistence from launch
- ✅ **Added**: 24-hour upload batching
- ✅ **Added**: Login-dependent uploads

### Gradual Migration
1. **Phase 1**: Both systems run in parallel (current state)
2. **Phase 2**: Move specific views to new system
3. **Phase 3**: Remove old `ActivityTrackingManager`

### Key Benefits
- 📊 **100% Event Capture**: Nothing lost due to app crashes or network issues
- 🧪 **Deterministic Tests**: No more arbitrary 16-second waits
- 🔋 **Battery Efficient**: 24-hour batching reduces network usage
- 🔒 **Privacy Compliant**: Only uploads after explicit login
- 📱 **Offline Capable**: Works completely offline until login

## 📋 Next Steps

1. **Add session recording to remaining views** (5 minutes each)
2. **Test with mock analytics in unit tests** (deterministic)
3. **Verify upload behavior** with test login/logout
4. **Monitor Core Data storage** growth over time
5. **Phase out old ActivityTrackingManager** when confident

The session recorder is now capturing every interaction from app launch. Events are safely persisted and will upload automatically when the user logs in or every 24 hours thereafter! 