import SwiftUI

// MARK: - Contacts List View
struct ContactsListView: View {
    @StateObject private var contactsManager = ContactsManager()
    @State private var searchText = ""
    
    // This will be passed from HomeView to know which favorite slot is being filled
    var onSelectContactForFavorite: ((DeviceContact) -> Void)? = nil
    // Environment variable to dismiss the sheet if presented that way
    @Environment(\.dismiss) var dismissSheet

    var filteredContacts: [DeviceContact] {
        if searchText.isEmpty {
            return contactsManager.allContacts
        } else {
            return contactsManager.allContacts.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) || 
                $0.initials.localizedCaseInsensitiveContains(searchText) 
            }
        }
    }

    var body: some View {
        NavigationView { // Or use existing NavigationView if part of a larger flow
            VStack {
                if contactsManager.isLoading {
                    ProgressView("Loading Contacts...")
                        .padding()
                } else if let errorMessage = contactsManager.permissionError {
                    VStack(spacing: 20) {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("Try Again or Check Settings") {
                            contactsManager.refreshContactsIfPermitted() // Or guide to settings
                        }
                        .padding()
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if contactsManager.allContacts.isEmpty && contactsManager.permissionError == nil {
                     VStack(spacing: 20) {
                        Text("No contacts found or permission not yet requested.")
                            .multilineTextAlignment(.center)
                        Button("Load Contacts") {
                            contactsManager.refreshContactsIfPermitted()
                        }
                        .padding()
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List(filteredContacts) { contact in
                        HStack {
                            Text(contact.initials)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(Circle())
                            Text(contact.name)
                            Spacer()
                        }
                        .contentShape(Rectangle()) // Make the whole row tappable
                        .onTapGesture {
                            if let onSelect = onSelectContactForFavorite {
                                onSelect(contact) // Call the callback for HomeView
                                dismissSheet()    // Dismiss this view (if presented as a sheet)
                            } else {
                                // Default action if not selecting for favorite
                                // e.g., navigate to a detailed contact view within this list
                
                            }
                        }
                    }
                    .listStyle(.plain) // Use plain list style to avoid grouped background
                    .listRowSeparator(.hidden) // Hide separators if desired
                    .scrollContentBackground(.hidden) // Remove default List background (iOS 16+)
                    .background(Color.black) // Ensure overall background is black to blend with app theme
                    .onAppear {
                        // Set UITableView appearance for earlier iOS versions
                        UITableView.appearance().backgroundColor = .black
                    }
                    .searchable(text: $searchText, prompt: "Search Contacts")
                    .refreshable { // Pull to refresh
                        contactsManager.refreshContactsIfPermitted()
                    }
                }
            }
            .navigationTitle("All Contacts")
            .background(Color.black) // Ensure VStack background is black
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if onSelectContactForFavorite != nil { // Show Cancel if it's for picking a favorite
                        Button("Cancel") {
                            dismissSheet()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        contactsManager.refreshContactsIfPermitted()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(contactsManager.isLoading)
                }
            }
            .onAppear {
                // Decide if you want to auto-load or wait for button press
                if contactsManager.allContacts.isEmpty && contactsManager.permissionError == nil {
                     // contactsManager.refreshContactsIfPermitted() // Or wait for user action
                }
            }
        }
        .background(Color.black) // Fallback background for entire view
    }
}

// MARK: - Preview
#if DEBUG
struct ContactsListView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview for general contacts list
        ContactsListView()
        
        // Preview for selecting a contact for a favorite slot
        ContactsListView { contact in
            print("Preview: Selected \(contact.name) for favorite.")
        }
        .environmentObject(ContactsManager()) // Ensure manager is available for previews
    }
}
#endif 