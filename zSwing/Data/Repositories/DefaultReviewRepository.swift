//
//  DefaultReviewRepository.swift
//  zSwing
//
//  Created by USER on 12/16/24.
//

import RxSwift
import Firebase

final class DefaultReviewRepository: ReviewRepository {
    private let firestore: Firestore
    
    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }
    
    func getReviews(playgroundId: String) -> Observable<[PlaygroundReview]> {
        return Observable.create { [weak self] observer in
            self?.firestore.collection("playgrounds")
                .document(playgroundId)
                .collection("reviews")
                .order(by: "createdAt", descending: true)
                .getDocuments { snapshot, error in
                    if let error = error {
                        observer.onError(error)
                        return
                    }
                    
                    let reviews = snapshot?.documents.compactMap { document -> PlaygroundReview? in
                        guard let imageUrl = document.data()["imageUrl"] as? String,
                              let timestamp = document.data()["createdAt"] as? Timestamp else {
                            return nil
                        }
                        
                        return PlaygroundReview(
                            id: document.documentID,
                            imageUrl: imageUrl,
                            createdAt: timestamp.dateValue()
                        )
                    } ?? []
                    
                    observer.onNext(reviews)
                    observer.onCompleted()
                }
            
            return Disposables.create()
        }
    }
    
    func writeReview(playgroundId: String, review: PlaygroundReview) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            let data: [String: Any] = [
                "imageUrl": review.imageUrl,
                "createdAt": Timestamp(date: review.createdAt)
            ]
            
            self?.firestore.collection("playgrounds")
                .document(playgroundId)
                .collection("reviews")
                .document(review.id)
                .setData(data) { error in
                    if let error = error {
                        observer.onError(error)
                    } else {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                }
            
            return Disposables.create()
        }
    }
}
