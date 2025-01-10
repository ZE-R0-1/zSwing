//
//  DefaultPostRepository.swift
//  zSwing
//
//  Created by USER on 1/10/25.
//

import Foundation
import RxSwift
import FirebaseFirestore
import FirebaseAuth

final class DefaultPostRepository: PostRepository {
    private let db: Firestore
    private let auth: Auth
    
    init(db: Firestore = Firestore.firestore(), auth: Auth = Auth.auth()) {
        self.db = db
        self.auth = auth
    }
    
    func fetchPosts(page: Int, pageSize: Int) -> Observable<[Post]> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            let query = self.db.collection("reviews")
                .order(by: "createdAt", descending: true)
                .limit(to: pageSize)
            
            query.getDocuments { snapshot, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                let posts = snapshot?.documents.compactMap { document -> Post? in
                    let data = document.data()
                    
                    return Post(
                        id: document.documentID,
                        content: data["content"] as? String ?? "",
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        imageUrls: data["imageUrls"] as? [String] ?? [],
                        likeCount: data["likeCount"] as? Int ?? 0,
                        rating: data["rating"] as? Double ?? 0.0,
                        updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                        userId: data["userId"] as? String ?? "",
                        userName: data["userName"] as? String ?? "",
                        isLiked: false  // 초기값은 false로 설정
                    )
                } ?? []
                
                observer.onNext(posts)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func toggleLike(postId: String) -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let self = self,
                  let currentUserId = self.auth.currentUser?.uid else {
                observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
                return Disposables.create()
            }
            
            let postRef = self.db.collection("reviews").document(postId)
            let likeRef = postRef.collection("likes").document(currentUserId)
            
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                let postDocument: DocumentSnapshot
                let likeDocument: DocumentSnapshot
                
                do {
                    try postDocument = transaction.getDocument(postRef)
                    try likeDocument = transaction.getDocument(likeRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                let currentLikeCount = postDocument.data()?["likeCount"] as? Int ?? 0
                let isLiked = likeDocument.exists
                
                if isLiked {
                    transaction.deleteDocument(likeRef)
                    transaction.updateData(["likeCount": currentLikeCount - 1], forDocument: postRef)
                    return false
                } else {
                    transaction.setData([:], forDocument: likeRef)
                    transaction.updateData(["likeCount": currentLikeCount + 1], forDocument: postRef)
                    return true
                }
            }) { (result, error) in
                if let error = error {
                    observer.onError(error)
                } else if let isLiked = result as? Bool {
                    observer.onNext(isLiked)
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
}
