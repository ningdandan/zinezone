import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class ZineService {
    private static let db = Firestore.firestore()
    
    // MARK: - Zine related Services
    static func createZine(zineId: String, title: String, description: String, coverUrl: String, pages: Int, publishedAt: Date, tags: [String], completion: ((Error?) -> Void)? = nil) {
        guard let user = Auth.auth().currentUser else {
            completion?(NSError(domain: "NoUser", code: 0))
            return
        }
        
        let data: [String: Any] = [
            "title": title,
            "description": description,
            "coverImageUrl": coverUrl,
            "artistId": user.uid,
            "createdAt": FieldValue.serverTimestamp(),
            "pages": pages,
            "publishedAt": Timestamp(date: publishedAt),
            "tags": tags,
            "type": "digital",
            "link": ""
        ]
        
        Firestore.firestore().collection("zines").document(zineId).setData(data) { error in
            completion?(error)
        }
    }
    /// 获取所有zines（按时间倒序）
    static func fetchAllZines(completion: @escaping ([Zine]) -> Void) {
        db.collection("zines")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching all zines: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                if let documents = snapshot?.documents {
                    let zines = documents.compactMap { try? $0.data(as: Zine.self) }
                    completion(zines)
                } else {
                    completion([])
                }
            }
    }
    static func uploadZineCover(image: UIImage, completion: @escaping (Result<(zineId: String, coverUrl: String), Error>) -> Void) {
        let zineId = UUID().uuidString
        let storageRef = Storage.storage().reference().child("zine-covers/\(zineId).jpg")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "InvalidImageData", code: 0)))
            return
        }
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let url = url {
                    completion(.success((zineId: zineId, coverUrl: url.absoluteString)))
                } else if let error = error {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // 保存zine
    static func saveZine(zineId: String, completion: ((Error?) -> Void)? = nil) {
        guard let userRef = userDocument() else {
            completion?(NSError(domain: "NoUser", code: 0))
            return
        }
        
        userRef.updateData([
            "savedZines": FieldValue.arrayUnion([zineId])
        ]) { error in
            if error == nil {
                notifySavedZinesUpdated()
            }
            completion?(error)
        }
    }
    
    /// 拉取当前用户收藏的zines
    static func fetchSavedZines(completion: @escaping ([Zine]) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            completion([])
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let data = snapshot?.data(),
                  let savedZineIds = data["savedZines"] as? [String],
                  !savedZineIds.isEmpty else {
                completion([])
                return
            }
            
            // 有收藏的zineId，批量拉取对应的zine文档
            db.collection("zines")
                .whereField(FieldPath.documentID(), in: savedZineIds)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error fetching saved zines: \(error.localizedDescription)")
                        completion([])
                        return
                    }
                    
                    if let documents = snapshot?.documents {
                        let zines = documents.compactMap { try? $0.data(as: Zine.self) }
                        completion(zines)
                    } else {
                        completion([])
                    }
                }
        }
    }
    
    // MARK: - Flower Services
    
    /// 给Zine献花并留言
    static func giveFlower(toZineId: String, assetsType: Int = 1, message: String, completion: ((Error?) -> Void)? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion?(NSError(domain: "NoUser", code: 0))
            return
        }
        
        // First get the artistId from the zine
        db.collection("zines").document(toZineId).getDocument { snapshot, error in
            if let error = error {
                completion?(error)
                return
            }
            
            guard let data = snapshot?.data(), let artistId = data["artistId"] as? String else {
                completion?(NSError(domain: "InvalidZine", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find zine artist"]))
                return
            }
            
            let flowerData: [String: Any] = [
                "fromUserId": userId,
                "toZineId": toZineId,
                "toUserId": artistId,
                "assetsType": assetsType,
                "message": message,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            let flowerRef = db.collection("flowers").document()
            
            flowerRef.setData(flowerData) { error in
                completion?(error)
            }
        }
    }
    
    /// 获取指定Zine的所有花和留言（按时间倒序）
    static func fetchFlowers(forZineId: String, completion: @escaping ([Flower]) -> Void) {
        db.collection("flowers")
            .whereField("toZineId", isEqualTo: forZineId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching flowers: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                if let documents = snapshot?.documents {
                    let flowers = documents.compactMap { try? $0.data(as: Flower.self) }
                    completion(flowers)
                } else {
                    completion([])
                }
            }
    }
    
    /// 获取指定用户收到的所有花和留言（按时间倒序）
    static func fetchFlowersByUserId(userId: String, completion: @escaping ([Flower]) -> Void) {
        db.collection("flowers")
            .whereField("toUserId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching flowers for user: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                if let documents = snapshot?.documents {
                    let flowers = documents.compactMap { try? $0.data(as: Flower.self) }
                    completion(flowers)
                } else {
                    completion([])
                }
            }
    }
    
    // MARK: - User related Services
    
    /// 获取当前用户上传的zines
    static func fetchUploadedZines(completion: @escaping ([Zine]) -> Void) {
        guard let userId = getCurrentUserId() else {
            completion([])
            return
        }
        
        db.collection("zines")
            .whereField("artistId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    let zines = documents.compactMap { try? $0.data(as: Zine.self) }
                    completion(zines)
                } else {
                    completion([])
                }
            }
    }


    static func updateUserProfile(profile: UserProfile, completion: ((Error?) -> Void)? = nil) {
        guard let userRef = userDocument() else {
            completion?(NSError(domain: "NoUser", code: 0))
            return
        }
        
        do {
            try userRef.setData(from: profile, merge: true) { error in
                completion?(error)
            }
        } catch {
            completion?(error)
        }
    }
    
    static func uploadAvatar(imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            //print("DEBUG: No user logged in")
            completion(.failure(NSError(domain: "NoUser", code: 0)))
            return
        }
        
        //print("DEBUG: Current User ID: \(userId)")
        
        let storageRef = Storage.storage().reference()
        let avatarPath = "avatars/\(userId).jpg"
        //print("DEBUG: Avatar upload path: \(avatarPath)")
        
        let avatarRef = storageRef.child(avatarPath)
        
        avatarRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                //print("DEBUG: Failed uploading data: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            avatarRef.downloadURL { url, error in
                if let url = url {
                    print("DEBUG: Uploaded avatar URL: \(url.absoluteString)")
                    completion(.success(url.absoluteString))
                } else if let error = error {
                    print("DEBUG: Failed getting download URL: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }


    //fetch自己的
    static func fetchUserProfile(completion: @escaping (UserProfile?) -> Void) {
        guard let userRef = userDocument() else {
            completion(nil)
            return
        }
        
        userRef.getDocument { snapshot, error in
            if let snapshot = snapshot {
                let profile = try? snapshot.data(as: UserProfile.self)
                completion(profile)
            } else {
                completion(nil)
            }
        }
    }
    
    // 新增，根据传入userId去拉别人的profile
    static func fetchUserProfile(userId: String, completion: @escaping (UserProfile?) -> Void) {
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        userRef.getDocument { snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                let profile = try? snapshot.data(as: UserProfile.self)
                completion(profile)
            } else {
                completion(nil)
            }
        }
    }
    
    static func fetchUploadedZines(userId: String, completion: @escaping ([Zine]) -> Void) {
        db.collection("zines")
            .whereField("artistId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    let zines = documents.compactMap { try? $0.data(as: Zine.self) }
                    completion(zines)
                } else {
                    completion([])
                }
            }
    }

    //取消保存
    static func unsaveZine(zineId: String, completion: ((Error?) -> Void)? = nil) {
        guard let userRef = userDocument() else {
            completion?(NSError(domain: "NoUser", code: 0))
            return
        }
        
        userRef.updateData([
            "savedZines": FieldValue.arrayRemove([zineId])
        ]) { error in
            if error == nil {
                notifySavedZinesUpdated()
            }
            completion?(error)
        }
    }
    
    static func isZineSaved(zineId: String, completion: @escaping (Bool) -> Void) {
            guard let userId = Auth.auth().currentUser?.uid else {
                print("No user logged in")
                completion(false)
                return
            }
            
            db.collection("users").document(userId).getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching user document: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let data = snapshot?.data(),
                   let savedZines = data["savedZines"] as? [String] {
                    completion(savedZines.contains(zineId))
                } else {
                    completion(false)
                }
            }
        }
    // MARK: - FirestoreHelper
    
    private static func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }

    private static func userDocument() -> DocumentReference? {
        guard let userId = getCurrentUserId() else { return nil }
        return db.collection("users").document(userId)
    }

    private static func notifySavedZinesUpdated() {
        NotificationCenter.default.post(name: .savedZinesUpdated, object: nil)
    }
    
    // MARK: - Zine Deletion
    
    /// 删除指定的Zine（仅允许作者删除）
    static func deleteZine(zineId: String, completion: ((Error?) -> Void)? = nil) {
        // First verify the current user is the artist
        guard let currentUserId = getCurrentUserId() else {
            completion?(NSError(domain: "NoUser", code: 0))
            return
        }
        
        let zineRef = db.collection("zines").document(zineId)
        
        zineRef.getDocument { snapshot, error in
            if let error = error {
                completion?(error)
                return
            }
            
            guard let data = snapshot?.data(),
                  let artistId = data["artistId"] as? String,
                  artistId == currentUserId else {
                completion?(NSError(domain: "Unauthorized", code: 403, userInfo: [NSLocalizedDescriptionKey: "Only the creator can delete this zine"]))
                return
            }
            
            // Delete the zine document
            zineRef.delete { error in
                if let error = error {
                    completion?(error)
                    return
                }
                
                // Also delete the zine cover from storage
                if let coverImageUrl = data["coverImageUrl"] as? String,
                   let url = URL(string: coverImageUrl),
                   url.pathComponents.count > 1 {
                    let storageRef = Storage.storage().reference(withPath: "zine-covers/\(zineId).jpg")
                    storageRef.delete { error in
                        // We don't fail the operation if deleting the image fails
                        if let error = error {
                            print("Warning: Failed to delete zine cover: \(error.localizedDescription)")
                        }
                    }
                }
                
                // Also remove references to this zine from users' saved collections
                // This is a maintenance operation and doesn't affect the success of the deletion
                db.collection("users").whereField("savedZines", arrayContains: zineId)
                    .getDocuments { snapshot, error in
                        if let documents = snapshot?.documents {
                            let batch = db.batch()
                            for document in documents {
                                batch.updateData([
                                    "savedZines": FieldValue.arrayRemove([zineId])
                                ], forDocument: document.reference)
                            }
                            batch.commit()
                        }
                    }
                
                completion?(nil)
            }
        }
    }
}
