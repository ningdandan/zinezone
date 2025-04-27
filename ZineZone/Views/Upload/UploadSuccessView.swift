import SwiftUI

struct UploadSuccessView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppStateViewModel

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 120, height: 120)
                .foregroundColor(.green)
            
            Text("发布成功！")
                .font(.largeTitle)
                .bold()
            
            Button(action: {
                // 返回首页
                appState.selectedTab = 0 // 我们后面让AppState加一个selectedTab
            }) {
                Text("返回首页")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}
