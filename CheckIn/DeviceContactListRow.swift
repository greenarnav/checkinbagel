import SwiftUI

struct DeviceContactListRow: View {
    let contact: DeviceContact
    let onToggleFavorites: () -> Void
    let isPinned: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var contactsManager = ContactsManager()
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile image placeholder with initials
            Circle()
                .fill(themeManager.currentTheme == .light ? Color.blue.opacity(0.2) : Color.gray.opacity(0.5))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(contact.initials)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme == .light ? .blue : .white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.headline)
                    .foregroundColor(themeManager.primaryTextColor)
                    .lineLimit(1)
                
                Text(contact.phoneNumber)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(1)
                
                // Display header stats if available
                if let headerStats = contactsManager.getHeaderStats(for: contact.phoneNumber),
                   let data = headerStats.data {
                    HStack(spacing: 8) {
                        if let energy = data.energy {
                            Text("⚡ \(energy)")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        if let sleepHours = data.sleepHours {
                            Text("😴 \(sleepHours, specifier: "%.1f")h")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        if let heartRate = data.heartRate {
                            Text("❤️ \(heartRate)")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                        if let steps = data.steps {
                            Text("👟 \(steps)")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                } else if isPinned {
                    Text("Added to home")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Tap to add to home")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Spacer()
            
            // Toggle favorites button
            Button(action: onToggleFavorites) {
                Image(systemName: isPinned ? "minus.circle.fill" : "plus.circle")
                    .foregroundColor(isPinned ? .red : .blue)
                    .font(.title2)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(themeManager.cardBackgroundColor.opacity(0.7))
        .contentShape(Rectangle())
    }
}

#if DEBUG
#Preview {
    DeviceContactListRow(
        contact: DeviceContact(
            name: "John Doe",
            initials: "JD",
            phoneNumber: "+1234567890"
        ),
        onToggleFavorites: {},
        isPinned: false
    )
    .environmentObject(ThemeManager())
    .padding()
}
#endif 