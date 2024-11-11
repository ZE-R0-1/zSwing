//
//  DefaultNicknameRepository.swift
//  zSwing
//
//  Created by USER on 11/11/24.
//

import RxSwift
import FirebaseAuth
import FirebaseFirestore

class DefaultNicknameRepository: NicknameRepository {
    private let firestore: Firestore
    private let auth: Auth
    
    init(firestore: Firestore = Firestore.firestore(), auth: Auth = Auth.auth()) {
        self.firestore = firestore
        self.auth = auth
    }
    
    func saveNickname(_ nickname: String) -> Observable<Result<Void, Error>> {
        return Observable.create { [weak self] observer in
            guard let self = self,
                  let uid = self.auth.currentUser?.uid,
                  let email = self.auth.currentUser?.email else {
                observer.onNext(.failure(AuthError.userNotFound))
                observer.onCompleted()
                return Disposables.create()
            }
            
            let userRef = self.firestore.collection("users").document(uid)
            userRef.getDocument { document, error in
                if let error = error {
                    observer.onNext(.failure(error))
                    observer.onCompleted()
                    return
                }
                
                var userData: [String: Any] = [
                    "nickname": nickname,
                    "lastAccessDate": FieldValue.serverTimestamp()
                ]
                
                if document?.exists != true {
                    // 새 사용자인 경우 추가 정보 설정
                    userData["email"] = email
                    userData["createdAt"] = FieldValue.serverTimestamp()
                }
                
                userRef.setData(userData, merge: true) { error in
                    if let error = error {
                        observer.onNext(.failure(error))
                    } else {
                        observer.onNext(.success(()))
                    }
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    func checkNicknameExists() -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let uid = self?.auth.currentUser?.uid else {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }
            
            self?.firestore.collection("users").document(uid).getDocument { document, error in
                if let document = document,
                   document.exists,
                   document.data()?["nickname"] as? String != nil {
                    observer.onNext(true)
                } else {
                    observer.onNext(false)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}
