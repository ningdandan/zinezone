import SwiftUI
import SDWebImageSwiftUI

struct ZineGridView: View {
    let zines: [Zine]
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(zines) { zine in
                ZineGridItem(zine: zine)
            }
        }
        .padding(.horizontal)
    }
}

struct ZineGridItem: View {
    let zine: Zine
    @State private var userProfile: UserProfile? = nil
    
    var body: some View {
        NavigationLink(destination: ZineDetailView(zine: zine)) {
            VStack(alignment: .leading, spacing: 4) {
                WebImage(url: URL(string: zine.coverImageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipped()
                    .cornerRadius(10)
                
                Text(zine.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if let avatarUrl = userProfile?.avatar, let url = URL(string: avatarUrl) {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 24, height: 24)
                    }
                    
                    Text(userProfile?.displayName ?? "Unknown User")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(4)
            .onAppear {
                loadUserProfile()
            }
        }
    }
    
    private func loadUserProfile() {
        guard userProfile == nil else { return }  // 避免重复加载
        ZineService.fetchUserProfile(userId: zine.artistId) { profile in
            if let profile = profile {
                self.userProfile = profile
            }
        }
    }
}
