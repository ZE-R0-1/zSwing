//
//  DefaultAuthenticationRepository.swift
//  zSwing
//
//  Created by USER on 11/5/24.
//

import RxSwift
import FirebaseFirestore
import FirebaseAuth
import FirebaseCore
import KakaoSDKUser
import GoogleSignIn
import AuthenticationServices
import CryptoKit

class DefaultAuthenticationRepository: AuthenticationRepository {
    private let firebaseAuth: Auth
    private let firestore: Firestore
    
    init(firebaseAuth: Auth = Auth.auth(), firestore: Firestore = Firestore.firestore()) {
        self.firebaseAuth = firebaseAuth
        self.firestore = firestore
    }
    
    func signIn(with provider: LoginMethod, credentials: [String: Any]) -> Observable<Result<User, Error>> {
        return Observable.create { [weak self] observer in
            switch provider {
            case .kakao:
                self?.handleKakaoSignIn(credentials: credentials, observer: observer)
            case .google:
                self?.handleGoogleSignIn(credentials: credentials, observer: observer)
            case .apple:
                self?.handleAppleSignIn(credentials: credentials, observer: observer)
            }
            return Disposables.create()
        }
    }
    
    func checkUserExists(userId: String) -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            self?.firestore.collection("users").document(userId).getDocument { document, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                observer.onNext(document?.exists ?? false)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    // MARK: - Kakao Sign In Implementation
    private func handleKakaoSignIn(credentials: [String: Any], observer: AnyObserver<Result<User, Error>>) {
        if UserApi.isKakaoTalkLoginAvailable() {
            handleKakaoTalkLogin(observer: observer)
        } else {
            handleKakaoAccountLogin(observer: observer)
        }
    }
    
    private func handleKakaoTalkLogin(observer: AnyObserver<Result<User, Error>>) {
        UserApi.shared.loginWithKakaoTalk { [weak self] (oauthToken, error) in
            if let error = error {
                observer.onNext(.failure(error))
                return
            }
            self?.fetchKakaoUserInfo(observer: observer)
        }
    }
    
    private func handleKakaoAccountLogin(observer: AnyObserver<Result<User, Error>>) {
        UserApi.shared.loginWithKakaoAccount { [weak self] (oauthToken, error) in
            if let error = error {
                observer.onNext(.failure(error))
                return
            }
            self?.fetchKakaoUserInfo(observer: observer)
        }
    }
    
    private func fetchKakaoUserInfo(observer: AnyObserver<Result<User, Error>>) {
        UserApi.shared.me() { [weak self] (user, error) in
            if let error = error {
                observer.onNext(.failure(error))
                return
            }
            
            guard let email = user?.kakaoAccount?.email,
                  let id = user?.id else {
                observer.onNext(.failure(AuthError.missingEmail))
                return
            }
            
            let password = "KAKAO_\(id)"
            self?.signInToFirebase(email: email, password: password, loginMethod: .kakao, observer: observer)
        }
    }
    
    // MARK: - Google Sign In Implementation
    private func handleGoogleSignIn(credentials: [String: Any], observer: AnyObserver<Result<User, Error>>) {
        guard let presentingViewController = credentials["presentingViewController"] as? UIViewController else {
            observer.onNext(.failure(AuthError.invalidCredentials))
            return
        }
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            observer.onNext(.failure(AuthError.invalidCredentials))
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            if let error = error {
                observer.onNext(.failure(error))
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                observer.onNext(.failure(AuthError.invalidToken))
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)
            
            self?.firebaseAuth.signIn(with: credential) { authResult, error in
                if let error = error {
                    observer.onNext(.failure(error))
                    return
                }
                
                if let email = authResult?.user.email {
                    let user = User(id: authResult?.user.uid ?? "",
                                  email: email,
                                  loginMethod: .google)
                    observer.onNext(.success(user))
                } else {
                    observer.onNext(.failure(AuthError.missingEmail))
                }
            }
        }
    }
    
    // MARK: - Apple Sign In Implementation
    private func handleAppleSignIn(credentials: [String: Any], observer: AnyObserver<Result<User, Error>>) {
        guard let appleCredential = credentials["appleCredential"] as? ASAuthorizationAppleIDCredential,
              let nonce = credentials["nonce"] as? String,
              let identityToken = appleCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            observer.onNext(.failure(AuthError.invalidCredentials))
            return
        }
        
        let credential = OAuthProvider.appleCredential(withIDToken: tokenString,
                                                     rawNonce: nonce,
                                                     fullName: appleCredential.fullName)
        
        firebaseAuth.signIn(with: credential) { authResult, error in
            if let error = error {
                observer.onNext(.failure(error))
                return
            }
            
            if let email = authResult?.user.email {
                let user = User(id: authResult?.user.uid ?? "",
                              email: email,
                              loginMethod: .apple)
                observer.onNext(.success(user))
            } else {
                observer.onNext(.failure(AuthError.missingEmail))
            }
        }
    }
    
    // MARK: - Firebase Auth Helper
    private func signInToFirebase(email: String, password: String, loginMethod: LoginMethod, observer: AnyObserver<Result<User, Error>>) {
        firebaseAuth.signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            if let error = error {
                // If user doesn't exist, create a new account
                if (error as NSError).code == AuthErrorCode.userNotFound.rawValue {
                    self?.createFirebaseAccount(email: email,
                                             password: password,
                                             loginMethod: loginMethod,
                                             observer: observer)
                } else {
                    observer.onNext(.failure(error))
                }
            } else if let email = authResult?.user.email {
                let user = User(id: authResult?.user.uid ?? "",
                              email: email,
                              loginMethod: loginMethod)
                observer.onNext(.success(user))
            }
        }
    }
    
    private func createFirebaseAccount(email: String, password: String, loginMethod: LoginMethod, observer: AnyObserver<Result<User, Error>>) {
        firebaseAuth.createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                observer.onNext(.failure(error))
                return
            }
            
            if let email = authResult?.user.email {
                let user = User(id: authResult?.user.uid ?? "",
                              email: email,
                              loginMethod: loginMethod)
                observer.onNext(.success(user))
            } else {
                observer.onNext(.failure(AuthError.missingEmail))
            }
        }
    }
}
