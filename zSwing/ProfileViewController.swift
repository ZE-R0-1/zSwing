//
//  ProfileViewController.swift
//  zSwing
//
//  Created by USER on 10/21/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import KakaoSDKUser
import AuthenticationServices

class ProfileViewController: UIViewController {
    
    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("로그아웃", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let withdrawButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("회원탈퇴", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        title = "내 정보"
        
        view.addSubview(logoutButton)
        view.addSubview(withdrawButton)
        
        NSLayoutConstraint.activate([
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoutButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            logoutButton.heightAnchor.constraint(equalToConstant: 44),
            
            withdrawButton.topAnchor.constraint(equalTo: logoutButton.bottomAnchor, constant: 20),
            withdrawButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            withdrawButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            withdrawButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupActions() {
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        withdrawButton.addTarget(self, action: #selector(withdrawButtonTapped), for: .touchUpInside)
    }
    
    private func fetchLoginMethod(completion: @escaping (String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let document = document, document.exists {
                let loginMethod = document.data()?["loginMethod"] as? String
                completion(loginMethod)
            } else {
                completion(nil)
            }
        }
    }
    
    @objc private func logoutButtonTapped() {
        fetchLoginMethod { [weak self] loginMethod in
            guard let self = self else { return }
            
            switch loginMethod {
            case "Kakao":
                self.handleKakaoLogout()
            case "Google":
                self.handleGoogleLogout()
            case "Apple":
                self.handleGeneralLogout()
            default:
                self.handleGeneralLogout()
            }
        }
    }
    
    private func handleKakaoLogout() {
        UserApi.shared.logout { [weak self] error in
            if let error = error {
                self?.showAlert(message: "카카오 로그아웃 실패: \(error.localizedDescription)")
            } else {
                self?.handleGeneralLogout()
            }
        }
    }
    
    private func handleGoogleLogout() {
        GIDSignIn.sharedInstance.signOut()
        handleGeneralLogout()
    }
    
    private func handleGeneralLogout() {
        do {
            try Auth.auth().signOut()
            navigateToLogin()
        } catch {
            showAlert(message: "로그아웃 실패: \(error.localizedDescription)")
        }
    }
    
    @objc private func withdrawButtonTapped() {
        let alert = UIAlertController(title: "회원탈퇴",
                                    message: "정말로 탈퇴하시겠습니까? 이 작업은 되돌릴 수 없습니다.",
                                    preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "탈퇴", style: .destructive) { [weak self] _ in
            self?.handleWithdrawal()
        })
        
        present(alert, animated: true)
    }
    
    private func handleWithdrawal() {
        fetchLoginMethod { [weak self] loginMethod in
            guard let self = self else { return }
            
            switch loginMethod {
            case "Kakao":
                self.handleKakaoWithdrawal()
            case "Google":
                self.handleGoogleWithdrawal()
            case "Apple":
                self.handleFirebaseWithdrawal()
            default:
                self.handleFirebaseWithdrawal()
            }
        }
    }
    
    private func handleKakaoWithdrawal() {
        UserApi.shared.unlink { [weak self] error in
            if let error = error {
                self?.showAlert(message: "카카오 계정 연결 해제 실패: \(error.localizedDescription)")
            } else {
                self?.handleFirebaseWithdrawal()
            }
        }
    }
    
    private func handleGoogleWithdrawal() {
        GIDSignIn.sharedInstance.signOut()
        handleFirebaseWithdrawal()
    }
    
    private func handleFirebaseWithdrawal() {
        guard let user = Auth.auth().currentUser else {
            showAlert(message: "사용자 정보를 찾을 수 없습니다.")
            return
        }
        
        // Firestore 사용자 데이터 삭제
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).delete { [weak self] error in
            if let error = error {
                self?.showAlert(message: "데이터 삭제 실패: \(error.localizedDescription)")
                return
            }
            
            // Firebase Authentication 계정 삭제
            user.delete { [weak self] error in
                if let error = error {
                    self?.showAlert(message: "계정 삭제 실패: \(error.localizedDescription)")
                } else {
                    self?.showAlert(message: "회원탈퇴가 완료되었습니다.") {
                        self?.navigateToLogin()
                    }
                }
            }
        }
    }
    
    private func navigateToLogin() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let loginVC = LoginViewController()
            window.rootViewController = loginVC
            window.makeKeyAndVisible()
        }
    }
    
    private func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
