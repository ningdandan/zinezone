import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore

struct ProfileView: View {
    let userProfile: UserProfile
    
    @State private var userZines: [Zine] = []
    @State private var userFlowers: [Flower] = []
    @State private var flowerSenders: [String: UserProfile] = [:]
    @State private var flowerZines: [String: Zine] = [:]
    @State private var selectedTab = 0  // 0 for Zines, 1 for Flowers
    @State private var isLoadingFlowers = false
    
    var body: some View {
        VStack {
            ProfileHeaderView(
                userProfile: userProfile,
                isCurrentUser: false,
                onEditTapped: {},
                onShareTapped: {
                    // todo: 分享功能，可以做
                }
            )
//            ZineGridView(zines: userZines)

            Divider()
                .padding(.vertical, 12)
            
            // Tab selector
            HStack(spacing: 0) {
                TabButton(text: "Zines", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                TabButton(text: "Flowers", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            .padding(.bottom, 12)
            
            // Content based on selected tab
            ScrollView {
                if selectedTab == 0 {
                    // Zines tab
                    ZineGridView(zines: userZines)
                        .padding(.horizontal)
                } else {
                    // Flowers tab
                    if isLoadingFlowers {
                        ProgressView("Loading flowers...")
                            .padding()
                    } else {
                        FlowerListView(
                            flowers: userFlowers,
                            senderProfiles: flowerSenders,
                            zines: flowerZines
                        )
                    }
                }
            }
        }
        .padding()
        .navigationTitle(userProfile.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchUserZines()
            fetchUserFlowers()
        }
    }
    
    private func fetchUserZines() {
        guard let userId = userProfile.id else { return }
        
        ZineService.fetchUploadedZines(userId: userId) { zines in
            self.userZines = zines
        }
    }
    
    private func fetchUserFlowers() {
        guard let userId = userProfile.id else { return }
        
        isLoadingFlowers = true
        
        // Directly fetch flowers by userId
        ZineService.fetchFlowersByUserId(userId: userId) { flowers in
            self.userFlowers = flowers
            
            // Load zine info for each flower
            let zineIds = Set(flowers.map { $0.toZineId })
            for zineId in zineIds {
                loadZineInfo(zineId: zineId)
            }
            
            // Load sender profiles
            let senderIds = Set(flowers.map { $0.fromUserId })
            for senderId in senderIds {
                loadUserProfile(userId: senderId)
            }
            
            self.isLoadingFlowers = false
        }
    }
    
    private func loadUserProfile(userId: String) {
        ZineService.fetchUserProfile(userId: userId) { profile in
            if let profile = profile {
                self.flowerSenders[userId] = profile
            }
        }
    }
    
    private func loadZineInfo(zineId: String) {
        let db = Firestore.firestore()
        db.collection("zines").document(zineId).getDocument { snapshot, error in
            if let zine = try? snapshot?.data(as: Zine.self) {
                self.flowerZines[zineId] = zine
            }
        }
    }
}

// MARK: - Supporting Views

struct TabButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(text)
                    .font(.headline)
                    .foregroundColor(isSelected ? .primary : .gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                
                if isSelected {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(height: 3)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 3)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}


