import SwiftUI

struct EditUserProfileView: View {
    @Binding var userProfile: UserProfile
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var name: String = ""
    @State private var avatar: String = ""
    @State private var description: String = ""
    @State private var instagram: String = ""
    @State private var twitter: String = ""
    @State private var website: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Spacer().frame(height: 20)
                
                // 头像
                Button(action: {
                    showingImagePicker = true
                }) {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else if let avatarUrl = userProfile.avatar, let url = URL(string: avatar) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                        } placeholder: {
                            Circle()
                                .fill(Color.gray)
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 100, height: 100)
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(image: $selectedImage)
                }

                
                // Name
                TextField("Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Description
                TextField("Description", text: $description)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Instagram
                TextField("Instagram handle", text: $instagram)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Twitter
                TextField("Twitter handle", text: $twitter)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Website
                TextField("Website", text: $website)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Spacer()
                
                // Save按钮
                Button(action: {
                    saveProfile()
                }) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Edit Profile")
            .onAppear {
                loadFields()
            }
        }
    }
    
    private func loadFields() {
        self.name = userProfile.displayName
        self.description = userProfile.aboutMe
        self.instagram = userProfile.social_ig
        self.twitter = userProfile.social_twi
        self.website = userProfile.social_web
    }
    
    private func saveProfile() {
        if let selectedImage = selectedImage,
           let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
            
            // 先上传头像
            ZineService.uploadAvatar(imageData: imageData) { result in
                switch result {
                case .success(let urlString):
                    self.userProfile.avatar = urlString
                    self.saveUserProfileData()
                case .failure(let error):
                    print("Upload avatar failed: \(error.localizedDescription)")
                    // 即使头像上传失败，也可以只保存文字
                    self.saveUserProfileData()
                }
            }
        } else {
            // 没有选新头像，直接保存
            saveUserProfileData()
        }
    }
    
    private func saveUserProfileData() {
        userProfile.displayName = name
        userProfile.aboutMe = description
        userProfile.social_ig = instagram
        userProfile.social_twi = twitter
        userProfile.social_web = website
        
        // Placeholder：调用Service保存user profile到Firestore
        ZineService.updateUserProfile(profile: userProfile) { error in
                if let error = error {
                    print("Error saving profile: \(error.localizedDescription)")
                    // 可以考虑给用户一个Toast提示保存失败
                } else {
                    print("Profile saved successfully!")
                    // 保存成功，关闭编辑页
                    presentationMode.wrappedValue.dismiss()
                }
            }

    }
    
    
}
