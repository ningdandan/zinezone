import Foundation
import FirebaseFirestore

struct Zine: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var coverImageUrl: String
    var artistId: String
    var createdAt: Date?   // 用Date，FirebaseFirestoreSwift自动转Timestamp
    var type: String?
    var link: String?
}


struct UserProfile: Identifiable, Codable {
    @DocumentID var id: String? // Firestore文档ID
    
    var displayName: String
    var aboutMe: String
    var avatar: String?
    var social_ig: String
    var social_twi: String
    var social_web: String
    
    var createdAt: Date?
    
    // 默认空的初始化器
    static func placeholder() -> UserProfile {
        return UserProfile(
            id: nil,
            displayName: "",
            aboutMe: "",
            avatar: nil,
            social_ig: "",
            social_twi: "",
            social_web: "",
            createdAt: nil
        )
    }
}
