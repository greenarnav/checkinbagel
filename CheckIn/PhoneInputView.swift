import SwiftUI

// Legacy PhoneInputView - kept for compatibility
// New authentication flows should use PhoneNumberInputView instead
struct PhoneInputView: View {
    @Binding var isPresented: Bool
    @State private var phoneNumber = ""   // Stores the phone number input by the user
    @State private var isValidPhoneNumber = true // Validates phone number input
    @State private var phoneNumberSaved = false // Tracks if the phone number was saved successfully
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        PhoneNumberInputView(
            phoneNumber: $phoneNumber,
            isPresented: $isPresented,
            onSave: { phone in
                authManager.savePhoneNumber(phoneNumber: phone) { success in
                    if success {
                        isPresented = false
                    }
                }
            }
        )
    }
}

struct PhoneInputView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneInputView(isPresented: .constant(true))
    }
}
