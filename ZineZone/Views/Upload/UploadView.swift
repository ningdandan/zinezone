import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth

struct UploadView: View {
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var isUploading = false
    @State private var showSuccessPage = false
    
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    var body: some View {
        
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    NavigationLink(
                        destination: UploadSuccessView(),
                        isActive: $showSuccessPage,
                        label: { EmptyView() }
                    )
                    .hidden()
                    // 封面图片选择
                    Button(action: {
                        showImagePicker = true
                    }) {
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .cornerRadius(10)
                                .clipped()
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .frame(height: 200)
                                
                                Text("选择封面图片")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(image: $selectedImage)
                    }
                    
                    // 标题输入
                    TextField("标题", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    // 描述输入
                    TextField("描述", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    // 发布按钮
                    Button(action: {
                        uploadZine()
                    }) {
                        if isUploading {
                            ProgressView()
                        } else {
                            Text("发布")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                }
                .padding()
            }
            .navigationTitle("发布Zine")
        }
        
    }
    private func uploadZine() {
        guard let selectedImage = selectedImage else {
            print("No image selected")
            return
        }
        
        guard !title.isEmpty else {
            print("Title is empty")
            return
        }
        
        isUploading = true
        
        ZineService.uploadZineCover(image: selectedImage) { result in
            switch result {
            case .success(let (zineId, coverUrl)):
                ZineService.createZine(zineId: zineId, title: title, description: description, coverUrl: coverUrl) { error in
                    isUploading = false
                    if let error = error {
                        print("Error creating zine: \(error.localizedDescription)")
                    } else {
                        print("Zine uploaded successfully!")
                        resetFields()
                        showSuccessPage = true
                    }
                }
            case .failure(let error):
                print("Upload cover failed: \(error.localizedDescription)")
                isUploading = false
            }
        }
    }

    private func resetFields() {
        self.title = ""
        self.description = ""
        self.selectedImage = nil
    }

//    private func uploadZine() {
//        guard let selectedImage = selectedImage else {
//            print("No image selected")
//            return
//        }
//        
//        guard !title.isEmpty else {
//            print("Title is empty")
//            return
//        }
//        
//        isUploading = true
//        
//        let zineId = UUID().uuidString  // 生成一个唯一ID
//        
//        // 上传图片到Storage
//        let storageRef = storage.reference().child("zine-covers/\(zineId).jpg")
//        
//        if let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
//            storageRef.putData(imageData, metadata: nil) { metadata, error in
//                if let error = error {
//                    print("Upload error: \(error.localizedDescription)")
//                    isUploading = false
//                    return
//                }
//                
//                storageRef.downloadURL { url, error in
//                    if let error = error {
//                        print("Download URL error: \(error.localizedDescription)")
//                        isUploading = false
//                        return
//                    }
//                    
//                    if let coverUrl = url?.absoluteString {
//                        // 创建Firestore文档
//                        createZineInFirestore(zineId: zineId, coverUrl: coverUrl)
//                    }
//                }
//            }
//        }
//    }
    
//    private func createZineInFirestore(zineId: String, coverUrl: String) {
//        guard let user = Auth.auth().currentUser else {
//            print("No user logged in")
//            isUploading = false
//            return
//        }
//        
//        let data: [String: Any] = [
//            "title": title,
//            "description": description,
//            "coverImageUrl": coverUrl,
//            "artistId": user.uid,
//            "createdAt": FieldValue.serverTimestamp(),
//            "type": "digital",
//            "link": ""
//        ]
//        
//        db.collection("zines").document(zineId).setData(data) { error in
//            isUploading = false
//            if let error = error {
//                print("Error saving zine: \(error.localizedDescription)")
//            } else {
//                print("Zine uploaded successfully!")
//                // 上传成功后清空输入
//                self.title = ""
//                self.description = ""
//                self.selectedImage = nil
//                self.showSuccessPage = true
//            }
//        }
//    }
}
