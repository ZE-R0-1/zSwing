//
//  DefaultProfileRepository.swift
//  zSwing
//
//  Created by USER on 11/7/24.
//

import RxSwift
import FirebaseAuth
import FirebaseFirestore
import KakaoSDKUser
import GoogleSignIn

class DefaultProfileRepository: ProfileRepository {
    // MARK: - Dependencies
    private let firebaseAuthService: FirebaseAuthServiceProtocol
    private let firestore: Firestore
    
    // MARK: - Initialization
    init(firebaseAuthService: FirebaseAuthServiceProtocol = FirebaseAuthService(),
         firestore: Firestore = Firestore.firestore()) {
        self.firebaseAuthService = firebaseAuthService
        self.firestore = firestore
    }
    
    // MARK: - ProfileRepository Implementation
    func getCurrentUser() -> Observable<Result<User, Error>> {
        return firebaseAuthService.getCurrentUser()
            .map { user -> Result<User, Error> in
                if let user = user {
                    return .success(user)
                } else {
                    return .failure(AuthError.userNotFound)
                }
            }
    }
    
    func logout() -> Observable<Result<Void, Error>> {
        print("🔄 Starting logout process")
        return Observable.create { [weak self] observer in
            guard let self = self else {
                print("❌ Self is nil in logout")
                observer.onNext(.failure(AuthError.unknown))
                observer.onCompleted()
                return Disposables.create()
            }
            
            print("🔍 About to call getCurrentLoginMethod")
            let disposable = self.getCurrentLoginMethod()
                .debug("Login Method Stream")
                .subscribe(onNext: { result in
                    print("✅ Received login method result: \(result)")
                    switch result {
                    case .success(let method):
                        print("📱 Processing logout for method: \(method)")
                        switch method {
                        case .google:
                            print("🔵 Starting Google logout")
                            self.handleGoogleLogout(observer: observer)
                        case .kakao:
                            print("🟡 Starting Kakao logout")
                            self.handleKakaoLogout(observer: observer)
                        case .apple:
                            print("⚪️ Starting Apple logout")
                            self.handleFirebaseLogout(observer: observer)
                        }
                    case .failure(let error):
                        print("❌ Login method error: \(error)")
                        observer.onNext(.failure(error))
                        observer.onCompleted()
                    }
                }, onError: { error in
                    print("❌ getCurrentLoginMethod error: \(error)")
                    observer.onNext(.failure(error))
                    observer.onCompleted()
                }, onCompleted: {
                    print("✅ getCurrentLoginMethod completed")
                })
            
            return Disposables.create {
                print("🔄 Disposing logout stream")
                disposable.dispose()
            }
        }
    }

    func withdraw() -> Observable<Result<Void, Error>> {
        print("🔄 Starting withdrawal process")
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(.failure(AuthError.unknown))
                observer.onCompleted()
                return Disposables.create()
            }
            
