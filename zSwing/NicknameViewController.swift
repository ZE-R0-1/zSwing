//
//  NicknameViewController.swift
//  zSwing
//
//  Created by USER on 10/21/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class NicknameViewController: UIViewController {
    
    var loginMethod: String?
    
    private let nicknameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "닉네임을 입력하세요"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("제출", for: .normal)
        button.backgroundColor = .systemBlue
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
        view.addSubview(nicknameTextField)
        view.addSubview(submitButton)
        
        NSLayoutConstraint.activate([
            nicknameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nicknameTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            nicknameTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            nicknameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            submitButton.topAnchor.constraint(equalTo: nicknameTextField.bottomAnchor, constant: 20),
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            submitButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupActions() {
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
    }
    
    @objc private func submitButtonTapped() {
        guard let nickname = nicknameTextField.text, !nickname.isEmpty else {
            showAlert(message: "닉네임을 입력해주세요.")
            return
        }
        
        saveUserToFirestore(nickname: nickname)
    }
    
    private func saveUserToFirestore(nickname: String) {
        guard let uid = Auth.auth().currentUser?.uid,
              let email = Auth.auth().currentUser?.email else {
            showAlert(message: "사용자 정보를 가져올 수 없습니다.")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "nickname": nickname,
            "email": email,
            "loginMethod": loginMethod ?? "unknown",
            "createdAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                self.showAlert(message: "데이터 저장 중 오류가 발생했습니다: \(error.localizedDescription)")
            } else {
                self.showAlert(message: "사용자 정보가 저장되었습니다.", completion: {
                    // 여기서 메인 화면으로 이동하는 로직을 구현합니다.
                    // 예: self.navigateToMainScreen()
                })
            }
        }
    }
    
    private func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    // 메인 화면으로 이동하는 메소드 (구현 필요)
    private func navigateToMainScreen() {
        // 메인 화면으로 이동하는 로직을 구현합니다.
    }
}
