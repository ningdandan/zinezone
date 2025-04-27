import SwiftUI
import SDWebImageSwiftUI

struct ZineDetailView: View {
    let zine: Zine  // 从首页传进来一个Zine对象
    @State private var isSaved: Bool = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WebImage(url: URL(string: zine.coverImageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .clipped()
                
                Text(zine.title)
                    .font(.title)
                    .bold()
                
                Text("by \(zine.artistId)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Divider()
                
                Text(zine.description)
                    .font(.body)
                    .padding(.bottom, 20)
                
                Spacer()
                
                Button(action: {
                    toggleSave()
                }) {
                    HStack {
                        Image(systemName: isSaved ? "star.fill" : "star")
                            .font(.title)
                        
                        Text(isSaved ? "Saved" : "Save")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSaved ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                if showToast {
                        VStack {
                            Spacer()
                            
                            Text(toastMessage)
                                .padding()
                                .background(Color.black.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.bottom, 50)
                                .transition(.opacity)
                                .animation(.easeInOut, value: showToast)
                        }
                    }
            }
            
            .onAppear {
                loadSavedStatus()
            }
            .padding()
            
            

        }
        .navigationTitle("Zine Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func loadSavedStatus() {
        guard let zineId = zine.id else { return }
        ZineService.isZineSaved(zineId: zineId) { isSaved in
            self.isSaved = isSaved
        }
    }
    
    private func toggleSave() {
        guard let zineId = zine.id else { return }
        
        if isSaved {
            // 取消收藏
            ZineService.unsaveZine(zineId: zineId) { error in
                if error == nil {
                    isSaved = false
                    showToast(message: "Unsaved")
                }
            }
        } else {
            // 收藏
            ZineService.saveZine(zineId: zineId) { error in
                if error == nil {
                    isSaved = true
                    showToast(message: "Saved")
                }
            }
        }
    }
    
    private func showToast(message: String) {
        self.toastMessage = message
        self.showToast = true
        
        // 自动3秒后消失
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showToast = false
        }
    }
    

}
