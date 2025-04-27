import SwiftUI
import FirebaseAuth

class AppStateViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var selectedTab: Int = 0
    @Published var savedZines: [String] = []
    
    init() {
        self.isLoggedIn = Auth.auth().currentUser != nil
        
        // 监听登录状态变化
        Auth.auth().addStateDidChangeListener { _, user in
            self.isLoggedIn = user != nil
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isLoggedIn = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
