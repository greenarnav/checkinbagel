//
//  ContactDetailComponents.swift
//  moodgpt
//
//  Created by Test on 5/27/25.
//

import SwiftUI

// MARK: - Pull-Down Interactive Components
struct PullDownTimelineCard: View {
    let item: EmotionalTimelineItem
    @Binding var showingOverlay: Bool
    @State private var dragOffset: CGFloat = 0
    @Binding var replyContext: ReplyContext?
    
    var body: some View {
        VStack(spacing: 8) {
            Text(item.time)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.8))
            
            AnimatedEmoji(item.mood, size: 32, fallback: item.mood)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                .scaleEffect(dragOffset > 0 ? 1.0 + (dragOffset / 300) : 1.0)
                .offset(y: dragOffset > 0 ? dragOffset * 0.2 : 0)
            
            Text(item.description)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            if item.isCurrentTime {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 6, height: 6)
                    .shadow(color: Color.yellow.opacity(0.6), radius: 3, x: 0, y: 0)
            }
            
            if dragOffset > 30 {
                Text("Pull to chat")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .transition(.opacity)
            }
        }
        .frame(width: 80, height: dragOffset > 30 ? 120 : 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(item.isCurrentTime ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(item.isCurrentTime ? Color.yellow : Color.white.opacity(0.2), lineWidth: item.isCurrentTime ? 2 : 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 60 {
                        // Set context and open chat
                        replyContext = ReplyContext(
                            type: .timeline,
                            content: item.time,
                            emoji: item.mood
                        )
                        withAnimation(.spring()) {
                            showingOverlay = true
                        }
                    }
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
        )
    }
}

struct PullDownAnalysisCard: View {
    let text: String
    let contact: Contact
    @Binding var showingOverlay: Bool
    @State private var dragOffset: CGFloat = 0
    @Binding var replyContext: ReplyContext?
    
