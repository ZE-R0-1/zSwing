//
//  FirebaseAuthService.swift
//  zSwing
//
//  Created by USER on 11/5/24.
//

import RxSwift
import FirebaseAuth
import FirebaseFirestore

protocol FirebaseAuthServiceProtocol {
    func getCurrentUser() -> Observable<User?>
    func signOut() -> Observable<Void>
    func updateLastAccessDate(for userId: String) -> Observable<Void>
}

class FirebaseAuthService: FirebaseAuthServiceProtocol {
    private let auth: Auth
    private let firestore: Firestore
    
    init(auth: Auth = Auth.auth(), firestore: Firestore = Firestore.firestore()) {
        print("Initializing FirebaseAuthService")
        self.auth = auth
        self.firestore = firestore
        print("Current Auth User: \(auth.currentUser?.uid ?? "No User")")
        print("Firestore instance created: \(firestore)")
    }
    
    func getCurrentUser() -> Observable<User?> {
        return Observable.create { [weak self] observer in
            if let currentUser = self?.auth.currentUser {
                print("Firebase Auth User Found - UID: \(currentUser.uid)")
                
                self?.firestore.collection("users").document(currentUser.uid).getDocument { document, error in
                    if let error = error {
                        print("Firestore Error: \(error)")
                        observer.onError(error)
                        return
                    }
                    
                    if let document = document, document.exists {
                        print("Document Data: \(document.data() ?? [:])")  // 실제 데이터 확인
                        
                        do {
                            let userDTO = try document.data(as: UserDTO.self)
                            print("Successfully decoded UserDTO: \(userDTO)")
                            observer.onNext(userDTO.toDomain())
                        } catch {
                            print("Decoding Error: \(error)")  // 디코딩 에러 상세 확인
                            // 임시 해결책: 수동으로 User 객체 생성
                            if let data = document.data() {
                                print("Attempting manual decode...")
                                let user = User(
                                    id: currentUser.uid,
                                    email: data["email"] as? String ?? "",
                                    loginMethod: LoginMethod(rawValue: data["loginMethod"] as? String ?? "kakao") ?? .kakao
                                )
                                observer.onNext(user)
                            } else {
                                observer.onNext(nil)
                            }
                        }
                    } else {
                        print("No document exists for user: \(currentUser.uid)")
                        observer.onNext(nil)
                    }
                    observer.onCompleted()
                }
            } else {
                print("No Firebase Auth User")
                observer.onNext(nil)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    
    func signOut() -> Observable<Void> {
        return Observable.create { [weak self] observer in
            print("FirebaseAuthService: Attempting to sign out")
            do {
                try self?.auth.signOut()
                print("FirebaseAuthService: Sign out successful")
                observer.onNext(())
                observer.onCompleted()
            } catch let error {
                print("FirebaseAuthService: Sign out failed with error: \(error)")
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    
    func updateLastAccessDate(for userId: String) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            self?.firestore.collection("users").document(userId).updateData([
                "lastAccessDate": FieldValue.serverTimestamp()
            ]) { error in
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
