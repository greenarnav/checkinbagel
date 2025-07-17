import SwiftUI

// MARK: - Follower Row View
struct FollowerListRow: View {
    let follower: Follower
    let onFollowBack: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showInfoTooltip = false
    
    // Random emoji for each follower based on their name
    private var followerEmoji: String {
        let emojis = ["😊", "🤗", "😎", "🥰", "😃", "🙂", "😌", "🤓", "😍", "🥳"]
        let index = abs(follower.name.hashValue) % emojis.count
        return emojis[index]
    }
    
    var body: some View {
        ZStack {
            HStack(spacing: 12) {
                // Emoji avatar
                AnimatedEmoji(followerEmoji, size: 52, fallback: followerEmoji)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(follower.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.primaryTextColor)
                            .lineLimit(1)
                        
                        if !follower.isFollowingBack {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showInfoTooltip.toggle()
                                }
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue.opacity(0.7))
                            }
                        }
                    }
                    
                    Text("Location Unknown")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Follow status indicator
                    if follower.isFollowingBack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                    } else {
                        Button(action: onFollowBack) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text("Updated now")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.borderColor, lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
            
            // Info tooltip
            if showInfoTooltip {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 14))
                        
                        Text("Follow to see their info")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showInfoTooltip = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Text("You need to add them to following first to view their detailed profile and emotions.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
                .offset(y: -80)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
                .zIndex(999)
            }
        }
    }
}

#if DEBUG
#Preview {
    FollowerListRow(
        follower: Follower(
            name: "John Doe",
            phoneNumber: "+1234567890",
            isFollowingBack: false
        ),
        onFollowBack: {}
    )
    .environmentObject(ThemeManager())
    .padding()
}
#endif 