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
            print("🔍 Checking favorite status for playground:", playgroundId)
            
            guard let userId = self?.firebaseAuth.currentUser?.uid else {
                print("❌ No logged in user found")
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }
            
            print("👤 Current user ID:", userId)
            
            let docRef = self?.firestore.collection("users")
                .document(userId)
                .collection("favorites")
                .document(playgroundId)
            
            docRef?.getDocument { snapshot, error in
                if let error = error {
                    print("❌ Error checking favorite status:", error)
                    observer.onError(error)
                    return
                }
                
                let isFavorite = snapshot?.exists ?? false
                print("✅ Favorite status:", isFavorite)
                observer.onNext(isFavorite)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func toggleFavorite(playgroundId: String) -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            print("🔄 Toggling favorite for playground:", playgroundId)
            
            guard let userId = self?.firebaseAuth.currentUser?.uid else {
                print("❌ No logged in user found")
                observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
                return Disposables.create()
            }
            
            print("👤 Current user ID:", userId)
            
            let docRef = self?.firestore.collection("users")
                .document(userId)
                .collection("favorites")
                .document(playgroundId)
            
            docRef?.getDocument { snapshot, error in
                if let error = error {
                    print("❌ Error checking current favorite status:", error)
                    observer.onError(error)
                    return
                }
                
                if snapshot?.exists == true {
                    print("🗑 Removing from favorites")
                    docRef?.delete { error in
                        if let error = error {
                            print("❌ Error removing favorite:", error)
                            observer.onError(error)
                        } else {
                            print("✅ Successfully removed from favorites")
                            observer.onNext(false)
                            observer.onCompleted()
                        }
                    }
                } else {
                    print("➕ Adding to favorites")
                    docRef?.setData([:]) { error in
                        if let error = error {
                            print("❌ Error adding favorite:", error)
                            observer.onError(error)
                        } else {
                            print("✅ Successfully added to favorites")
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
