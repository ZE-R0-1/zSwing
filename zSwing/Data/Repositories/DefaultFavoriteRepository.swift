//
//  DefaultFavoriteRepository.swift
//  zSwing
//
//  Created by USER on 12/16/24.
//

import RxSwift
import Firebase
import FirebaseAuth

final class DefaultFavoriteRepository: FavoriteRepository {
    private let firestore: Firestore
    private let firebaseAuth: Auth
    
    init(firestore: Firestore = Firestore.firestore(), auth: Auth = Auth.auth()) {
        self.firestore = firestore
        self.firebaseAuth = auth
    }
    
    func isFavorite(playgroundId: String) -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let userId = self?.firebaseAuth.currentUser?.uid else {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }
            
            let docRef = self?.firestore.collection("users")
                .document(userId)
                .collection("favorites")
                .document(playgroundId)
            
            docRef?.getDocument { snapshot, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                observer.onNext(snapshot?.exists ?? false)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func toggleFavorite(playgroundId: String) -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let userId = self?.firebaseAuth.currentUser?.uid else {
                observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
                return Disposables.create()
            }
            
            let docRef = self?.firestore.collection("users")
                .document(userId)
                .collection("favorites")
                .document(playgroundId)
            
            docRef?.getDocument { snapshot, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                if snapshot?.exists == true {
                    docRef?.delete { error in
                        if let error = error {
                            observer.onError(error)
                        } else {
                            observer.onNext(false)
                            observer.onCompleted()
                        }
                    }
                } else {
                    docRef?.setData([:]) { error in
                        if let error = error {
                            observer.onError(error)
                        } else {
                            observer.onNext(true)
                            observer.onCompleted()
                        }
                    }
                }
            }
            
            return Disposables.create()
        }
    }
}
