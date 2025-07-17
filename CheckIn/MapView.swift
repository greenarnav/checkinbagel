//
//  MapView.swift
//  moodgpt
//
//  Created by Test on 5/27/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showUserLocation = true
    @State private var moodLocations: [MoodLocation] = []
    @State private var lastGeneratedLocation: CLLocationCoordinate2D?
    @State private var selectedLocation: MoodLocation?
    @State private var hasGeneratedInitialLocations = false
    @State private var showSaveLocationPopup = false
    @State private var currentMapCenter: CLLocationCoordinate2D = CLLocationCoordinate2D()
    @State private var savedPlaces: [SavedPlace] = []
    @EnvironmentObject var pinnedContactsManager: PinnedContactsManager
    @EnvironmentObject var themeManager: ThemeManager
    
    // Saved place model
    struct SavedPlace: Identifiable {
        let id = UUID()
        let name: String
        let category: String
        let coordinate: CLLocationCoordinate2D
        let dateAdded: Date
        let icon: String
        let color: Color
    }
    
    // Combined annotation model for map
    struct MapAnnotationItem: Identifiable {
        let id: String
        let coordinate: CLLocationCoordinate2D
        let isSavedPlace: Bool
    }
    
    // Computed property to combine mood locations and saved places
    var mapAnnotations: [MapAnnotationItem] {
        var annotations: [MapAnnotationItem] = []
        
        // Add mood locations
        for location in moodLocations {
            annotations.append(MapAnnotationItem(
                id: location.id.uuidString,
                coordinate: location.coordinate,
                isSavedPlace: false
            ))
        }
        
        // Add saved places
        for place in savedPlaces {
            annotations.append(MapAnnotationItem(
                id: place.id.uuidString,
                coordinate: place.coordinate,
                isSavedPlace: true
            ))
        }
        
        return annotations
    }
    
    // Get current user mood from UserDefaults or default
    private var currentUserMood: String {
        UserDefaults.standard.string(forKey: "CurrentUserMood") ?? "😊"
    }
    
    private var currentUserMoodText: String {
        UserDefaults.standard.string(forKey: "CurrentUserMoodText") ?? "Happy"
    }
    
    var body: some View {
        ZStack {
            // Solid base background to prevent white lines
            Color.black
                .ignoresSafeArea()
            
            // Base background for multi-color theme
            if let gradient = themeManager.backgroundGradient {
                gradient
                    .ignoresSafeArea()
                    .opacity(0.2) // Even more subtle so map remains clearly visible
            }
            
            // Map with dynamic mood locations and saved places
            Map(coordinateRegion: $locationManager.region, 
                interactionModes: [.all], // Enable all interactions including pinch to zoom
                showsUserLocation: true,
                annotationItems: mapAnnotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    if annotation.isSavedPlace {
                        // Saved place annotation
                        if let place = savedPlaces.first(where: { $0.id.uuidString == annotation.id }) {
                            Button(action: {
                                // Could show saved place details
                            }) {
                                VStack(spacing: 2) {
                                    ZStack {
                                        Circle()
                                            .fill(place.color)
                                            .frame(width: 32, height: 32)
                                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                        
                                        Image(systemName: place.icon)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(place.name)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.9))
                                                .shadow(color: .black.opacity(0.1), radius: 2)
                                        )
                                }
                            }
                        }
                    } else {
                        // Mood location annotation
                        if let location = moodLocations.first(where: { $0.id.uuidString == annotation.id }) {
                            Button(action: {
                                selectedLocation = location
                            }) {
                                if location.isCurrentUser {
                                    // User's location with pulsing effect
                                    ZStack {
                                        // Pulsing background
                                        Circle()
                                            .fill(Color.blue.opacity(0.3))
                                            .frame(width: 60, height: 60)
                                            .scaleEffect(1.2)
                                            .opacity(0.5)
                                            .animation(
                                                Animation.easeInOut(duration: 1.5)
                                                    .repeatForever(autoreverses: true),
                                                value: location.isCurrentUser
                                            )
                                        
                                        // White background circle
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 46, height: 46)
                                            .shadow(radius: 3)
                                        
                                        // User's mood emoji
                                        AnimatedEmoji(location.mood, size: 36, fallback: location.mood)
                                        
                                        // "You" label
                                        VStack {
                                            Spacer()
                                            Text("You")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue)
                                                .cornerRadius(10)
                                                .offset(y: 30)
                                        }
                                    }
                                    .frame(width: 60, height: 60)
                                } else {
                                    // Other users' emojis
                                    AnimatedEmoji(location.mood, size: 30, fallback: location.mood)
                                }
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .onAppear {
                if !hasGeneratedInitialLocations {
                    generateMoodLocations()
                    hasGeneratedInitialLocations = true
                    loadSampleSavedPlaces()
                }
                // Request location permission
                locationManager.requestLocation()
            }
            .onReceive(locationManager.$location) { newLocation in
                if let location = newLocation {
                    generateMoodLocations(around: location)
                }
            }
            
            // Subtle top gradient overlay
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.3), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
                .ignoresSafeArea()
                
                Spacer()
            }
            
            // AssistiveTouch-style Save Button (top-right)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        currentMapCenter = locationManager.region.center
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showSaveLocationPopup = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.75))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .scaleEffect(showSaveLocationPopup ? 0.9 : 1.0)
                    .opacity(showSaveLocationPopup ? 0.7 : 1.0)
                    .animation(.spring(response: 0.3), value: showSaveLocationPopup)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
            }
            
            // Bottom controls
            VStack {
                Spacer()
                
                HStack(spacing: 20) {
                    // Refresh button
                    Button(action: {
                        withAnimation(.spring()) {
                            if let location = locationManager.location {
                                generateMoodLocations(around: location)
                            } else {
                                generateMoodLocations()
                            }
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                            .font(.title2)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.7)))
                            .shadow(radius: 5)
                    }
                    
                    Spacer()
                    
                    // Current location button
                    Button(action: {
                        withAnimation {
                            if let location = locationManager.location {
                                locationManager.region = MKCoordinateRegion(
                                    center: location,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                            } else {
                                locationManager.requestLocation()
                            }
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                            .padding()
                            .background(Circle().fill(Color.blue))
                            .shadow(radius: 5)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            
            // Selected location detail sheet
            if let selected = selectedLocation {
                VStack {
                    Spacer()
                    
                    MoodLocationDetailCard(location: selected) {
                        withAnimation {
                            selectedLocation = nil
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // Save Location Popup
            if showSaveLocationPopup {
                SaveLocationPopup(
                    coordinate: currentMapCenter,
                    isShowing: $showSaveLocationPopup
                ) { place in
                    savedPlaces.append(place)
                }
            }
        }
        .trackScreenAuto(MapView.self)
        .navigationDestination(for: MoodLocation.self) { location in
            MapLocationDetailView(
                location: location,
                locationName: locationName(for: location.coordinate)
            )
        }
    }
    
    private func generateMoodLocations(around center: CLLocationCoordinate2D? = nil) {
        let centerCoordinate = center ?? CLLocationCoordinate2D(latitude: 40.7614, longitude: -73.9776)
        
        // Don't regenerate if we're still near the last generated location
        if let lastLocation = lastGeneratedLocation {
            let distance = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
                .distance(from: CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude))
            
            if distance < 500 { // Less than 500 meters
                return
            }
        }
        
        lastGeneratedLocation = centerCoordinate
        
        // Generate diverse mood points around the center
        let moods = ["😊", "😢", "😡", "😮", "😐", "😄", "🤔", "😏", "😴", "🥳", "😌", "😤"]
        let moodTexts = ["Happy", "Sad", "Angry", "Surprised", "Neutral", "Joyful", "Thinking", "Cool", "Sleepy", "Party", "Calm", "Frustrated"]
        
        // Define some app users (these will get blue outline)
        let appUserIndices = [1, 3, 5, 7, 10, 13] // Random indices that will be app users
        
        var newLocations: [MoodLocation] = []
        
        // Generate 15-20 mood points in a realistic pattern
        let numberOfPoints = Int.random(in: 15...20)
        
        for i in 0..<numberOfPoints {
            // Create clusters and scattered points
            let angle = Double.random(in: 0...(2 * Double.pi))
            let distance = Double.random(in: 0.0003...0.008) // Roughly 30m to 800m
            
            // Create some clustering effect
            let clusterProbability = Double.random(in: 0...1)
            let finalDistance = clusterProbability > 0.7 ? distance * 0.3 : distance
            
            let lat = centerCoordinate.latitude + finalDistance * cos(angle)
            let lon = centerCoordinate.longitude + finalDistance * sin(angle)
            
            let moodIndex = Int.random(in: 0..<moods.count)
            let isAppUser = appUserIndices.contains(i)
            
            newLocations.append(MoodLocation(
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                mood: moods[moodIndex],
                moodText: moodTexts[moodIndex],
                isAppUser: isAppUser
            ))
        }
        
        // Add user's current mood at their location if available (always app user)
        if let userLocation = center {
            newLocations.append(MoodLocation(
                coordinate: userLocation,
                mood: currentUserMood,
                moodText: currentUserMoodText,
                isCurrentUser: true,
                isAppUser: true
            ))
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            moodLocations = newLocations
        }
    }
    
    private func locationName(for coordinate: CLLocationCoordinate2D) -> String {
        // Generate realistic location names based on coordinates
        let streets = ["Broadway", "5th Avenue", "Park Avenue", "Madison Avenue", "Lexington Avenue", "3rd Avenue", "2nd Avenue", "1st Avenue"]
        let crossStreets = ["42nd St", "57th St", "59th St", "72nd St", "86th St", "96th St", "110th St", "125th St"]
        let landmarks = ["Central Park", "Times Square", "Columbus Circle", "Lincoln Center", "Carnegie Hall", "Rockefeller Center", "Grand Central", "Bryant Park"]
        
        let randomChoice = Int.random(in: 0...2)
        
        switch randomChoice {
        case 0:
            return "\(streets.randomElement()!) & \(crossStreets.randomElement()!)"
        case 1:
            return "Near \(landmarks.randomElement()!)"
        default:
            return "Manhattan"
        }
    }
    
    private func loadSampleSavedPlaces() {
        // Add some sample saved places for demo
        savedPlaces = [
            SavedPlace(
                name: "Home",
                category: "Home",
                coordinate: CLLocationCoordinate2D(latitude: 40.7614, longitude: -73.9776),
                dateAdded: Date(),
                icon: "house.fill",
                color: .orange
            ),
            SavedPlace(
                name: "Work",
                category: "Work", 
                coordinate: CLLocationCoordinate2D(latitude: 40.7505, longitude: -73.9934),
                dateAdded: Date(),
                icon: "building.2.fill",
                color: .blue
            )
        ]
    }
}

// MARK: - Mood Location Detail Card
struct MoodLocationDetailCard: View {
    let location: MoodLocation
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
            
            // Content
            HStack(spacing: 20) {
                AnimatedEmoji(location.mood, size: 50, fallback: location.mood)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(location.isCurrentUser ? "Your Mood" : "\(location.moodText) Mood")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(location.isCurrentUser ? "Current Location" : locationDescription(for: location))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.caption)
                        Text("\(Int.random(in: 5...50)) people")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                NavigationLink(destination: MapLocationDetailView(
                    location: location,
                    locationName: locationDescription(for: location)
                )) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
        .padding(.horizontal)
        .padding(.bottom, 20)
        .onTapGesture {
            onDismiss()
        }
    }
    
    private func locationDescription(for location: MoodLocation) -> String {
        let areas = ["Upper West Side", "Midtown", "Upper East Side", "Chelsea", "Greenwich Village", "SoHo", "Tribeca", "Financial District"]
        return areas.randomElement() ?? "Manhattan"
    }
}

// MARK: - Save Location Popup
struct SaveLocationPopup: View {
    let coordinate: CLLocationCoordinate2D
    @Binding var isShowing: Bool
    let onSave: (MapView.SavedPlace) -> Void
    @State private var selectedCategory: LocationCategory?
    @State private var customName = ""
    @State private var showCustomInput = false
    
    enum LocationCategory: String, CaseIterable {
        case home = "Home"
        case work = "Work"
        case gym = "Gym"
        case restaurant = "Restaurant"
        case coffee = "Coffee Shop"
        case shopping = "Shopping"
        case hospital = "Hospital"
        case school = "School"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .work: return "building.2.fill"
            case .gym: return "dumbbell.fill"
            case .restaurant: return "fork.knife"
            case .coffee: return "cup.and.saucer.fill"
            case .shopping: return "bag.fill"
            case .hospital: return "cross.case.fill"
            case .school: return "graduationcap.fill"
            case .other: return "mappin.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .home: return .orange
            case .work: return .blue
            case .gym: return .red
            case .restaurant: return .green
            case .coffee: return .brown
            case .shopping: return .purple
            case .hospital: return .pink
            case .school: return .indigo
            case .other: return .gray
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPopup()
                }
            
            VStack {
                Spacer()
                
                // Popup content
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 40, height: 5)
                        
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Save this place as")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("Lat: \(coordinate.latitude, specifier: "%.4f"), Lng: \(coordinate.longitude, specifier: "%.4f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Category grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 16) {
                        ForEach(LocationCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectCategory(category)
                            }
                        }
                    }
                    
                    // Custom input (if "Other" is selected)
                    if showCustomInput {
                        VStack(spacing: 12) {
                            TextField("Enter custom location name", text: $customName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 16))
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        // Cancel button
                        Button(action: dismissPopup) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                )
                        }
                        
                        // Save button
                        Button(action: saveLocation) {
                            Text("Save Place")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            selectedCategory != nil ?
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.3, green: 0.6, blue: 1.0),
                                                    Color(red: 0.2, green: 0.4, blue: 0.9)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ) :
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.gray, Color.gray]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                        .disabled(selectedCategory == nil || (selectedCategory == .other && customName.isEmpty))
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: -10)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
    }
    
    private func selectCategory(_ category: LocationCategory) {
        withAnimation(.spring(response: 0.3)) {
            selectedCategory = category
            showCustomInput = (category == .other)
            if category != .other {
                customName = ""
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func saveLocation() {
        guard let category = selectedCategory else { return }
        
        let locationName = category == .other ? customName : category.rawValue
        
        // Create the saved place
        let savedPlace = MapView.SavedPlace(
            name: locationName,
            category: category.rawValue,
            coordinate: coordinate,
            dateAdded: Date(),
            icon: category.icon,
            color: category.color
        )
        
        // Call the save callback
        onSave(savedPlace)
        
        // Success haptic
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Show success briefly then dismiss
        withAnimation(.spring(response: 0.3)) {
            dismissPopup()
        }
    }
    
    private func dismissPopup() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isShowing = false
        }
    }
}


// MARK: - Category Button
struct CategoryButton: View {
    let category: SaveLocationPopup.LocationCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : category.color)
                
                Text(category.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            gradient: Gradient(colors: [category.color, category.color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [category.color.opacity(0.1), category.color.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? category.color : category.color.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .scaleEffect(isSelected ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
} 
