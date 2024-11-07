//
//  LoginViewModel.swift
//  zSwing
//
//  Created by USER on 11/5/24.
//

import RxSwift
import RxRelay
import UIKit
import AuthenticationServices
import CryptoKit

class LoginViewModel {
    private let signInUseCase: SignInUseCase
    private let disposeBag = DisposeBag()
    
    // Outputs
    let isLoading = BehaviorRelay<Bool>(value: false)
    let error = PublishRelay<Error>()
    let navigationEvent = PublishRelay<NavigationEvent>()
    
    // Inputs
    let kakaoLoginTapped = PublishRelay<Void>()
    let googleLoginTapped = PublishRelay<Void>()
    let appleLoginTapped = PublishRelay<Void>()
    
    // Current View Controller for Google Sign In
    weak var presentingViewController: UIViewController?
    
    private var currentNonce: String?
    
    init(signInUseCase: SignInUseCase) {
        self.signInUseCase = signInUseCase
        setupBindings()
    }
    
    private func setupBindings() {
        // Kakao Login
        kakaoLoginTapped
            .do(onNext: { [weak self] in self?.isLoading.accept(true) })
            .flatMapLatest { [weak self] _ -> Observable<Result<User, Error>> in
                guard let self = self else { return .empty() }
                return self.signInUseCase.execute(with: .kakao, credentials: [:])
            }
            .subscribe(onNext: { [weak self] result in
                self?.handleSignInResult(result)
            })
            .disposed(by: disposeBag)
        
        // Google Login
        googleLoginTapped
            .do(onNext: { [weak self] in self?.isLoading.accept(true) })
            .flatMapLatest { [weak self] _ -> Observable<Result<User, Error>> in
                guard let self = self else { return .empty() }
                let credentials: [String: Any] = ["presentingViewController": self.presentingViewController as Any]
                return self.signInUseCase.execute(with: .google, credentials: credentials)
            }
            .subscribe(onNext: { [weak self] result in
                self?.handleSignInResult(result)
            })
            .disposed(by: disposeBag)
        
        // Apple Login
        appleLoginTapped
            .subscribe(onNext: { [weak self] in
                self?.initiateAppleSignIn()
            })
            .disposed(by: disposeBag)
    }
    
    private func initiateAppleSignIn() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        if let presentingViewController = presentingViewController as? ASAuthorizationControllerPresentationContextProviding {
            authorizationController.presentationContextProvider = presentingViewController
        }
        authorizationController.delegate = presentingViewController as? ASAuthorizationControllerDelegate
        authorizationController.performRequests()
    }
    
    func handleAppleSignInCompletion(credential: ASAuthorizationAppleIDCredential) {
        isLoading.accept(true)
        guard let nonce = currentNonce else { return }
        
        let credentials: [String: Any] = [
            "appleCredential": credential,
            "nonce": nonce
        ]
        
        signInUseCase.execute(with: .apple, credentials: credentials)
            .subscribe(onNext: { [weak self] result in
                self?.handleSignInResult(result)
            })
            .disposed(by: disposeBag)
    }
    
    private func handleSignInResult(_ result: Result<User, Error>) {
        isLoading.accept(false)
        switch result {
        case .success(let user):
            navigationEvent.accept(.mainScreen)
        case .failure(let error):
            self.error.accept(error)
        }
    }
    
    // MARK: - Helper Methods
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

enum NavigationEvent {
    case mainScreen
    case nickname
}
