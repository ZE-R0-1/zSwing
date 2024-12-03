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
    weak var coordinator: ProfileCoordinator?
    
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
        
        // Loading state
        viewModel.isLoading
            .bind(to: activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        viewModel.isLoading
            .map { !$0 }
            .bind(to: logoutButton.rx.isEnabled, withdrawButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        // Navigation request handling
        viewModel.navigationRequest
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] request in
                guard let self = self else { return }
                switch request {
                case .logout:
                    self.coordinator?.logout()
                case .withdraw:
                    self.coordinator?.withdraw()
                case .showWithdrawConfirmation:
                    self.coordinator?.showConfirmation(
                        message: "정말로 탈퇴하시겠습니까?\n이 작업은 되돌릴 수 없으며 모든 데이터가 삭제됩니다."
                    ) { [weak self] confirmed in
                        if confirmed {
                            self?.viewModel.withdrawConfirmed.accept(())
                        }
                    }
                }
            })
            .disposed(by: disposeBag)
        
        // Error handling
        viewModel.error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
                self?.coordinator?.showAlert(title: "오류", message: error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
}
