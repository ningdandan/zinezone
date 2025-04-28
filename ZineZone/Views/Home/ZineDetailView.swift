import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth

struct ZineDetailView: View {
    let zine: Zine  // 从首页传进来一个Zine对象
    @State private var isSaved: Bool = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var userProfile: UserProfile? = nil
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @Environment(\.presentationMode) var presentationMode
    
    // Flower related states
    @State private var showFlowerModal = false
    @State private var flowerMessage = ""
    @State private var selectedFlowerType = 1
    @State private var flowers: [Flower] = []
    @State private var flowerUserProfiles: [String: UserProfile] = [:]
    @State private var flowerZines: [String: Zine] = [:]
    
    // Check if current user is the creator of this zine
    private var isCurrentUserCreator: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return zine.artistId == currentUserId
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Cover image with delete button overlay
                ZStack(alignment: .topTrailing) {
                    WebImage(url: URL(string: zine.coverImageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(height: 300)
                        .clipped()
                    
                    if isCurrentUserCreator {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.red.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        .padding(16)
                    }
                }
                
                // 这里新增user信息
                if let userProfile = userProfile {
                    NavigationLink(destination: ProfileView(userProfile: userProfile)) {
                        HStack(spacing: 8) {
                            if let avatarUrl = userProfile.avatar, let url = URL(string: avatarUrl) {
                                WebImage(url: url)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 32, height: 32)
                            }
                            
                            Text(userProfile.displayName)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Text(zine.title)
                    .font(.title)
                    .bold()
                
                HStack(spacing: 12) {
                    Button(action: {
                        toggleSave()
                    }) {
                        HStack {
                            Image(systemName: isSaved ? "star.fill" : "star")
                                .font(.title)
                            
                            Text(isSaved ? "Saved" : "Save")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isSaved ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showFlowerModal = true
                    }) {
                        HStack {
                            Image(systemName: "gift")
                                .font(.title)
                            
                            Text("Give Flower")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
                
                // Flowers and messages section
                if !flowers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Flowers & Messages")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        FlowerListView(
                            flowers: flowers,
                            senderProfiles: flowerUserProfiles,
                            zines: flowerZines,
                            emptyMessage: "No flowers yet. Be the first to give one!"
                        )
                    }
                    .padding(.horizontal)
                }
                
                if showToast {
                    VStack {
                        Spacer()
                        
                        Text(toastMessage)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.bottom, 50)
                            .transition(.opacity)
                            .animation(.easeInOut, value: showToast)
                    }
                }
            }
            
            .onAppear {
                loadSavedStatus()
                loadUserProfile()
                loadFlowers()
            }
            .padding()
        }
        .navigationTitle("Zine Detail")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFlowerModal) {
            FlowerModalView(
                flowerMessage: $flowerMessage,
                selectedFlowerType: $selectedFlowerType,
                onSubmit: giveFlower
            )
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("删除Zine"),
                message: Text("确定要删除这个Zine吗？此操作无法撤销。"),
                primaryButton: .destructive(Text("删除")) {
                    deleteZine()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .overlay(
            Group {
                if isDeleting {
                    ProgressView("删除中...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 4)
                }
            }
        )
    }
    
    private func loadUserProfile() {
            guard userProfile == nil else { return }
            ZineService.fetchUserProfile(userId: zine.artistId) { profile in
                if let profile = profile {
                    self.userProfile = profile
                }
            }
        }
    
    private func loadSavedStatus() {
        guard let zineId = zine.id else { return }
        ZineService.isZineSaved(zineId: zineId) { isSaved in
            self.isSaved = isSaved
        }
    }
    
    private func toggleSave() {
        guard let zineId = zine.id else { return }
        
        if isSaved {
            // 取消收藏
            ZineService.unsaveZine(zineId: zineId) { error in
                if error == nil {
                    isSaved = false
                    showToast(message: "Unsaved")
                }
            }
        } else {
            // 收藏
            ZineService.saveZine(zineId: zineId) { error in
                if error == nil {
                    isSaved = true
                    showToast(message: "Saved")
                }
            }
        }
    }
    
    private func showToast(message: String) {
        self.toastMessage = message
        self.showToast = true
        
        // 自动3秒后消失
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showToast = false
        }
    }
    
    // MARK: - Delete Function
    
    private func deleteZine() {
        guard let zineId = zine.id else { return }
        isDeleting = true
        
        ZineService.deleteZine(zineId: zineId) { error in
            isDeleting = false
            
            if let error = error {
                showToast(message: "删除失败: \(error.localizedDescription)")
            } else {
                showToast(message: "Zine删除成功")
                
                // Navigate back to the User tab
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    // Post notification to navigate to User tab
                    NotificationCenter.default.post(name: Notification.Name("NavigateToProfile"), object: nil)
                    
                    // Dismiss this detail view
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    // MARK: - Flower functions
    
    private func loadFlowers() {
        guard let zineId = zine.id else { return }
        
        ZineService.fetchFlowers(forZineId: zineId) { flowers in
            self.flowers = flowers
            
            // Load user profiles for each flower sender
            let uniqueUserIds = Set(flowers.map { $0.fromUserId })
            for userId in uniqueUserIds {
                loadUserProfile(userId: userId)
            }
            
            // Store current zine in the flower zines map
            if let id = zine.id {
                self.flowerZines[id] = zine
            }
        }
    }
    
    private func loadUserProfile(userId: String) {
        ZineService.fetchUserProfile(userId: userId) { profile in
            if let profile = profile {
                self.flowerUserProfiles[userId] = profile
            }
        }
    }
    
    private func giveFlower() {
        guard let zineId = zine.id else { return }
        
        ZineService.giveFlower(toZineId: zineId, assetsType: selectedFlowerType, message: flowerMessage) { error in
            if let error = error {
                showToast(message: "Failed to give flower: \(error.localizedDescription)")
            } else {
                showToast(message: "Flower given successfully!")
                flowerMessage = ""
                showFlowerModal = false
                
                // Reload flowers to show the new one
                loadFlowers()
            }
        }
    }
}

// MARK: - Supporting Views

struct FlowerModalView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var flowerMessage: String
    @Binding var selectedFlowerType: Int
    var onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Send a Flower & Message")
                .font(.title2)
                .bold()
                .padding(.top)
            
            HStack(spacing: 20) {
                ForEach(1...3, id: \.self) { type in
                    Button(action: {
                        selectedFlowerType = type
                    }) {
                        Image(systemName: flowerTypeIcon(type))
                            .font(.system(size: 30))
                            .foregroundColor(flowerTypeColor(type))
                            .padding()
                            .background(
                                Circle()
                                    .stroke(selectedFlowerType == type ? flowerTypeColor(type) : Color.gray, lineWidth: 2)
                            )
                    }
                }
            }
            .padding()
            
            TextField("Your message (optional)", text: $flowerMessage)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            
            Button(action: {
                onSubmit()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Send Flower")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    private func flowerTypeIcon(_ type: Int) -> String {
        switch type {
        case 1: return "rosette"
        case 2: return "sparkles"
        case 3: return "leaf"
        default: return "rosette"
        }
    }
    
    private func flowerTypeColor(_ type: Int) -> Color {
        switch type {
        case 1: return .red
        case 2: return .blue
        case 3: return .yellow
        default: return .red
        }
    }
}
