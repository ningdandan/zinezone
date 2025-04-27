import SwiftUI
import FirebaseCore

@main
struct ZineZoneApp: App {
    @StateObject var appState = AppStateViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
        }
    }
}
