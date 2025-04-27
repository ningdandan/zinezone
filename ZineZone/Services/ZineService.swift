import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class ZineService {
    private static let db = Firestore.firestore()
    
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

    static func createZine(zineId: String, title: String, description: String, coverUrl: String, completion: ((Error?) -> Void)? = nil) {
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
            "type": "digital",
            "link": ""
        ]
        
        Firestore.firestore().collection("zines").document(zineId).setData(data) { error in
            completion?(error)
        }
    }

    
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
}
