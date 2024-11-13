//
//  ProfileViewController.swift
//  zSwing
//
//  Created by USER on 11/7/24.
//

import UIKit
import RxSwift
import RxCocoa

class ProfileViewController: UIViewController {
    // MARK: - Properties
    private let viewModel: ProfileViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
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
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Initialization
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        title = "내 정보"
        
        view.addSubview(logoutButton)
        view.addSubview(withdrawButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoutButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            logoutButton.heightAnchor.constraint(equalToConstant: 44),
            
            withdrawButton.topAnchor.constraint(equalTo: logoutButton.bottomAnchor, constant: 20),
            withdrawButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            withdrawButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            withdrawButton.heightAnchor.constraint(equalToConstant: 44),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        // Input bindings
        logoutButton.rx.tap
            .bind(to: viewModel.logoutTapped)
            .disposed(by: disposeBag)
        
        withdrawButton.rx.tap
            .bind(to: viewModel.withdrawTapped)
            .disposed(by: disposeBag)
        
        // Output bindings
        viewModel.isLoading
            .bind(to: activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        viewModel.isLoading
            .map { !$0 }
            .bind(to: logoutButton.rx.isEnabled, withdrawButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
                self?.showAlert(title: "오류", message: error.localizedDescription)
            })
            .disposed(by: disposeBag)
        
        viewModel.showConfirmation
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.showConfirmationAlert(message: message)
            })
            .disposed(by: disposeBag)
        
        viewModel.navigationEvent
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] event in
                self?.handleNavigation(event)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func showConfirmationAlert(message: String) {
        let alert = UIAlertController(title: "회원탈퇴",
                                    message: message,
                                    preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "탈퇴", style: .destructive) { [weak self] _ in
            self?.viewModel.withdrawConfirmed.accept(())
        })
        
        present(alert, animated: true)
    }

    private func handleNavigation(_ event: ProfileNavigationEvent) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            switch event {
            case .loginWithNickname:
                let loginVC = AppDIContainer.shared.makeLoginViewController()
                let navigationController = UINavigationController(rootViewController: loginVC)
                
                UIView.transition(with: window,
                                duration: 0.3,
                                options: .transitionCrossDissolve,
                                animations: {
                    window.rootViewController = navigationController
                })
                
            case .loginWithoutNickname:
                let loginVC = AppDIContainer.shared.makeLoginViewController()
                // 로그아웃의 경우 닉네임 입력 화면을 스킵하도록 플래그 설정
                UserDefaults.standard.set(true, forKey: "hasNickname")
                let navigationController = UINavigationController(rootViewController: loginVC)
                
                UIView.transition(with: window,
                                duration: 0.3,
                                options: .transitionCrossDissolve,
                                animations: {
                    window.rootViewController = navigationController
                })
            }
            
            window.makeKeyAndVisible()
        }
    }
}
