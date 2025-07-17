import SwiftUI

// MARK: - Grouped Contact List Row
struct GroupedContactListRow: View {
    @Binding var contact: GroupedContact
    let onToggleFavorites: (String) -> Void // Pass phone number
    let isPinned: (String) -> Bool // Check if phone number is pinned
    let onEditName: () -> Void
    let onSplitContact: () -> Void // New callback for splitting
    let onMergeContact: () -> Void // New callback for merging
    let contactHasSimilarContacts: (String) -> Bool // Check for similar contacts
    
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var contactsManager = ContactsManager()
    @State private var showingPhoneNumbers = false
    @State private var editingName = false
    @State private var editedName = ""
    @State private var showingActionSheet = false
    @State private var selectedPhoneNumber = ""
    @State private var showSplitDialog = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Main contact row
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
                    .onLongPressGesture(minimumDuration: 2.0) {
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        showSplitDialog = true
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    // Name without edit button
                    Text(contact.name)
                        .font(.headline)
                        .foregroundColor(themeManager.primaryTextColor)
                        .lineLimit(1)
                    
                    // Show phone numbers on same line
                    Text(contact.phoneNumbers.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(1)
                    
                    // Display header stats if available for any phone number
                    if let firstPhoneNumber = contact.phoneNumbers.first,
                       let headerStats = contactsManager.getHeaderStats(for: firstPhoneNumber),
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
                    }
                }
                
                Spacer()
                
                // Single Add/Remove button for the contact
                VStack(spacing: 4) {
                    let hasAnyPinned = contact.phoneNumbers.contains { isPinned($0) }
                    let allPinned = contact.phoneNumbers.allSatisfy { isPinned($0) }
                    
                    if allPinned {
                        Text("Added")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else if hasAnyPinned {
                        Text("Partial")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    } else {
                        Text("Add")
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Button(action: {
                        // Add all numbers if none are pinned, or remove all if any are pinned
                        if hasAnyPinned {
                            // Remove all pinned numbers
                            contact.phoneNumbers.forEach { phoneNumber in
                                if isPinned(phoneNumber) {
                                    onToggleFavorites(phoneNumber)
                                }
                            }
                        } else {
                            // Add the first number (or all if you prefer)
                            onToggleFavorites(contact.primaryPhoneNumber)
                        }
                    }) {
                        let hasAnyPinned = contact.phoneNumbers.contains { isPinned($0) }
                        Image(systemName: hasAnyPinned ? "minus.circle.fill" : "plus.circle")
                            .foregroundColor(hasAnyPinned ? .red : .blue)
                            .font(.title2)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(themeManager.cardBackgroundColor.opacity(0.7))
        .contentShape(Rectangle())
        .alert("Contact Options", isPresented: $showSplitDialog) {
            Button("Cancel", role: .cancel) { }
            
            if contact.hasMultipleNumbers {
                Button("Split Into Separate Contacts") {
                    onSplitContact()
                }
            }
            
            // Check if there are similar contacts to merge with
            if contactHasSimilarContacts(contact.name) {
                Button("Merge Similar Contacts") {
                    onMergeContact()
                }
            }
        } message: {
            if contact.hasMultipleNumbers && contactHasSimilarContacts(contact.name) {
                Text("Split '\(contact.name)' into separate contacts, or merge with similar contacts like '\(contact.name) (2)'.")
            } else if contact.hasMultipleNumbers {
                Text("Split '\(contact.name)' into separate contacts for each phone number.")
            } else if contactHasSimilarContacts(contact.name) {
                Text("Merge '\(contact.name)' with similar contacts.")
            } else {
                Text("No actions available for this contact.")
            }
        }
    }
}

#if DEBUG
#Preview {
    GroupedContactListRow(
        contact: .constant(GroupedContact(
            name: "John Doe",
            phoneNumbers: ["+1234567890", "+1987654321"]
        )),
        onToggleFavorites: { _ in },
        isPinned: { _ in false },
        onEditName: {},
        onSplitContact: {},
        onMergeContact: {},
        contactHasSimilarContacts: { _ in false }
    )
    .environmentObject(ThemeManager())
    .padding()
}
#endif 