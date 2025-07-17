//
//  TermsOfServiceView.swift
//  moodgpt
//
//  Created by Test on 6/1/25.
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Same beautiful gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.7, green: 0.4, blue: 0.9), // Purple
                        Color(red: 0.5, green: 0.6, blue: 0.9), // Purple-blue
                        Color(red: 0.3, green: 0.7, blue: 0.9), // Blue-teal
                        Color(red: 0.2, green: 0.8, blue: 0.8)  // Teal
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Semi-transparent overlay
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Terms of Service")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                            
                            Text("Last updated: Never")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        .padding(.top, 20)
                        
                        // Content sections with glass cards
                        VStack(spacing: 16) {
                            TermsSection(
                                title: "1. Acceptance of Terms",
                                content: "By using CheckIn, you agree that emotions are complicated, life is weird, and we're all just trying our best. If you don't agree, that's totally fine - we understand emotions are personal."
                            )
                            
                            TermsSection(
                                title: "2. Use of Service",
                                content: "CheckIn helps you track your emotional journey. We promise not to judge your feelings, even if you're grumpy on Mondays or inexplicably happy during traffic jams. Your emotions are valid, whatever they are."
                            )
                            
                            TermsSection(
                                title: "3. Privacy & Data",
                                content: "Your emotional data belongs to you. We don't sell your feelings to the highest bidder or share your Monday blues with advertisers. What happens in CheckIn, stays in CheckIn (unless you choose to share)."
                            )
                            
                            TermsSection(
                                title: "4. Emotional Responsibility",
                                content: "While we help track your emotions, we're not responsible for your crush not texting back, your coffee being cold, or your general existential dread. We're here to help, not to solve life's mysteries."
                            )
                            
                            TermsSection(
                                title: "5. App Behavior",
                                content: "Sometimes our app might feel emotions too - like when it crashes from too much happiness or gets slow when overwhelmed. We're working on app therapy sessions to help with this."
                            )
                            
                            TermsSection(
                                title: "6. Changes to Terms",
                                content: "We might update these terms when we feel like it, or when our lawyers have strong emotions about legal language. We'll try to let you know, but honestly, nobody reads these anyway."
                            )
                            
                            TermsSection(
                                title: "7. Contact Us",
                                content: "If you have questions, complaints, or just want to share how this app makes you feel, reach out to us. We're probably having feelings about something too and could use the company."
                            )
                            
                            // Fun disclaimer
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Important Disclaimer")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("This Terms of Service is intentionally lighthearted and not meant for actual legal purposes. In a real app, you'd want proper legal review. But for now, just know we care about your privacy and want you to have a good emotional journey with CheckIn! 💕")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .italic()
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .trackScreenAuto(TermsOfServiceView.self)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct TermsSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            Text(content)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .lineSpacing(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    TermsOfServiceView()
} 
