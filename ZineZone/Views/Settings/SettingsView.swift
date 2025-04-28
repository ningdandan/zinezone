import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var userProfile: UserProfile
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Button(action: {
                    logout()
                }) {
                    Text("Log Out")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Settings")
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            userProfile = UserProfile.placeholder()  // 登出后清空UserProfile
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
