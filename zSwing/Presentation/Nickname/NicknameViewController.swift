//
//  NicknameViewController.swift
//  zSwing
//
//  Created by USER on 11/11/24.
//

import UIKit
import RxSwift
import RxCocoa

class NicknameViewController: UIViewController {
    // MARK: - Properties
    private let viewModel: NicknameViewModel
    private let disposeBag = DisposeBag()
    private let keyboardHeight = PublishRelay<CGFloat>()
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "chevron.left")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))
        button.setImage(image, for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let nicknameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "닉네임을 입력하세요"
        textField.borderStyle = .roundedRect
        textField.returnKeyType = .done
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
        button.isEnabled = false  // 초기 상태는 비활성화
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private var containerCenterYConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    init(viewModel: NicknameViewModel) {
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
        setupKeyboardHandling()
        setupAutoFocus()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(backButton)
        view.addSubview(containerView)
        view.addSubview(activityIndicator)
        
        containerView.addSubview(nicknameTextField)
        containerView.addSubview(submitButton)
        
        containerCenterYConstraint = containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        
        NSLayoutConstraint.activate([
            // Back Button
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Container View
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerCenterYConstraint!,
            
            // Nickname TextField
            nicknameTextField.topAnchor.constraint(equalTo: containerView.topAnchor),
            nicknameTextField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            nicknameTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            nicknameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Submit Button
            submitButton.topAnchor.constraint(equalTo: nicknameTextField.bottomAnchor, constant: 20),
            submitButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            submitButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            submitButton.heightAnchor.constraint(equalToConstant: 44),
            submitButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        // Back button binding
        backButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        // TextField validation
        nicknameTextField.rx.text.orEmpty
            .map { !$0.isEmpty }
            .bind(to: submitButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        // Submit button style based on state
        nicknameTextField.rx.text.orEmpty
            .map { !$0.isEmpty }
            .do(onNext: { [weak self] isEnabled in
                let backgroundColor = isEnabled ? UIColor.systemBlue : UIColor.systemGray3
                self?.submitButton.backgroundColor = backgroundColor
            })
            .bind(to: submitButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        // Submit actions (button tap and return key)
        Observable.merge(
            submitButton.rx.tap.asObservable(),
            nicknameTextField.rx.controlEvent(.editingDidEndOnExit).asObservable()
        )
        .withLatestFrom(nicknameTextField.rx.text.orEmpty)
        .filter { !$0.isEmpty }
        .bind(to: viewModel.nicknameTrigger)
        .disposed(by: disposeBag)
        
        // ViewModel outputs
        viewModel.isLoading
            .bind(to: activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        viewModel.error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
                self?.showAlert(message: error.localizedDescription)
            })
            .disposed(by: disposeBag)
        
        viewModel.navigationEvent
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] event in
                self?.handleNavigation(event)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupKeyboardHandling() {
        // 키보드 알림에서 애니메이션 정보 추출
        struct KeyboardTransitionInfo {
            let height: CGFloat
            let duration: TimeInterval
            let curve: UIView.AnimationCurve
        }
        
        let keyboardWillShow = NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .map { notification -> KeyboardTransitionInfo in
                let height = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
                let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.3
                let curveRawValue = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? UIView.AnimationCurve.easeInOut.rawValue
                let curve = UIView.AnimationCurve(rawValue: curveRawValue) ?? .easeInOut
                return KeyboardTransitionInfo(height: height, duration: duration, curve: curve)
            }
        
        let keyboardWillHide = NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
            .map { notification -> KeyboardTransitionInfo in
                let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.3
                let curveRawValue = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? UIView.AnimationCurve.easeInOut.rawValue
                let curve = UIView.AnimationCurve(rawValue: curveRawValue) ?? .easeInOut
                return KeyboardTransitionInfo(height: 0, duration: duration, curve: curve)
            }
        
        // 키보드 트랜지션 처리
        Observable.merge(keyboardWillShow, keyboardWillHide)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] info in
                guard let self = self else { return }
                
                self.containerCenterYConstraint?.constant = info.height > 0 ? -info.height/4 : 0
                
                let animator = UIViewPropertyAnimator(duration: info.duration, curve: info.curve) {
                    self.view.layoutIfNeeded()
                }
                
                animator.startAnimation()
            })
            .disposed(by: disposeBag)
        
        // 화면 탭 제스처
        let tapGesture = UITapGestureRecognizer()
        view.addGestureRecognizer(tapGesture)
        
        tapGesture.rx.event
            .subscribe(onNext: { [weak self] _ in
                self?.view.endEditing(true)
            })
            .disposed(by: disposeBag)
    }
    
    
    private func setupAutoFocus() {
        Observable.just(())
            .subscribe(onNext: { [weak self] _ in
                self?.nicknameTextField.becomeFirstResponder()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helper Methods
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func handleNavigation(_ event: NicknameNavigationEvent) {
        switch event {
        case .mainScreen:
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                let mainTabCoordinator = AppDIContainer.shared.makeMainTabCoordinator(
                    navigationController: UINavigationController()
                )
                mainTabCoordinator.start()
                window.rootViewController = mainTabCoordinator.tabBarController
                window.makeKeyAndVisible()
            }
        }
    }
}
