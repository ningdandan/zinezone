import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userId: String?
    
    private var db = Firestore.firestore()

    func handleSignIn(user: User) {
        let userId = user.uid
        self.userId = userId
        
        let userRef = db.collection("users").document(userId)

        userRef.getDocument { document, error in
            if let document = document, document.exists {
                // 已经有Profile了
                print("User profile exists.")
                DispatchQueue.main.async {
                    self.isLoggedIn = true
                }
            } else {
                // 新用户，需要创建Profile
                print("Creating new user profile...")
                
                userRef.setData([
                    "displayName": user.displayName ?? "",
                    "email": user.email ?? "",
                    "avatar": "", // 初始为空，用户后面设置
                    "aboutMe": "",
                    "social_ig": "",
                    "social_twi": "",
                    "social_web": "",
                    "savedZines": [],
                    "publishedZines": [],
                    "createdAt": FieldValue.serverTimestamp()
                ]) { error in
                    if let error = error {
                        print("Error creating user profile: \(error.localizedDescription)")
                    } else {
                        print("New user profile created.")
                        DispatchQueue.main.async {
                            self.isLoggedIn = true
                        }
                    }
                }
            }
        }
    }
}