    var body: some View {
        VStack(spacing: 8) {
            Text(text)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if dragOffset > 30 {
                HStack {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text("Pull down to discuss this analysis")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .transition(.opacity)
                .padding(.bottom, 10)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .scaleEffect(dragOffset > 0 ? 1.0 + (dragOffset / 1000) : 1.0)
        .offset(y: dragOffset > 0 ? dragOffset * 0.1 : 0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 80 {
                        // Set context and open chat
                        replyContext = ReplyContext(
                            type: .analysis,
                            content: text,
                            emoji: nil
                        )
                        withAnimation(.spring()) {
                            showingOverlay = true
                        }
                    }
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
        )
    }
}

struct PullDownEmotionCard: View {
    let contact: Contact
    @Binding var showingOverlay: Bool
    @State private var dragOffset: CGFloat = 0
    @Binding var replyContext: ReplyContext?
    
    var body: some View {
        VStack(spacing: 15) {
            Text(contact.moodText)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Primary Emotion")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Last updated 2 minutes ago")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            if dragOffset > 30 {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text("Pull down to chat about this emotion")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .transition(.opacity)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .scaleEffect(dragOffset > 0 ? 1.0 + (dragOffset / 800) : 1.0)
        .offset(y: dragOffset > 0 ? dragOffset * 0.15 : 0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 80 {
                        // Set context and open chat
                        replyContext = ReplyContext(
                            type: .emotion,
                            content: contact.moodText,
                            emoji: contact.mood
                        )
                        withAnimation(.spring()) {
                            showingOverlay = true
                        }
                    }
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
        )
    }
}

// MARK: - Pull-Down Interactive Behavior Pattern Card
struct PullDownBehaviorPatternCard: View {
    let icon: String
    let title: String
    let frequency: String
    let description: String
    let tags: [String]
    @Binding var showingOverlay: Bool
    @State private var dragOffset: CGFloat = 0
    @Binding var replyContext: ReplyContext?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(frequency)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            if dragOffset > 30 {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text("Pull down to discuss \(title.lowercased())")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .transition(.opacity)
                .padding(.top, 5)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .scaleEffect(dragOffset > 0 ? 1.0 + (dragOffset / 1000) : 1.0)
        .offset(y: dragOffset > 0 ? dragOffset * 0.1 : 0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 80 {
                        // Set context and open chat
                        replyContext = ReplyContext(
                            type: .analysis,
                            content: "\(title): \(description)",
                            emoji: nil
                        )
                        withAnimation(.spring()) {
                            showingOverlay = true
                        }
                    }
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
        )
    }
}

// MARK: - Pull-Down Interactive Communication Insight Row
struct PullDownCommunicationInsightRow: View {
    let icon: String
    let title: String
    let value: String
    @Binding var showingOverlay: Bool
    @State private var dragOffset: CGFloat = 0
    @Binding var replyContext: ReplyContext?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.title3)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            if dragOffset > 30 {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text("Pull down to ask about \(title.lowercased())")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .transition(.opacity)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .scaleEffect(dragOffset > 0 ? 1.0 + (dragOffset / 1000) : 1.0)
        .offset(y: dragOffset > 0 ? dragOffset * 0.1 : 0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 80 {
                        // Set context and open chat
                        replyContext = ReplyContext(
                            type: .analysis,
                            content: "\(title): \(value)",
                            emoji: nil
                        )
                        withAnimation(.spring()) {
                            showingOverlay = true
                        }
                    }
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
        )
    }
}

// MARK: - Pull-Down Interactive Mood Change Row
struct PullDownMoodChangeRow: View {
    let fromMood: String
    let toMood: String
    let timeAgo: String
    let reason: String?
    @Binding var showingOverlay: Bool
    @State private var dragOffset: CGFloat = 0
    @Binding var replyContext: ReplyContext?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                AnimatedEmoji(fromMood, size: 28, fallback: fromMood)
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.white.opacity(0.6))
                
                AnimatedEmoji(toMood, size: 28, fallback: toMood)
                
                Spacer()
                
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            if let reason = reason {
                HStack {
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
            }
            
            if dragOffset > 30 {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text("Pull down to discuss this mood change")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .transition(.opacity)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .scaleEffect(dragOffset > 0 ? 1.0 + (dragOffset / 1000) : 1.0)
        .offset(y: dragOffset > 0 ? dragOffset * 0.1 : 0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 80 {
                        // Set context and open chat
                        let contextContent = reason != nil ? 
                            "Mood changed from \(fromMood) to \(toMood) \(timeAgo): \(reason!)" :
                            "Mood changed from \(fromMood) to \(toMood) \(timeAgo)"
                        
                        replyContext = ReplyContext(
                            type: .timeline,
                            content: contextContent,
                            emoji: toMood
                        )
                        withAnimation(.spring()) {
                            showingOverlay = true
                        }
                    }
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
        )
    }
}

// MARK: - Pull-Down Interactive Secondary Emotion
struct PullDownSecondaryEmotion: View {
    let emotion: String
    let emoji: String
    let percentage: Int
    @Binding var showingOverlay: Bool
    @State private var dragOffset: CGFloat = 0
    @Binding var replyContext: ReplyContext?
    
    var body: some View {
        VStack(spacing: 8) {
            AnimatedEmoji(emoji, size: 30, fallback: emoji)
                .scaleEffect(dragOffset > 0 ? 1.0 + (dragOffset / 300) : 1.0)
            
            Text(emotion)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("\(percentage)%")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            
            if dragOffset > 20 {
                Text("Pull to chat")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .transition(.opacity)
            }
        }
        .frame(width: 80, height: dragOffset > 20 ? 100 : 80)
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .scaleEffect(dragOffset > 0 ? 1.0 + (dragOffset / 500) : 1.0)
        .offset(y: dragOffset > 0 ? dragOffset * 0.2 : 0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 60 {
                        // Set context and open chat
                        replyContext = ReplyContext(
                            type: .emotion,
                            content: "\(emotion) (\(percentage)% intensity)",
                            emoji: emoji
                        )
                        withAnimation(.spring()) {
                            showingOverlay = true
                        }
                    }
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
        )
    }
}

// MARK: - Simple Display Components
struct TimelineCard: View {
    let item: EmotionalTimelineItem
    
    var body: some View {
        Button(action: {
            // Make timeline cards clickable with haptic feedback
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            VStack(spacing: 8) {
                Text(item.time)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                
                // Validate emoji is approved
                let validEmoji = EmojiMapper.isValidEmoji(item.mood) ? item.mood : "😊"
                AnimatedEmoji(validEmoji, size: 32, fallback: validEmoji)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                Text(item.description)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                if item.isCurrentTime {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 6, height: 6)
                        .shadow(color: Color.yellow.opacity(0.6), radius: 3, x: 0, y: 0)
                }
            }
            .frame(width: 80, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.isCurrentTime ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(item.isCurrentTime ? Color.yellow : Color.white.opacity(0.2), lineWidth: item.isCurrentTime ? 2 : 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            .scaleEffect(item.isCurrentTime ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: item.isCurrentTime)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AnalysisCard: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.body)
            .foregroundColor(.white.opacity(0.9))
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

struct EmotionCard: View {
    let contact: Contact
    
    var body: some View {
        VStack(spacing: 15) {
            Text(contact.moodText)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Primary Emotion")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Last updated 2 minutes ago")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Supporting Components
struct BehaviorPatternCard: View {
    let icon: String
    let title: String
    let frequency: String
    let description: String
    let tags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(frequency)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

struct TriggerRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.8))
                .font(.caption)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

struct CommunicationInsightRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct MoodChangeRow: View {
    let fromMood: String
    let toMood: String
    let timeAgo: String
    let reason: String?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                AnimatedEmoji(fromMood, size: 28, fallback: fromMood)
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.white.opacity(0.6))
                
                AnimatedEmoji(toMood, size: 28, fallback: toMood)
                
                Spacer()
                
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            if let reason = reason {
                HStack {
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Contact Mood Stack Component
struct ContactMoodStack: View {
    let contacts: [Contact]
    let maxDisplay: Int = 4
    
    var displayContacts: [Contact] {
        Array(contacts.prefix(maxDisplay))
    }
    
    var body: some View {
        HStack(spacing: -8) {
            ForEach(Array(displayContacts.enumerated()), id: \.element.id) { index, contact in
                ZStack {
                    // Outer glow/outline effect
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.8),
                                    Color.white.opacity(0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 38, height: 38)
                        .blur(radius: 1)
                    
                    // White background circle
                    Circle()
                        .fill(Color.white)
                        .frame(width: 34, height: 34)
                    
                    // Inner shadow for depth
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.0),
                                    Color.black.opacity(0.1)
                                ]),
                                center: .center,
                                startRadius: 10,
                                endRadius: 17
                            )
                        )
                        .frame(width: 34, height: 34)
                    
                    // Top highlight arc
                    Circle()
                        .trim(from: 0.65, to: 0.95)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.9),
                                    Color.white.opacity(0.4)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(-90))
                    
                    // Animated emoji - slightly bigger
                    AnimatedEmoji(contact.mood, size: 24, fallback: contact.mood)
                }
                .zIndex(Double(maxDisplay - index))
                .scaleEffect(1 - (CGFloat(index) * 0.05))
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 1, y: 2)
            }
            
            // Show +X more indicator if there are more contacts
            if contacts.count > maxDisplay {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.9))
                        .frame(width: 34, height: 34)
                    
                    Text("+\(contacts.count - maxDisplay)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 1, y: 2)
            }
        }
    }
}

