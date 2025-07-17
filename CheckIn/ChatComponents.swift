//
//  ChatComponents.swift
//  moodgpt
//
//  Created by Test on 5/27/25.
//

import SwiftUI

// MARK: - Enhanced Full Screen Chat Overlay
struct FullScreenChatOverlay: View {
    let recipientName: String
    let replyContext: ReplyContext?
    @Binding var isShowing: Bool
    @State private var text: String = ""
    @StateObject private var chatStorage = ChatStorage()
    @FocusState private var isFocused: Bool
    @Environment(\.chatIsShowing) var chatIsShowing
    @State private var keyboardHeight: CGFloat = 0
    
    var messages: [ChatMessage] {
        chatStorage.getMessages(for: recipientName)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Enhanced background with subtle blur effect
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissChat()
                    }
                
                VStack(spacing: 0) {
                    // Simple tap-to-close area with handle
                    VStack(spacing: 12) {
                        // Handle bar indicator
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 40, height: 6)
                            .padding(.top, 12)
                        
                        // Contact info
                        VStack(spacing: 4) {
                            Text(recipientName)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("Active now")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.3),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .onTapGesture {
                        dismissChat()
                    }
                    
                    // Enhanced messages area with better scrolling
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Enhanced reply context
                                if let context = replyContext {
                                    EnhancedReplyContextView(context: context, recipientName: recipientName)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 20)
                                }
                                
                                // Messages with better spacing
                                ForEach(messages) { message in
                                    EnhancedMessageBubble(message: message)
                                        .id(message.id)
                                }
                                
                                // Scroll anchor
                                Color.clear
                                    .frame(height: 20)
                                    .id("bottom")
                            }
                        }
                        .onChange(of: messages.count) { _ in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    
                    // Enhanced input area
                    VStack(spacing: 0) {
                        // Input container
                        HStack(spacing: 12) {
                            Button(action: {
                                // Camera/attachment action
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.title2)
                            }
                            
                            HStack(spacing: 8) {
                                TextField("Message", text: $text, axis: .vertical)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                                    .focused($isFocused)
                                    .lineLimit(1...4)
                                    .onSubmit {
                                        sendMessage()
                                    }
                                
                                if !text.isEmpty {
                                    Button(action: {
                                        sendMessage()
                                    }) {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            
                            if text.isEmpty {
                                Button(action: {
                                    // Voice message action
                                }) {
                                    Image(systemName: "mic.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.title2)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.clear,
                                    Color.black.opacity(0.3)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.1))
                        .background(.ultraThinMaterial)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 8)
                .padding(.bottom, keyboardHeight > 0 ? 8 : 40)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            // Close chat if swiped down significantly
                            if value.translation.height > 100 {
                                dismissChat()
                            }
                        }
                )
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            chatIsShowing.wrappedValue = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
    }
    
    private func dismissChat() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isShowing = false
            chatIsShowing.wrappedValue = false
            isFocused = false
        }
    }
    
    private func sendMessage() {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let contextString = generateContextString()
        let newMessage = ChatMessage(
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            isFromUser: true,
            replyContext: contextString,
            timestamp: Date()
        )
        chatStorage.addMessage(newMessage, for: recipientName)
        text = ""
        
        // Simulate a response after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.0...2.5)) {
            let response = ChatMessage(
                text: generateResponse(),
                isFromUser: false,
                replyContext: nil,
                timestamp: Date()
            )
            chatStorage.addMessage(response, for: recipientName)
        }
    }
    
    private func generateContextString() -> String {
        guard let context = replyContext else { return recipientName }
        
        switch context.type {
        case .emotion:
            return "\(recipientName)'s \(context.content) mood"
        case .timeline:
            return "\(context.emoji ?? "") at \(context.content)"
        case .analysis:
            return "\(recipientName)'s analysis"
        }
    }
    
    private func generateResponse() -> String {
        guard let context = replyContext else {
            let responses = [
                "Thanks for your message! 😊",
                "Great to hear from you!",
                "I appreciate you reaching out!",
                "Thanks for checking in! 💙"
            ]
            return responses.randomElement() ?? "Thanks for your message!"
        }
        
        switch context.type {
        case .emotion:
            let responses = [
                "I appreciate your thoughts on my \(context.content) mood! 😊",
                "Thanks for noticing my \(context.content) energy today!",
                "It means a lot that you're checking in on my \(context.content) feelings! 💙",
                "Your support when I'm feeling \(context.content) really helps! 🙏"
            ]
            return responses.randomElement() ?? "I appreciate your thoughts on my \(context.content) mood!"
        case .timeline:
            let responses = [
                "Yes, that's exactly how I felt at \(context.content)! 😊",
                "You really understand my mood patterns! 😊",
                "Thanks for paying attention to my day! 💙",
                "It's nice to have someone who notices these details! 🙏"
            ]
            return responses.randomElement() ?? "Yes, that's exactly how I felt at \(context.content)!"
        case .analysis:
            let responses = [
                "Your insights on my emotional patterns are really helpful! 🧠",
                "I love how you understand my moods so well! 😊",
                "Thanks for the thoughtful analysis! 💙",
                "You always know just what to say! 🙏"
            ]
            return responses.randomElement() ?? "Your insights on my emotional patterns are really helpful!"
        }
    }
}

// MARK: - Enhanced Reply Context View
struct EnhancedReplyContextView: View {
    let context: ReplyContext
    let recipientName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text("Replying to")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            HStack(spacing: 12) {
                if let emoji = context.emoji {
                    AnimatedEmoji(emoji, size: 32, fallback: emoji)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contextTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(contextDescription)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    private var contextTitle: String {
        switch context.type {
        case .emotion:
            return "\(recipientName)'s Current Emotion"
        case .timeline:
            return "Timeline Event"
        case .analysis:
            return "Emotion Analysis"
        }
    }
    
    private var contextDescription: String {
        switch context.type {
        case .emotion:
            return "\(context.content) - Primary emotion"
        case .timeline:
            return "\(context.content) - \(context.emoji ?? "")"
        case .analysis:
            return String(context.content.prefix(80)) + "..."
        }
    }
}

// MARK: - Enhanced Message Bubble
struct EnhancedMessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser { Spacer(minLength: 60) }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 6) {
                if let context = message.replyContext {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                            .font(.caption2)
                        Text("Replying to \(context)")
                            .font(.caption2)
                    }
                    .foregroundColor(.white.opacity(0.6))
                }
                
                Text(message.text)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(message.isFromUser ? 
                                  LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                                  LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(message.isFromUser ? 0.1 : 0.2), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: 280, alignment: message.isFromUser ? .trailing : .leading)
            
            if !message.isFromUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 20)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 