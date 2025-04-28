import SwiftUI
import FirebaseFirestore

struct MainTabView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var selectedTab: Int = 0  // 当前显示的Tab索引
        
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            UploadView()
                .tabItem {
                    Label("Upload", systemImage: "plus.circle")
                }
                .tag(1)
            
            UserTabView()
                .tabItem {
                    Label("User", systemImage: "person.crop.circle")
                }
                .tag(2)
        }
        
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToProfile"))) { _ in
            appState.selectedTab = 2  // User tab index is 2
        }
    }
}

//
//
//func batchInsertTags() {
//    let db = Firestore.firestore()
//    let batch = db.batch()
//    
//    let tagsCollection = db.collection("tags")
//    let now = Date()
//    
//    let contentTypes = [
//        "poetry", "short_story", "essay", "photography", "illustration", "comics"
//    ]
//    
//    let themes = [
//        "personal", "queer", "activism", "love", "mental_health", "nature",
//        "politics", "identity", "fashion", "music", "anime", "travel"
//    ]
//    
//    let techniques = [
//        "riso", "screen_printing", "letterpress", "handmade", "mixed_media", "collage", "digital"
//    ]
//    
//    // 插入 Content Type
//    for tag in contentTypes {
//        let docRef = tagsCollection.document(tag) // id = 小写名
//        let tagData: [String: Any] = [
//            "displayName": formatDisplayName(tag),
//            "category": "Content Type",
//            "createdAt": Timestamp(date: now)
//        ]
//        batch.setData(tagData, forDocument: docRef)
//    }
//    
//    // 插入 Theme
//    for tag in themes {
//        let docRef = tagsCollection.document(tag)
//        let tagData: [String: Any] = [
//            "displayName": formatDisplayName(tag),
//            "category": "Theme",
//            "createdAt": Timestamp(date: now)
//        ]
//        batch.setData(tagData, forDocument: docRef)
//    }
//    
//    // 插入 Technique
//    for tag in techniques {
//        let docRef = tagsCollection.document(tag)
//        let tagData: [String: Any] = [
//            "displayName": formatDisplayName(tag),
//            "category": "Technique",
//            "createdAt": Timestamp(date: now)
//        ]
//        batch.setData(tagData, forDocument: docRef)
//    }
//    
//    // 提交批量写入
//    batch.commit { error in
//        if let error = error {
//            print("批量插入 tags 失败: \(error)")
//        } else {
//            print("批量插入 tags 成功！🎉")
//        }
//    }
//}
//
//// 辅助函数：把 "short_story" 转成 "Short Story"
//func formatDisplayName(_ text: String) -> String {
//    return text
//        .replacingOccurrences(of: "_", with: " ")
//        .capitalized
//}
