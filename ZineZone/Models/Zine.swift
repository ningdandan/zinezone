import Foundation
import FirebaseFirestore

struct Zine: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var coverImageUrl: String
    var artistId: String // 自动填 user不可见
    var createdAt: Date? // 自动填 user不可见
    var pages: Int? //页数
    var publishedAt: Date? //出版日
    var tags: [String]? // 新增: 一个zine可以有多个tag（存tag名字）
    var type: String?
    var link: String?
}

struct Tag: Identifiable, Codable {
    @DocumentID var id: String?  // 直接用tag名小写，比如 "poetry"
    var displayName: String // 展示用名字，比如 "Poetry"
    var category: String // Category,分三组：content type、theme、technique
    var createdAt: Date
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

struct Flower: Identifiable, Codable {
    @DocumentID var id: String?
    var fromUserId: String // 谁送的花
    var toZineId: String // 哪本zine
    var assetsType: Int // 1=红花，2=蓝花，3=黄花 （默认为1 配assets）
    var message: String // 留言内容
    var createdAt: Date?
}
