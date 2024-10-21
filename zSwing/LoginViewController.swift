//
//  LoginViewController.swift
//  zSwing
//
//  Created by USER on 10/17/24.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import KakaoSDKAuth
import KakaoSDKUser
import AuthenticationServices
import CryptoKit

class LoginViewController: UIViewController {
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "logo") // 로고 이미지를 추가하세요
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let kakaoLoginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("카카오 로그인", for: .normal)
        button.backgroundColor = .yellow
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let googleLoginButton: GIDSignInButton = {
        let button = GIDSignInButton()
        button.style = .standard
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let appleLoginButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    fileprivate var currentNonce: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(logoImageView)
        view.addSubview(kakaoLoginButton)
        view.addSubview(googleLoginButton)
        view.addSubview(appleLoginButton)
        
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            logoImageView.widthAnchor.constraint(equalToConstant: 200),
            logoImageView.heightAnchor.constraint(equalToConstant: 100),
            
            kakaoLoginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            kakaoLoginButton.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 50),
            kakaoLoginButton.widthAnchor.constraint(equalToConstant: 250),
            kakaoLoginButton.heightAnchor.constraint(equalToConstant: 44),
            
            googleLoginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            googleLoginButton.topAnchor.constraint(equalTo: kakaoLoginButton.bottomAnchor, constant: 20),
            googleLoginButton.widthAnchor.constraint(equalToConstant: 250),
            googleLoginButton.heightAnchor.constraint(equalToConstant: 44),
            
            appleLoginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appleLoginButton.topAnchor.constraint(equalTo: googleLoginButton.bottomAnchor, constant: 20),
            appleLoginButton.widthAnchor.constraint(equalToConstant: 250),
            appleLoginButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupActions() {
        kakaoLoginButton.addTarget(self, action: #selector(kakaoLoginTapped), for: .touchUpInside)
        googleLoginButton.addTarget(self, action: #selector(googleLoginTapped), for: .touchUpInside)
        appleLoginButton.addTarget(self, action: #selector(appleLoginTapped), for: .touchUpInside)
    }
    
    @objc private func kakaoLoginTapped() {
        if (UserApi.isKakaoTalkLoginAvailable()) {
            UserApi.shared.loginWithKakaoTalk { [weak self] (oauthToken, error) in
                if let error = error {
                    print(error)
                } else {
                    print("카카오톡 로그인 성공")
                    self?.loadKakaoUserInfo()
                }
            }
        } else {
            UserApi.shared.loginWithKakaoAccount { [weak self] (oauthToken, error) in
                if let error = error {
                    print(error)
                } else {
                    print("카카오 계정 로그인 성공")
                    self?.loadKakaoUserInfo()
                }
            }
        }
    }

    private func loadKakaoUserInfo() {
        UserApi.shared.me() { [weak self] (user, error) in
            if let error = error {
                print(error)
            } else {
                guard let email = user?.kakaoAccount?.email,
                      let id = user?.id else {
                    print("Failed to get Kakao user info")
                    return
                }
                let password = "KAKAO_\(id)" // 고유한 비밀번호 생성
                self?.signInToFirebase(email: email, password: password)
            }
        }
    }

    private func signInToFirebase(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            if let error = error {
                // 로그인 실패 시 새 계정 생성
                if (error as NSError).code == AuthErrorCode.invalidCredential.rawValue {
                    self?.createFirebaseAccount(email: email, password: password)
                } else {
                    print("Firebase sign-in error: \(error.localizedDescription)")
                }
            } else {
                print("Firebase 로그인 성공")
            }
        }
    }

    private func createFirebaseAccount(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
            if let error = error {
                print("Firebase account creation error: \(error.localizedDescription)")
            } else {
                print("Firebase 계정 생성 및 로그인 성공")
            }
        }
    }
    
    @objc private func googleLoginTapped() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [unowned self] result, error in
            guard error == nil else {
                print("Google Sign-In error: \(error!.localizedDescription)")
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString
            else {
                print("Failed to get user or ID token")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase sign-in error: \(error.localizedDescription)")
                } else {
                    print("Google 로그인 성공")
                    // 추가 처리
                }
            }
        }
    }
    
    @objc private func appleLoginTapped() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      var randomBytes = [UInt8](repeating: 0, count: length)
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
      if errorCode != errSecSuccess {
        fatalError(
            "nonce 생성 불가. SecRandomCopyBytes 실행 실패. OSStatus: \(errorCode)"
        )
      }

      let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

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

extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                              rawNonce: nonce,
                                                              fullName: appleIDCredential.fullName)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase sign-in error: \(error.localizedDescription)")
                    return
                }
                print("Apple 로그인 성공")
                // 추가 처리 (예: 사용자 정보 저장, 메인 화면으로 이동 등)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign-In error: \(error.localizedDescription)")
    }
}
