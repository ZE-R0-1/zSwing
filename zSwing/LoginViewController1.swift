////
////  LoginViewController.swift
////  zSwing
////
////  Created by USER on 10/17/24.
////
//
//import UIKit
//import FirebaseCore
//import FirebaseAuth
//import FirebaseFirestore
//import GoogleSignIn
//import KakaoSDKAuth
//import KakaoSDKUser
//import AuthenticationServices
//import CryptoKit
//
//class LoginViewController1: UIViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
//    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
//        <#code#>
//    }
//    
//    
//    private let logoImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFit
//        imageView.image = UIImage(named: "logo") // 로고 이미지를 추가하세요
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        return imageView
//    }()
//    
//    private let kakaoLoginButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("카카오 로그인", for: .normal)
//        button.backgroundColor = .yellow
//        button.setTitleColor(.black, for: .normal)
//        button.layer.cornerRadius = 8
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
//    
//    private let googleLoginButton: GIDSignInButton = {
//        let button = GIDSignInButton()
//        button.style = .standard
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
//    
//    private let appleLoginButton: ASAuthorizationAppleIDButton = {
//        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
//    
//    private let loadingView: UIView = {
//        let view = UIView()
//        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.isHidden = true
//        return view
//    }()
//    
//    private let activityIndicator: UIActivityIndicatorView = {
//        let indicator = UIActivityIndicatorView(style: .large)
//        indicator.color = .white
//        indicator.translatesAutoresizingMaskIntoConstraints = false
//        return indicator
//    }()
//    
//    private let loadingLabel: UILabel = {
//        let label = UILabel()
//        label.text = "로그인 중..."
//        label.textColor = .white
//        label.font = .systemFont(ofSize: 16, weight: .medium)
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    fileprivate var currentNonce: String?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupActions()
//        setupLoadingView()
//    }
//    
//    private func setupUI() {
//        view.backgroundColor = .white
//        
//        view.addSubview(logoImageView)
//        view.addSubview(kakaoLoginButton)
//        view.addSubview(googleLoginButton)
//        view.addSubview(appleLoginButton)
//        
//        NSLayoutConstraint.activate([
//            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
//            logoImageView.widthAnchor.constraint(equalToConstant: 200),
//            logoImageView.heightAnchor.constraint(equalToConstant: 100),
//            
//            kakaoLoginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            kakaoLoginButton.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 50),
//            kakaoLoginButton.widthAnchor.constraint(equalToConstant: 250),
//            kakaoLoginButton.heightAnchor.constraint(equalToConstant: 44),
//            
//            googleLoginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            googleLoginButton.topAnchor.constraint(equalTo: kakaoLoginButton.bottomAnchor, constant: 20),
//            googleLoginButton.widthAnchor.constraint(equalToConstant: 250),
//            googleLoginButton.heightAnchor.constraint(equalToConstant: 44),
//            
//            appleLoginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            appleLoginButton.topAnchor.constraint(equalTo: googleLoginButton.bottomAnchor, constant: 20),
//            appleLoginButton.widthAnchor.constraint(equalToConstant: 250),
//            appleLoginButton.heightAnchor.constraint(equalToConstant: 44)
//        ])
//    }
//    
//    private func setupActions() {
//        kakaoLoginButton.addTarget(self, action: #selector(kakaoLoginTapped), for: .touchUpInside)
//        googleLoginButton.addTarget(self, action: #selector(googleLoginTapped), for: .touchUpInside)
//        appleLoginButton.addTarget(self, action: #selector(appleLoginTapped), for: .touchUpInside)
//    }
//    
//    private func setupLoadingView() {
//        view.addSubview(loadingView)
//        loadingView.addSubview(activityIndicator)
//        loadingView.addSubview(loadingLabel)
//        
//        NSLayoutConstraint.activate([
//            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
//            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            
//            activityIndicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
//            activityIndicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor, constant: -20),
//            
//            loadingLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
//            loadingLabel.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor)
//        ])
//    }
//    
//    private func showLoading() {
//        loadingView.isHidden = false
//        activityIndicator.startAnimating()
//    }
//    
//    private func hideLoading() {
//        loadingView.isHidden = true
//        activityIndicator.stopAnimating()
//    }
//    
//    private func navigateToMainScreen() {
//        hideLoading()
//        let mainTabBarController = MainTabBarController()
//        mainTabBarController.modalPresentationStyle = .fullScreen
//        present(mainTabBarController, animated: true)
//    }
//    
//    private func navigateToNicknameViewController(loginMethod: String) {
//        hideLoading()
//        let nicknameVC = NicknameViewController()
//        nicknameVC.loginMethod = loginMethod
//        nicknameVC.modalPresentationStyle = .fullScreen
//        present(nicknameVC, animated: true, completion: nil)
//    }
//    
//    private func checkUserExists(loginMethod: String) {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        
//        let db = Firestore.firestore()
//        db.collection("users").document(uid).getDocument { [weak self] document, error in
//            if let document = document, document.exists {
//                self?.navigateToMainScreen()
//            } else {
//                self?.navigateToNicknameViewController(loginMethod: loginMethod)
//            }
//        }
//    }
//    
//    @objc private func kakaoLoginTapped() {
//        showLoading()
//        if (UserApi.isKakaoTalkLoginAvailable()) {
//            UserApi.shared.loginWithKakaoTalk { [weak self] (oauthToken, error) in
//                if let error = error {
//                    print(error)
//                    self?.hideLoading()
//                } else {
//                    print("카카오톡 로그인 성공")
//                    self?.loadKakaoUserInfo()
//                }
//            }
//        } else {
//            UserApi.shared.loginWithKakaoAccount { [weak self] (oauthToken, error) in
//                if let error = error {
//                    print(error)
//                    self?.hideLoading()
//                } else {
//                    print("카카오 계정 로그인 성공")
//                    self?.loadKakaoUserInfo()
//                }
//            }
//        }
//    }
//
//    private func loadKakaoUserInfo() {
//        UserApi.shared.me() { [weak self] (user, error) in
//            if let error = error {
//                print(error)
//            } else {
//                guard let email = user?.kakaoAccount?.email,
//                      let id = user?.id else {
//                    print("Failed to get Kakao user info")
//                    return
//                }
//                let password = "KAKAO_\(id)" // 고유한 비밀번호 생성
//                self?.signInToFirebase(email: email, password: password)
//            }
//        }
//    }
//
//    private func signInToFirebase(email: String, password: String) {
//        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
//            if let error = error {
//                if (error as NSError).code == AuthErrorCode.invalidCredential.rawValue {
//                    self?.createFirebaseAccount(email: email, password: password) { success in
//                        if success {
//                            self?.checkUserExists(loginMethod: "Kakao")
//                        }
//                    }
//                } else {
//                    print("Firebase sign-in error: \(error.localizedDescription)")
//                }
//            } else {
//                print("Firebase 로그인 성공")
//                self?.checkUserExists(loginMethod: "Kakao")
//            }
//        }
//    }
//
//    private func createFirebaseAccount(email: String, password: String, completion: @escaping (Bool) -> Void) {
//        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
//            if let error = error {
//                print("Firebase account creation error: \(error.localizedDescription)")
//                completion(false)
//            } else {
//                print("Firebase 계정 생성 및 로그인 성공")
//                completion(true)
//            }
//        }
//    }
//    
//    @objc private func googleLoginTapped() {
//        showLoading()
//        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
//        
//        let config = GIDConfiguration(clientID: clientID)
//        GIDSignIn.sharedInstance.configuration = config
//        
//        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [unowned self] result, error in
//            if let error = error {
//                print("Google Sign-In error: \(error.localizedDescription)")
//                self.hideLoading()
//                return
//            }
//            
//            guard let user = result?.user,
//                  let idToken = user.idToken?.tokenString else {
//                print("Failed to get user or ID token")
//                self.hideLoading()
//                return
//            }
//            
//            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
//                                                         accessToken: user.accessToken.tokenString)
//            
//            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
//                if let error = error {
//                    print("Firebase sign-in error: \(error.localizedDescription)")
//                    self?.hideLoading()
//                } else {
//                    print("Google 로그인 성공")
//                    self?.checkUserExists(loginMethod: "Google")
//                }
//            }
//        }
//    }
//    
//    @objc private func appleLoginTapped() {
//        showLoading()
//        let nonce = randomNonceString()
//        currentNonce = nonce
//        let appleIDProvider = ASAuthorizationAppleIDProvider()
//        let request = appleIDProvider.createRequest()
//        request.requestedScopes = [.fullName, .email]
//        request.nonce = sha256(nonce)
//        
//        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
//        authorizationController.delegate = self
//        authorizationController.presentationContextProvider = self
//        authorizationController.performRequests()
//    }
//    
//    private func randomNonceString(length: Int = 32) -> String {
//      precondition(length > 0)
//      var randomBytes = [UInt8](repeating: 0, count: length)
//      let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
//      if errorCode != errSecSuccess {
//        fatalError(
//            "nonce 생성 불가. SecRandomCopyBytes 실행 실패. OSStatus: \(errorCode)"
//        )
//      }
//
//      let charset: [Character] =
//        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
//
//      let nonce = randomBytes.map { byte in
//        charset[Int(byte) % charset.count]
//      }
//
//      return String(nonce)
//    }
//
//    private func sha256(_ input: String) -> String {
//        let inputData = Data(input.utf8)
//        let hashedData = SHA256.hash(data: inputData)
//        let hashString = hashedData.compactMap {
//            String(format: "%02x", $0)
//        }.joined()
//
//        return hashString
//    }
//}
//
//extension LoginViewController1: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
//    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
//        return self.view.window!
//    }
//    
//    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
//        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
//            guard let nonce = currentNonce else {
//                fatalError("Invalid state: A login callback was received, but no login request was sent.")
//            }
//            guard let appleIDToken = appleIDCredential.identityToken else {
//                print("Unable to fetch identity token")
//                return
//            }
//            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
//                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
//                return
//            }
//            
//            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
//                                                              rawNonce: nonce,
//                                                              fullName: appleIDCredential.fullName)
//            
//            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
//                if let error = error {
//                    print("Firebase sign-in error: \(error.localizedDescription)")
//                    return
//                }
//                print("Apple 로그인 성공")
//                self?.checkUserExists(loginMethod: "Apple")
//            }
//        }
//    }
//    
//    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
//        print("Apple Sign-In error: \(error.localizedDescription)")
//        hideLoading()
//    }
//}
