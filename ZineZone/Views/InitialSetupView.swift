import SwiftUI
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore

struct InitialSetupView: View {
    @State private var displayName: String = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isSaving = false
    @State private var shouldGoToHome = false
    
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Avatar选择
            Button(action: {
                showImagePicker = true
            }) {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text("选择头像")
                                .foregroundColor(.white)
                                .font(.caption)
                        )
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            
            
            // Display Name输入
            TextField("请输入你的昵称", text: $displayName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Spacer()
            
            // 保存按钮
            Button(action: {
                saveProfile()
            }) {
                if isSaving {
                    ProgressView()
                } else {
                    Text("保存")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            NavigationLink(destination: HomeView(), isActive: $shouldGoToHome) {
                EmptyView()
            }
        }
    }
    
    private func saveProfile() {
        guard let user = Auth.auth().currentUser else {
            print("No current user.")
            return
        }
        
        isSaving = true
        
        guard let selectedImage = selectedImage else {
            print("No image selected. Skipping avatar upload.")
            updateUserProfile(userId: user.uid, avatarUrl: nil)
            return
        }
        
        // 有图片，继续上传
        uploadAvatarImage(selectedImage, for: user.uid) { result in
            switch result {
            case .success(let avatarUrl):
                self.updateUserProfile(userId: user.uid, avatarUrl: avatarUrl)
            case .failure(let error):
                print("Upload avatar error: \(error.localizedDescription)")
                isSaving = false
            }
        }
    }
    
    private func uploadAvatarImage(_ image: UIImage, for userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageConversion", code: -1, userInfo: nil)))
            return
        }
        
        let storageRef = storage.reference().child("avatars/\(userId).jpg")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let downloadUrl = url?.absoluteString {
                    completion(.success(downloadUrl))
                } else {
                    completion(.failure(NSError(domain: "URLConversion", code: -1, userInfo: nil)))
                }
            }
        }
    }
    
    private func updateUserProfile(userId: String, avatarUrl: String?) {
        var data: [String: Any] = [
            "displayName": self.displayName
        ]
        
        if let avatarUrl = avatarUrl {
            data["avatar"] = avatarUrl
        }
        
        db.collection("users").document(userId).updateData(data) { error in
            isSaving = false
            if let error = error {
                print("Error updating user profile: \(error.localizedDescription)")
            } else {
                print("User profile updated successfully.")
                DispatchQueue.main.async {
                    self.shouldGoToHome = true
                }
            }
        }
        
    }
    
}