// MARK: - Energy Selector
struct CompactEnergySelector: View {
    @Binding var isPresented: Bool
    @State private var energyLevel: Double = 50
    @State private var dragAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 6)
            
            // Header
            HStack {
                Text("Your Energy Right Now")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Done") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
                .foregroundColor(.blue)
                .fontWeight(.semibold)
            }
            
            // Circular Energy Selector
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                // Energy arc
                Circle()
                    .trim(from: 0, to: energyLevel / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.red, .orange, .yellow, .green]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                
                // Center content
                VStack(spacing: 8) {
                    Text("\(Int(energyLevel))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(energyDescription)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Draggable handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 30, height: 30)
                    .shadow(radius: 5)
                    .offset(x: 100 * cos(angleForEnergy), y: 100 * sin(angleForEnergy))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let center = CGPoint(x: 0, y: 0)
                                let angle = atan2(value.location.y - center.y, value.location.x - center.x)
                                var normalizedAngle = angle + .pi / 2
                                
                                if normalizedAngle < 0 {
                                    normalizedAngle += 2 * .pi
                                }
                                
                                let percentage = (normalizedAngle / (2 * .pi)) * 100
                                energyLevel = max(0, min(100, percentage))
                            }
                    )
            }
            .frame(width: 220, height: 220)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    private var angleForEnergy: Double {
        let percentage = energyLevel / 100
        return (percentage * 2 * .pi) - .pi / 2
    }
    
    private var energyDescription: String {
        switch energyLevel {
        case 0..<20: return "Very Low"
        case 20..<40: return "Low"
        case 40..<60: return "Moderate"
        case 60..<80: return "High"
        default: return "Very High"
        }
    }
} 
