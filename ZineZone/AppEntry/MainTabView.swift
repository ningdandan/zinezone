import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppStateViewModel
    
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
    }
}
