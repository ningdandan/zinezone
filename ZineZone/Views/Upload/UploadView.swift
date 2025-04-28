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
    @State private var isLoggedIn: Bool = Auth.auth().currentUser != nil
    @State private var pages: String = ""
    @State private var publishedAt: Date = Date()
    @State private var selectedTags: [String] = []
    @State private var tags: [Tag] = []
    @State private var hasFetchedTags = false
    
    private let storage = Storage.storage()
    private let db = Firestore.firestore()

    // Group tags by category
    var groupedTags: [String: [Tag]] {
        Dictionary(grouping: tags, by: { $0.category })
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoggedIn {
                        uploadContentView()
                    } else {
                        loginPromptView()
                    }
                }
                .padding()
                .onAppear {
                    isLoggedIn = Auth.auth().currentUser != nil
                    if !hasFetchedTags {
                            fetchTags()
                            hasFetchedTags = true
                        }
                }
            }
            .navigationTitle("发布Zine")
        }
    }
    
    // Fetch tags from Firestore
    private func fetchTags() {
        print("Starting to fetch tags...")
        db.collection("tags").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching tags: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents {
                print("Received \(documents.count) tag documents")
                for doc in documents {
                    print("Tag document: \(doc.documentID), data: \(doc.data())")
                }
                
                self.tags = documents.compactMap { doc -> Tag? in
                    do {
                        let tag = try doc.data(as: Tag.self)
                        print("Successfully parsed tag: \(tag.displayName)")
                        return tag
                    } catch {
                        print("Error parsing tag document \(doc.documentID): \(error)")
                        return nil
                    }
                }
                
                print("Final tags count: \(self.tags.count)")
                if self.tags.isEmpty {
                    // If no tags were parsed, create some default ones for testing
                    print("Creating default tags for testing")
                    self.createDefaultTags()
                }
            } else {
                print("No tag documents found")
                self.createDefaultTags()
            }
        }
    }
    
    // Create some default tags for testing if Firestore fetch fails
    private func createDefaultTags() {
        // Create sample tags for each category
        let now = Date()
        self.tags = [
            // Content Type
            Tag(id: "poetry", displayName: "Poetry", category: "Content Type", createdAt: now),
            Tag(id: "short_story", displayName: "Short Story", category: "Content Type", createdAt: now),
            Tag(id: "photography", displayName: "Photography", category: "Content Type", createdAt: now),
            
            // Theme
            Tag(id: "love", displayName: "Love", category: "Theme", createdAt: now),
            Tag(id: "nature", displayName: "Nature", category: "Theme", createdAt: now),
            Tag(id: "politics", displayName: "Politics", category: "Theme", createdAt: now),
            
            // Technique
            Tag(id: "digital", displayName: "Digital", category: "Technique", createdAt: now),
            Tag(id: "handmade", displayName: "Handmade", category: "Technique", createdAt: now),
            Tag(id: "collage", displayName: "Collage", category: "Technique", createdAt: now)
        ]
    }
    
    // MARK: - 已登录用户上传内容的视图
     private func uploadContentView() -> some View {
         VStack(spacing: 20) {
             NavigationLink(
                 destination: UploadSuccessView(),
                 isActive: $showSuccessPage,
                 label: { EmptyView() }
             )
             .hidden()
             
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
             
             TextField("标题", text: $title)
                 .textFieldStyle(RoundedBorderTextFieldStyle())
                 .padding(.horizontal)
             
             TextField("描述", text: $description)
                 .textFieldStyle(RoundedBorderTextFieldStyle())
                 .padding(.horizontal)
             
             TextField("页数", text: $pages)
                 .textFieldStyle(RoundedBorderTextFieldStyle())
                 .padding(.horizontal)
             
             DatePicker("出版日", selection: $publishedAt, displayedComponents: .date)
                 .padding(.horizontal)
             
             // Tag selection
             ForEach(groupedTags.keys.sorted(), id: \ .self) { category in
                 VStack(alignment: .leading) {
                     Text(category)
                         .font(.headline)
                         .padding(.top)
                     
                     ScrollView(.horizontal, showsIndicators: false) {
                         HStack {
                             ForEach(groupedTags[category] ?? [], id: \ .id) { tag in
                                 Button(action: {
                                     if selectedTags.contains(tag.id ?? "") {
                                         selectedTags.removeAll { $0 == tag.id }
                                     } else {
                                         selectedTags.append(tag.id ?? "")
                                     }
                                 }) {
                                     Text(tag.displayName)
                                         .padding(.horizontal)
                                         .padding(.vertical, 8)
                                         .background(selectedTags.contains(tag.id ?? "") ? Color.blue : Color.gray.opacity(0.2))
                                         .foregroundColor(selectedTags.contains(tag.id ?? "") ? .white : .black)
                                         .cornerRadius(20)
                                 }
                             }
                         }
                     }
                 }
             }
             
             Button(action: uploadZine) {
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
     }
     
     // MARK: - 未登录用户提示登录的视图
     private func loginPromptView() -> some View {
         VStack(spacing: 16) {
             Text("请登录后再上传内容")
                 .foregroundColor(.gray)
             
             Button(action: {
                 NotificationCenter.default.post(name: Notification.Name("NavigateToProfile"), object: nil)
             }) {
                 Text("前往登录")
                     .foregroundColor(.white)
                     .padding()
                     .frame(maxWidth: .infinity)
                     .background(Color.blue)
                     .cornerRadius(10)
             }
         }
         .padding()
     }
    
    // MARK: - 上传逻辑
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
                ZineService.createZine(zineId: zineId, title: title, description: description, coverUrl: coverUrl, pages: Int(self.pages) ?? 0, publishedAt: self.publishedAt, tags: self.selectedTags) { error in
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
        self.pages = ""
        self.publishedAt = Date()
        self.selectedTags = []
    }

}
