import SwiftUI

struct ProfileHeaderView: View {
    let userProfile: UserProfile
    let isCurrentUser: Bool
    var onEditTapped: (() -> Void)? = nil
    var onShareTapped: (() -> Void)? = nil
    
    var body: some View {
        VStack {
            Spacer().frame(height: 20)
            
            // 头像
            if let avatarUrl = userProfile.avatar, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Circle()
                        .fill(Color.gray)
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 100, height: 100)
            }
            
            // 用户名
            Text(userProfile.displayName)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 8)
            
            // 简介
            if !userProfile.aboutMe.isEmpty {
                Text(userProfile.aboutMe)
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            
            // 社交链接
            HStack(spacing: 12) {
                if !userProfile.social_ig.isEmpty {
                    SocialButton(platform: .instagram, handle: userProfile.social_ig)
                }
                if !userProfile.social_twi.isEmpty {
                    SocialButton(platform: .twitter, handle: userProfile.social_twi)
                }
                if !userProfile.social_web.isEmpty {
                    SocialButton(platform: .website, handle: userProfile.social_web)
                }
            }
            .padding(.top, 8)
            
            // Edit / Share 按钮
            if isCurrentUser {
                HStack(spacing: 30) {
                    Button(action: {
                        onEditTapped?()
                    }) {
                        Text("Edit")
                            .frame(width: 100, height: 44)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        onShareTapped?()
                    }) {
                        Text("Share")
                            .frame(width: 100, height: 44)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 12)
            }
        }
    }
    
    

struct SocialButton: View {
    let platform: SocialPlatform
    let handle: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: platform.buildURL(from: handle)) {
                UIApplication.shared.open(url)
            }
        }) {
            Text(platform.displayName)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(6)
        }
    }
}

enum SocialPlatform {
    case instagram
    case twitter
    case website
    
    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .twitter: return "Twitter"
        case .website: return "Website"
        }
    }
    
    func buildURL(from handle: String) -> String {
        switch self {
        case .instagram:
            if handle.isEmpty { return "https://www.instagram.com" }
            return "https://www.instagram.com/\(handle)/"
        case .twitter:
            if handle.isEmpty { return "https://twitter.com" }
            return "https://twitter.com/\(handle)"
        case .website:
            return handle // website字段存的是完整url
        }
    }
}

}
