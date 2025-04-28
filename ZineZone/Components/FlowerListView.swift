import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore

// MARK: - Flower List View

/// A view that displays a list of flowers, showing an empty state if there are no flowers
struct FlowerListView: View {
    let flowers: [Flower]
    let senderProfiles: [String: UserProfile]
    let zines: [String: Zine]
    let emptyMessage: String
    
    init(
        flowers: [Flower],
        senderProfiles: [String: UserProfile],
        zines: [String: Zine],
        emptyMessage: String = "No flowers received yet"
    ) {
        self.flowers = flowers
        self.senderProfiles = senderProfiles
        self.zines = zines
        self.emptyMessage = emptyMessage
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if flowers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                    
                    Text(emptyMessage)
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                ForEach(flowers) { flower in
                    FlowerItemView(
                        flower: flower,
                        senderProfile: senderProfiles[flower.fromUserId],
                        zine: zines[flower.toZineId],
                        showZineInfo: zines[flower.toZineId] != nil
                    )
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Flower Item View

/// A view that displays a single flower item with sender information and optional zine information
struct FlowerItemView: View {
    let flower: Flower
    let senderProfile: UserProfile?
    let zine: Zine?
    let showZineInfo: Bool
    
    init(
        flower: Flower,
        senderProfile: UserProfile?,
        zine: Zine? = nil,
        showZineInfo: Bool = false
    ) {
        self.flower = flower
        self.senderProfile = senderProfile
        self.zine = zine
        self.showZineInfo = showZineInfo
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User avatar
            if let profile = senderProfile, let avatarUrl = profile.avatar, let url = URL(string: avatarUrl) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 40, height: 40)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Flower icon
                    flowerIcon
                        .frame(width: 24, height: 24)
                    
                    // User name
                    Text(senderProfile?.displayName ?? "Anonymous")
                        .font(.subheadline)
                        .bold()
                }
                
                // Show which zine received this flower (if showing zine info)
                if showZineInfo, let zine = zine {
                    Text("to \"\(zine.title)\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                
                // Message if any
                if !flower.message.isEmpty {
                    Text(flower.message)
                        .font(.body)
                        .padding(.top, 2)
                }
                
                // Time
                if let date = flower.createdAt {
                    Text(dateFormatter.string(from: date))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    private var flowerIcon: some View {
        let systemName: String
        let color: Color
        
        switch flower.assetsType {
        case 2:
            systemName = "sparkles"
            color = .blue
        case 3:
            systemName = "leaf"
            color = .yellow
        default:
            systemName = "rosette"
            color = .red
        }
        
        return Image(systemName: systemName)
            .foregroundColor(color)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
} 