            let disposable = self.getCurrentLoginMethod()
                .flatMap { result -> Observable<Result<Void, Error>> in
                    switch result {
                    case .success(let method):
                        print("📱 Processing withdrawal for method: \(method)")
                        switch method {
                        case .google:
                            print("🔵 Starting Google withdrawal")
                            GIDSignIn.sharedInstance.signOut()
                            print("🔵 Google SignIn signOut completed")
                            // Firebase 계정 삭제로 직접 진행
                            return self.handleFirebaseWithdrawal()
                        case .kakao:
                            return self.handleKakaoWithdrawal()
                        case .apple:
                            return self.handleFirebaseWithdrawal()
                        }
                    case .failure(let error):
                        return .just(.failure(error))
                    }
                }
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { result in
                    observer.onNext(result)
                }, onError: { error in
                    observer.onNext(.failure(error))
                    observer.onCompleted()
                }, onCompleted: {
                    observer.onCompleted()
                })
            
            return Disposables.create {
                disposable.dispose()
            }
        }
    }
    
    // MARK: - Private Helper Methods
    private func getCurrentLoginMethod() -> Observable<Result<LoginMethod, Error>> {
        print("🟡 getCurrentLoginMethod started")
        return Observable.create { [weak self] observer in
            print("🟡 Inside Observable.create")
            
            guard let uid = Auth.auth().currentUser?.uid else {
                print("❌ No current user")
                observer.onNext(.failure(AuthError.userNotFound))
                observer.onCompleted()
                return Disposables.create()
            }
            print("🟡 Current UID: \(uid)")
            
            self?.firestore.collection("users").document(uid).getDocument { document, error in
                print("🟡 Firestore callback received")
                
                if let error = error {
                    print("❌ Firestore error: \(error)")
                    observer.onNext(.failure(error))
                    observer.onCompleted()
                    return
                }
                
                print("🟡 Document data: \(String(describing: document?.data()))")
                
                if let method = document?.data()?["loginMethod"] as? String,
                   let loginMethod = LoginMethod(rawValue: method.lowercased()) {
                    print("✅ Found login method: \(loginMethod)")
                    observer.onNext(.success(loginMethod))
                } else {
                    print("❌ Login method not found or invalid")
                    observer.onNext(.failure(AuthError.unknown))
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    // MARK: - Withdrawal Handlers
    private func handleKakaoWithdrawal() -> Observable<Result<Void, Error>> {
        return Observable.create { [weak self] observer in
            print("🟡 Starting Kakao account withdrawal")
            
            // DisposeBag 생성
            var disposeBag = DisposeBag()
            
            UserApi.shared.unlink { [weak self] error in
                if let error = error {
                    print("❌ Kakao unlink error: \(error)")
                    observer.onNext(.failure(error))
                    observer.onCompleted()
                } else {
                    print("✅ Kakao unlink successful")
                    guard let self = self else {
                        observer.onNext(.failure(AuthError.unknown))
                        observer.onCompleted()
                        return
                    }
                    // Firebase 계정 삭제 진행
                    self.handleFirebaseWithdrawal()
                        .subscribe(onNext: { result in
                            observer.onNext(result)
                        }, onCompleted: {
                            observer.onCompleted()
                        })
                        .disposed(by: disposeBag)
                }
            }
            
            return Disposables.create {
                print("🗑 Cleaning up Kakao withdrawal resources")
                disposeBag = DisposeBag()  // 새로운 DisposeBag을 할당하여 이전 구독들을 정리
            }
        }
    }

    private func handleGoogleWithdrawal() -> Observable<Result<Void, Error>> {
        return Observable.create { [weak self] observer in
            print("🔵 Starting Google account withdrawal")
            
            var disposeBag = DisposeBag()
            
            // Google 로그아웃
            GIDSignIn.sharedInstance.signOut()
            print("🔵 Google SignIn signOut completed")
            
            guard let self = self else {
                observer.onNext(.failure(AuthError.unknown))
                observer.onCompleted()
                return Disposables.create()
            }
            
            // Firebase 계정 삭제 진행
            self.handleFirebaseWithdrawal()
                .subscribe(onNext: { result in
                    observer.onNext(result)
                }, onCompleted: {
                    observer.onCompleted()
                })
                .disposed(by: disposeBag)
            
            return Disposables.create {
                print("🗑 Cleaning up Google withdrawal resources")
                disposeBag = DisposeBag()  // 새로운 DisposeBag을 할당하여 이전 구독들을 정리
            }
        }
    }
    private func handleFirebaseWithdrawal() -> Observable<Result<Void, Error>> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(.failure(AuthError.unknown))
                observer.onCompleted()
                return Disposables.create()
            }
            
            guard let firebaseUser = Auth.auth().currentUser else {
                observer.onNext(.failure(AuthError.userNotFound))
                observer.onCompleted()
                return Disposables.create()
            }
            
            print("🔥 Starting Firebase account deletion")
            print("🔍 Current user UID: \(firebaseUser.uid)")
            print("📝 Starting deletion process")
            
            let disposable = self.deleteUserData(userId: firebaseUser.uid)
                .flatMap { [weak self] _ -> Observable<Void> in
                    guard let self = self else { return .empty() }
                    return self.deleteFirebaseUser(firebaseUser: firebaseUser)
                }
                .subscribe(
                    onNext: { _ in
                        print("✅ Complete user deletion successful")
                        observer.onNext(.success(()))
                    },
                    onError: { error in
                        print("❌ Error during user deletion: \(error)")
                        observer.onNext(.failure(error))
                    },
                    onCompleted: {
                        observer.onCompleted()
                    }
                )
            
            return Disposables.create {
                disposable.dispose()
            }
        }
    }
    
    private func deleteUserData(userId: String) -> Observable<Void> {
        print("📁 Starting Firestore data deletion")
        return Observable.create { [weak self] observer in
            guard let self = self else {
                print("❌ Self is nil in deleteUserData")
                return Disposables.create()
            }
            
            print("🗑 Creating batch delete")
            let batch = self.firestore.batch()
            let userRef = self.firestore.collection("users").document(userId)
            batch.deleteDocument(userRef)
            
            print("🚀 Committing batch delete")
            batch.commit { error in
                if let error = error {
                    print("❌ Firestore data deletion error: \(error)")
                    observer.onError(error)
                } else {
                    print("✅ Firestore data successfully deleted")
                    observer.onNext(())
                    observer.onCompleted()  // 이 부분이 호출되는지 확인
                }
            }
            
            return Disposables.create()
        }
    }
    private func deleteFirebaseUser(firebaseUser: FirebaseAuth.User) -> Observable<Void> {
        print("🔥 Starting Firebase Authentication account deletion")
        return Observable.create { observer in
            // 현재 사용자 재확인
            guard let currentUser = Auth.auth().currentUser,
                  currentUser.uid == firebaseUser.uid else {
                print("❌ Current user mismatch or not found")
                observer.onError(AuthError.userNotFound)
                return Disposables.create()
            }
            
            print("🔄 Attempting to delete user: \(currentUser.uid)")
            
            // 사용자 삭제 수행
            currentUser.delete { error in
                if let error = error {
                    print("❌ Firebase Authentication deletion error: \(error.localizedDescription)")
                    
                    // 특정 에러 타입 체크
                    let authError = error as NSError
                    if authError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                        print("⚠️ Requires recent login")
                        observer.onError(AuthError.invalidCredentials)
                    } else {
                        observer.onError(error)
                    }
                } else {
                    print("✅ Firebase Authentication user successfully deleted")
                    observer.onNext(())
                    observer.onCompleted()  // 이 부분이 중요합니다
                }
            }
            
            return Disposables.create()
        }
    }
        
    // MARK: - Logout Handlers
    private func handleKakaoLogout(observer: AnyObserver<Result<Void, Error>>) {
        print("Handling Kakao logout")
        UserApi.shared.logout { [weak self] error in
            if let error = error {
                print("Kakao logout error: \(error)")
                observer.onNext(.failure(error))
                observer.onCompleted()
            } else {
                print("Kakao logout successful")
                self?.handleFirebaseLogout(observer: observer)
            }
        }
    }
    
    private func handleGoogleLogout(observer: AnyObserver<Result<Void, Error>>) {
        print("🔵 Inside handleGoogleLogout")
        GIDSignIn.sharedInstance.signOut()
        print("🔵 Google SignIn signOut called")
        handleFirebaseLogout(observer: observer)
    }

    private func handleFirebaseLogout(observer: AnyObserver<Result<Void, Error>>) {
        print("🔥 Starting Firebase logout")
        let disposable = firebaseAuthService.signOut()
            .debug("Firebase Logout Stream")
            .subscribe(onNext: { _ in
                print("✅ Firebase logout successful")
                observer.onNext(.success(()))
                observer.onCompleted()
            }, onError: { error in
                print("❌ Firebase logout error: \(error)")
                observer.onNext(.failure(error))
                observer.onCompleted()
            })
        
        disposable.disposed(by: DisposeBag())
        print("🔥 Firebase logout disposable set")
    }
}
