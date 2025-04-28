import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseAuth

struct UserProfileView: View {
    @State private var userZines: [Zine] = []
    @State private var allZines: [Zine] = []
    @State private var userProfile: UserProfile = UserProfile.placeholder() // 占位数据
    @State private var isEditingProfile = false
    @State private var isShowingSettings = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            VStack {
                ProfileHeaderView(
                    userProfile: userProfile,
                    isCurrentUser: true,
                    onEditTapped: {
                        isEditingProfile = true
                    },
                    onShareTapped: {
                        // todo: 分享功能
                    }
                )
                
                Divider()
                    .padding(.vertical, 12)
                
                ScrollView {
                    ZineGridView(zines: userZines)
                        .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("User")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                    }
                }
            }
            .fullScreenCover(isPresented: $isShowingSettings) {
                SettingsView(userProfile: $userProfile)
            }
            .fullScreenCover(isPresented: $isEditingProfile) {
                EditUserProfileView(userProfile: $userProfile)
            }
            .onAppear {
                loadUserProfile()
                fetchZines()
            }
        }
    }
    
    private func fetchZines() {
        ZineService.fetchUploadedZines { zines in
            self.userZines = zines
        }
    }

    
    private func uploadedZines() -> [Zine] {
        guard let userId = Auth.auth().currentUser?.uid else {
            return []
        }
        
        return allZines.filter { $0.artistId == userId }
    }
    
    private func loadUserProfile() {
        ZineService.fetchUserProfile { profile in
                if let profile = profile {
                    self.userProfile = profile
                } else {
                    print("Failed to load user profile.")
                }
            }
        }
 
}
