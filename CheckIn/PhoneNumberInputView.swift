import SwiftUI

struct PhoneNumberInputView: View {
    @Binding var phoneNumber: String
    @Binding var isPresented: Bool
    @State private var isValidPhoneNumber = true
    @State private var isLoading = false
    
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "phone.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Phone Number Required")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Please enter your phone number to complete the authentication process")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Phone input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)
                    
                    TextField("Enter your phone number", text: $phoneNumber)
                        .font(.body)
                        .keyboardType(.phonePad)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 20)
                        .frame(height: 55)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isValidPhoneNumber ? Color.clear : Color.red, lineWidth: 1)
                                )
                        )
                    
                    if !isValidPhoneNumber && !phoneNumber.isEmpty {
                        Text("Please enter a valid phone number (10-15 digits)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 30)
                
                // Debug info
                VStack {
                    Text("Debug Info:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Phone: '\(phoneNumber)'")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Valid: \(isFormValid)")
                        .font(.caption)
                        .foregroundColor(isFormValid ? .green : .red)
                    Text("Loading: \(isLoading)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Button Enabled: \(!(!isFormValid || isLoading))")
                        .font(.caption)
                        .foregroundColor(!(!isFormValid || isLoading) ? .green : .red)
                }
                .padding()
                
                // Save button
                Button(action: {
            
                    handleSave()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Text(isLoading ? "Saving..." : "Save Phone Number")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isFormValid ? Color.blue : Color.red.opacity(0.7))
                    )
                }
                .disabled(!isFormValid || isLoading)
                .opacity(isFormValid && !isLoading ? 1.0 : 0.6)
                .padding(.horizontal, 30)
                
                // Temporary test button (always enabled)
                Button(action: {
        
                    let cleanedPhoneNumber = phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
                    onSave(cleanedPhoneNumber.isEmpty ? "1234567890" : cleanedPhoneNumber)
                }) {
                    Text("TEST: Save Anyway")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green)
                        )
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .navigationTitle("Phone Number")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onChange(of: isPresented) { newValue in
            // Reset loading state when sheet is dismissed
            if !newValue {
                isLoading = false
            }
        }
    }
    
    private var isFormValid: Bool {
        let cleanedNumber = phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")

        return isValidPhoneNumberFormat(cleanedNumber)
    }
    
    private func isValidPhoneNumberFormat(_ number: String) -> Bool {
        // More lenient validation - just check if it has 10-15 digits
        let digitsOnly = number.replacingOccurrences(of: "+", with: "")
        let isValid = digitsOnly.count >= 10 && digitsOnly.count <= 15 && digitsOnly.allSatisfy { $0.isNumber }

        return isValid
    }
    
    private func handleSave() {
        print("handleSave() called")
        let cleanedPhoneNumber = phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        print("Original: '\(phoneNumber)' -> Cleaned: '\(cleanedPhoneNumber)'")
        
        if isValidPhoneNumberFormat(cleanedPhoneNumber) {
            print("Phone number is valid, proceeding...")
            isValidPhoneNumber = true
            isLoading = true
            onSave(cleanedPhoneNumber)
            
            // Reset loading state after a delay to prevent stuck button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
            }
        } else {
            print("Phone number is invalid")
            isValidPhoneNumber = false
        }
    }
}

// Keyboard helper extension removed - using global extension from LoginView

#Preview {
    PhoneNumberInputView(
        phoneNumber: .constant(""),
        isPresented: .constant(true),
        onSave: { phone in
            print("Saving phone: \(phone)")
        }
    )
} 