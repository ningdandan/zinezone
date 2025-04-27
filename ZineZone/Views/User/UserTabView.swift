import SwiftUI

struct UserTabView: View {
    @EnvironmentObject var appState: AppStateViewModel
    
    var body: some View {
        if appState.isLoggedIn {
            UserProfileView()
        } else {
            LoginView()
        }
    }
}
