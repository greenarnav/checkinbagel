import SwiftUI

struct NewPageView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var username = ""
    @State private var displayName = ""
    @State private var selectedInterests: Set<String> = []
    @State private var profilePicture: UIImage?
    @State private var showingImagePicker = false
    @State private var showingInterestSelector = false
    @State private var bio = ""
    @State private var selectedMood = "😊"
    @State private var isPrivateProfile = false
    @State private var showingConfirmation = false
    @State private var isCreatingProfile = false
    
    private let availableInterests = [
        "Music", "Movies", "Reading", "Fitness", "Cooking",
        "Travel", "Art", "Gaming", "Technology", "Nature",
        "Sports", "Photography", "Meditation", "Theater"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 24) {
                        profilePictureSection
                        basicInfoSection
                        moodSection
                        interestsSection
                        bioSection
                        privacySection
                        createProfileButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.primaryTextColor)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $profilePicture)
        }
        .sheet(isPresented: $showingInterestSelector) {
            InterestSelectorView(
                selectedInterests: $selectedInterests,
                availableInterests: availableInterests,
                isPresented: $showingInterestSelector
            )
            .environmentObject(themeManager)
        }
        .alert("Profile Created!", isPresented: $showingConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your profile has been created successfully!")
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()
            
            if let gradient = themeManager.backgroundGradient {
                gradient
                    .ignoresSafeArea()
                    .opacity(0.3)
            }
        }
    }
    
    private var profilePictureSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingImagePicker = true
            }) {
                ZStack {
                    Circle()
                        .fill(themeManager.cardBackgroundColor)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(themeManager.borderColor, lineWidth: 2)
                        )
                    
                    if let image = profilePicture {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 32))
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            Text("Add Photo")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                }
            }
            
            Text("Tap to add profile picture")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }
    
    private var basicInfoSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Username")
                    .font(.headline)
                    .foregroundColor(themeManager.primaryTextColor)
                
                TextField("Enter username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name")
                    .font(.headline)
                    .foregroundColor(themeManager.primaryTextColor)
                
                TextField("Enter display name", text: $displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
    
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Mood")
                .font(.headline)
                .foregroundColor(themeManager.primaryTextColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(["😊", "😄", "😍", "🤔", "😌", "😎", "🥳", "😇"], id: \.self) { mood in
                        Button(action: {
                            selectedMood = mood
                        }) {
                            Text(mood)
                                .font(.system(size: 32))
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(selectedMood == mood ? themeManager.accentColor.opacity(0.3) : Color.clear)
                                )
                                .scaleEffect(selectedMood == mood ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: selectedMood)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Interests")
                    .font(.headline)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                Button(action: {
                    showingInterestSelector = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            if selectedInterests.isEmpty {
                Text("No interests selected")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding(.vertical, 8)
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80))
                ], spacing: 8) {
                    ForEach(Array(selectedInterests), id: \.self) { interest in
                        InterestButton(
                            interest: interest,
                            isSelected: true,
                            onTap: {
                                selectedInterests.remove(interest)
                            }
                        )
                        .environmentObject(themeManager)
                    }
                }
            }
        }
    }
    
    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bio")
                .font(.headline)
                .foregroundColor(themeManager.primaryTextColor)
            
            TextField("Tell us about yourself...", text: $bio, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
    
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy")
                .font(.headline)
                .foregroundColor(themeManager.primaryTextColor)
            
            Toggle("Private Profile", isOn: $isPrivateProfile)
                .toggleStyle(SwitchToggleStyle())
            
            if isPrivateProfile {
                Text("Only people you approve can see your profile")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }
    
    private var createProfileButton: some View {
        Button(action: {
            createProfile()
        }) {
            HStack {
                if isCreatingProfile {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "person.crop.circle.fill.badge.plus")
                }
                
                Text(isCreatingProfile ? "Creating..." : "Create Profile")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .disabled(isCreatingProfile || username.isEmpty || displayName.isEmpty)
            .opacity(username.isEmpty || displayName.isEmpty ? 0.6 : 1.0)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Functions
    
    private func createProfile() {
        isCreatingProfile = true
        
        // Simulate profile creation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isCreatingProfile = false
            showingConfirmation = true
        }
    }
}

// MARK: - Supporting Views

struct InterestSelectorView: View {
    @Binding var selectedInterests: Set<String>
    let availableInterests: [String]
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            VStack {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120))
                ], spacing: 12) {
                    ForEach(availableInterests, id: \.self) { interest in
                        InterestButton(
                            interest: interest,
                            isSelected: selectedInterests.contains(interest),
                            onTap: {
                                if selectedInterests.contains(interest) {
                                    selectedInterests.remove(interest)
                                } else {
                                    selectedInterests.insert(interest)
                                }
                            }
                        )
                        .environmentObject(themeManager)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Select Interests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(themeManager.primaryTextColor)
                }
            }
        }
    }
}

struct InterestButton: View {
    let interest: String
    let isSelected: Bool
    let onTap: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            Text(interest)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : themeManager.primaryTextColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : themeManager.cardBackgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color.blue : themeManager.borderColor, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ConfirmationPopup: View {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let onConfirm: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.headline)
                .foregroundColor(themeManager.primaryTextColor)
            
            Text(message)
                .font(.body)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(themeManager.secondaryTextColor)
                
                Button("Confirm") {
                    onConfirm()
                    isPresented = false
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
                .shadow(radius: 10)
        )
        .padding()
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    NewPageView()
        .environmentObject(ThemeManager())
} 