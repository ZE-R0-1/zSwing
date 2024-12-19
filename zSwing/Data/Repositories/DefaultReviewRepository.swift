//
//  DefaultReviewRepository.swift
//  zSwing
//
//  Created by USER on 12/16/24.
//

import RxSwift
import FirebaseFirestore
import FirebaseAuth

final class DefaultReviewRepository: ReviewRepository {
    private let db: Firestore
    private let auth: Auth
    
    init(db: Firestore = Firestore.firestore(), auth: Auth = Auth.auth()) {
        self.db = db
        self.auth = auth
    }
    
    func createReview(review: Review) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            print("Repository - Attempting to create review")
            guard let self = self,
                  let currentUserId = self.auth.currentUser?.uid else {
                print("Repository - No user logged in")
                observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
                return Disposables.create()
            }
            
            print("Repository - Creating review with data:")
            print("PlaygroundId:", review.playgroundId)
            print("Content:", review.content)
            print("Rating:", review.rating)
            
            // Get user data
            self.auth.currentUser?.reload()
            let userName = self.auth.currentUser?.displayName ?? "Anonymous"
            
            let reviewRef = self.db.collection("reviews").document()
            
            let reviewData: [String: Any] = [
                "id": reviewRef.documentID,
                "playgroundId": review.playgroundId,
                "userId": currentUserId,
                "content": review.content,
                "rating": review.rating,
                "imageUrls": review.imageUrls,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp(),
                "likeCount": 0,
                "userName": userName
            ]
            
            print("Repository - Saving review data:", reviewData)
            
            reviewRef.setData(reviewData) { error in
                if let error = error {
                    print("Repository - Error saving review:", error.localizedDescription)
                    observer.onError(error)
                } else {
                    print("Repository - Review successfully saved with ID:", reviewRef.documentID)
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    func fetchReviews(
        playgroundId: String,
        sortBy: ReviewSortOption,
        page: Int,
        pageSize: Int
    ) -> Observable<[Review]> {
        return Observable.create { [weak self] observer in
            print("Repository - Fetching reviews for playground:", playgroundId)
            
            guard let self = self else { return Disposables.create() }
            
            // 기본 쿼리 생성
            var query = self.db.collection("reviews")
                .whereField("playgroundId", isEqualTo: playgroundId)
            
            // 정렬 옵션 적용
            switch sortBy {
            case .latest:
                query = query.order(by: "createdAt", descending: true)
            case .rating:
                query = query.order(by: "rating", descending: true)
            }
            
            // 페이지네이션 적용 (offset 방식으로 변경)
            query = query.limit(to: pageSize)
            
            print("Repository - Executing query for reviews")
            
            query.getDocuments { snapshot, error in
                if let error = error {
                    print("Repository - Error fetching reviews:", error.localizedDescription)
                    observer.onError(error)
                    return
                }
                
                print("Repository - Retrieved documents count:", snapshot?.documents.count ?? 0)
                
                let reviews = snapshot?.documents.compactMap { document -> Review? in
                    print("Repository - Processing document:", document.documentID)
                    
                    let data = document.data()
                    print("Repository - Document data:", data)
                    
                    return Review(
                        id: document.documentID,
                        playgroundId: data["playgroundId"] as? String ?? "",
                        userId: data["userId"] as? String ?? "",
                        content: data["content"] as? String ?? "",
                        rating: data["rating"] as? Double ?? 0.0,
                        imageUrls: data["imageUrls"] as? [String] ?? [],
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                        likeCount: data["likeCount"] as? Int ?? 0,
                        isLiked: false,
                        userName: data["userName"] as? String ?? "",
                        userProfileUrl: data["userProfileUrl"] as? String
                    )
                } ?? []
                
                print("Repository - Final processed reviews count:", reviews.count)
                observer.onNext(reviews)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func updateReview(review: Review) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self,
                  let currentUserId = self.auth.currentUser?.uid else {
                observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
                return Disposables.create()
            }
            
            let reviewRef = self.db.collection("reviews").document(review.id)
            
            // 작성자 확인
            reviewRef.getDocument { document, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                guard let document = document,
                      let userId = document.data()?["userId"] as? String,
                      userId == currentUserId else {
                    observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Permission denied"]))
                    return
                }
                
                // 리뷰 업데이트
                let updateData: [String: Any] = [
                    "content": review.content,
                    "rating": review.rating,
                    "imageUrls": review.imageUrls,
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                
                reviewRef.updateData(updateData) { error in
                    if let error = error {
                        observer.onError(error)
                    } else {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    func deleteReview(reviewId: String) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self,
                  let currentUserId = self.auth.currentUser?.uid else {
                observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
                return Disposables.create()
            }
            
            let reviewRef = self.db.collection("reviews").document(reviewId)
            
            // 작성자 확인 후 삭제
            reviewRef.getDocument { document, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                guard let document = document,
                      let userId = document.data()?["userId"] as? String,
                      userId == currentUserId else {
                    observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Permission denied"]))
                    return
                }
                
                reviewRef.delete { error in
                    if let error = error {
                        observer.onError(error)
                    } else {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    func toggleLike(reviewId: String) -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let self = self,
                  let currentUserId = self.auth.currentUser?.uid else {
                observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
                return Disposables.create()
            }
            
            let reviewRef = self.db.collection("reviews").document(reviewId)
            let likeRef = reviewRef.collection("likes").document(currentUserId)
            
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                let reviewDocument: DocumentSnapshot
                do {
                    try reviewDocument = transaction.getDocument(reviewRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                let likeDocument: DocumentSnapshot
                do {
                    try likeDocument = transaction.getDocument(likeRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                let currentLikeCount = reviewDocument.data()?["likeCount"] as? Int ?? 0
                let isLiked = likeDocument.exists
                
                if isLiked {
                    // 좋아요 취소
                    transaction.deleteDocument(likeRef)
                    transaction.updateData(["likeCount": currentLikeCount - 1], forDocument: reviewRef)
                    return false
                } else {
                    // 좋아요 추가
                    transaction.setData([:], forDocument: likeRef)
                    transaction.updateData(["likeCount": currentLikeCount + 1], forDocument: reviewRef)
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
