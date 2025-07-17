//
//  CheckInSocialInfluenceView.swift
//  CheckIn
//
//  Created by AI Assistant on 28/06/2025.
//

import SwiftUI

// MARK: - Contact Influence Data Models
struct ContactInfluence: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let mood: String
    let relationship: String
    let lastSeen: String
    let influenceLevel: InfluenceLevel
    
    var influenceText: String {
        switch influenceLevel {
        case .high: return "High Impact"
        case .medium: return "Medium Impact"
        case .low: return "Low Impact"
        }
    }
    
    var influenceColor: Color {
        switch influenceLevel {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

enum InfluenceLevel {
    case high, medium, low
}

// MARK: - CheckIn Social Influence View
struct CheckInSocialInfluenceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedContacts: Set<UUID> = Set()
    @State private var searchText = ""
    
    private let contactInfluences = [
        ContactInfluence(name: "Sarah Chen", emoji: "happy", mood: "Joyful", relationship: "Best Friend", lastSeen: "2 hours ago", influenceLevel: .high),
        ContactInfluence(name: "Marcus Johnson", emoji: "worried", mood: "Stressed", relationship: "Coworker", lastSeen: "1 hour ago", influenceLevel: .medium),
        ContactInfluence(name: "Emma Rodriguez", emoji: "excited", mood: "Excited", relationship: "Sister", lastSeen: "30 min ago", influenceLevel: .high),
        ContactInfluence(name: "David Kim", emoji: "tired", mood: "Exhausted", relationship: "Friend", lastSeen: "4 hours ago", influenceLevel: .low),
        ContactInfluence(name: "Lisa Park", emoji: "love", mood: "Content", relationship: "Partner", lastSeen: "1 hour ago", influenceLevel: .high),
        ContactInfluence(name: "James Wilson", emoji: "frustrated", mood: "Frustrated", relationship: "Manager", lastSeen: "3 hours ago", influenceLevel: .medium),
        ContactInfluence(name: "Alex Thompson", emoji: "sad", mood: "Down", relationship: "Friend", lastSeen: "6 hours ago", influenceLevel: .medium),
        ContactInfluence(name: "Maya Patel", emoji: "grateful", mood: "Grateful", relationship: "Mentor", lastSeen: "5 hours ago", influenceLevel: .low)
    ]
    
    private var filteredContacts: [ContactInfluence] {
        if searchText.isEmpty {
            return contactInfluences
        } else {
            return contactInfluences.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.mood.localizedCaseInsensitiveContains(searchText) ||
                $0.relationship.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                        
                        // Search bar
                        searchBarView
                        
                        // Influence Categories
                        influenceCategoriesView
                        
                        // Contact List
                        contactListView
                        
                        // Emotional Insights
                        emotionalInsightsView
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Social Influence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save selected influences
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .disabled(selectedContacts.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            Text("Who influences your mood?")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Select people whose emotions affect your own emotional state")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            // Selection count
            if !selectedContacts.isEmpty {
                Text("\(selectedContacts.count) influences selected")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))
            
            TextField("Search contacts, moods, or relationships...", text: $searchText)
                .foregroundColor(.white)
                .accentColor(.blue)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Influence Categories
    private var influenceCategoriesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Influence Levels")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach([InfluenceLevel.high, .medium, .low], id: \.self) { level in
                    influenceCategoryCard(level)
                }
            }
        }
    }
    
    private func influenceCategoryCard(_ level: InfluenceLevel) -> some View {
        let contacts = filteredContacts.filter { $0.influenceLevel == level }
        let selectedCount = contacts.filter { selectedContacts.contains($0.id) }.count
        
        return VStack(spacing: 8) {
            Text(level == .high ? "High" : level == .medium ? "Medium" : "Low")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Text("\(selectedCount)/\(contacts.count)")
                .font(.system(size: 12))
                .foregroundColor(level == .high ? .red : level == .medium ? .orange : .green)
            
            Circle()
                .fill(level == .high ? Color.red.opacity(0.2) : level == .medium ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
                .frame(width: 8, height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Contact List
    private var contactListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select People")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(filteredContacts) { contact in
                    contactInfluenceCard(contact)
                }
            }
        }
    }
    
    private func contactInfluenceCard(_ contact: ContactInfluence) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedContacts.contains(contact.id) {
                    selectedContacts.remove(contact.id)
                } else {
                    selectedContacts.insert(contact.id)
                }
            }
        }) {
            HStack(spacing: 12) {
                // Contact emoji
                AnimatedEmoji(contact.emoji, size: 42, fallback: "neutral-face")
                    .frame(width: 40, height: 40)
                
                // Contact info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(contact.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(contact.relationship)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    HStack {
                        Text("Feeling \(contact.mood.lowercased())")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text(contact.lastSeen)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    // Influence level
                    HStack {
                        Text(contact.influenceText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(contact.influenceColor)
                        
                        Spacer()
                        
                        if selectedContacts.contains(contact.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedContacts.contains(contact.id) ? Color.blue.opacity(0.1) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedContacts.contains(contact.id) ? Color.blue.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Emotional Insights
    private var emotionalInsightsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Emotional Insights")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                insightCard(
                    icon: "person.2.fill",
                    title: "Social Contagion",
                    description: "Research shows that emotions can spread between close contacts. Your selected high-influence people have 3x more impact on your mood.",
                    color: .blue
                )
                
                insightCard(
                    icon: "brain.head.profile",
                    title: "Emotional Patterns",
                    description: "You tend to mirror the emotions of your partner and best friends. Being aware of this can help you maintain emotional balance.",
                    color: .purple
                )
                
                insightCard(
                    icon: "heart.fill",
                    title: "Positive Influence",
                    description: "Currently, 60% of your selected influences are in positive emotional states, which may boost your overall mood.",
                    color: .green
                )
            }
        }
    }
    
    private func insightCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview
#if DEBUG
struct CheckInSocialInfluenceView_Previews: PreviewProvider {
    static var previews: some View {
        CheckInSocialInfluenceView()
    }
}
#endif 