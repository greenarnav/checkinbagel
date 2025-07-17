//
//  CommonComponents.swift
//  moodgpt
//
//  Created by Test on 5/27/25.
//

import SwiftUI
import WebKit

// MARK: - Animated Emoji View
struct AnimatedEmoji: View {
    let emojiName: String  // Original emotion name for Unicode fallback
    let gifEmojiName: String  // Emoji name to use for GIF lookup
    let size: CGFloat
    let fallbackEmoji: String
    
    init(_ emojiName: String, size: CGFloat = 50, fallback: String = "smile") {
        self.emojiName = emojiName  // Always preserve original for Unicode fallback
        self.size = size
        self.fallbackEmoji = fallback
        
        // Determine which emoji name to use for GIF file lookup
        if EmojiMapper.hasGifFile(for: emojiName) {
            self.gifEmojiName = emojiName
        } else if EmojiMapper.hasGifFile(for: fallback) {
            print("Warning: No GIF for '\(emojiName)', using GIF fallback '\(fallback)'")
            self.gifEmojiName = fallback
        } else {
            print("Warning: No GIF for '\(emojiName)' or fallback '\(fallback)', using default 'smile' for GIF")
            self.gifEmojiName = "smile" // Default that should have GIF
        }
    }
    
    var body: some View {
        let gifFileName = EmojiMapper.getGifName(for: gifEmojiName)
        
        // Look for GIF files in the emoji folder
        if let gifURL = Bundle.main.url(forResource: gifFileName, withExtension: "gif") {
            GIFView(url: gifURL)
                .frame(width: size, height: size)
        } else {
            // Use original emotion name for Unicode fallback (not the GIF fallback name)
            let fallbackEmoji = EmojiMapper.getUnicodeEmoji(for: emojiName)
            Text(fallbackEmoji)
                .font(.system(size: size * 0.8))
                .frame(width: size, height: size)
        }
    }
}

// MARK: - GIF View using WebKit
struct GIFView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isUserInteractionEnabled = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let data = try? Data(contentsOf: url) else { return }
        uiView.load(data, mimeType: "image/gif", characterEncodingName: "", baseURL: url)
    }
}

// MARK: - Mood Filter Button
struct MoodFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .gray)
                .cornerRadius(12)
        }
    }
} 