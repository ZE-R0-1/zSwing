//
//  AppCoordinator.swift
//  zSwing
//
//  Created by USER on 11/5/24.
//

import UIKit
import RxSwift

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    var childCoordinators: [Coordinator] { get set }
    func start()
}

class AppCoordinator: Coordinator {
    let window: UIWindow
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    private let firebaseAuthService: FirebaseAuthServiceProtocol
    private let disposeBag = DisposeBag()
    
    init(window: UIWindow,
         navigationController: UINavigationController = UINavigationController(),
         firebaseAuthService: FirebaseAuthServiceProtocol = FirebaseAuthService()) {
        self.window = window
        self.navigationController = navigationController
        self.firebaseAuthService = firebaseAuthService
        
        setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.tintColor = .black
    }
    
    func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        checkAuthenticationStatus()
    }
    
    private func checkAuthenticationStatus() {
        print("Checking authentication status")
        
        firebaseAuthService.getCurrentUser()
            .observe(on: MainScheduler.instance)
            .do(onNext: { user in
                print("Auth status received: \(user != nil)")
            }, onError: { error in
                print("Auth error: \(error)")
            }, onCompleted: {
                print("Auth check completed")
            })
            .subscribe(onNext: { [weak self] user in
                if let user = user {
                    print("User found, showing main flow")
                    self?.showMainFlow(for: user)
                } else {
                    print("No user found, showing auth flow")
                    self?.showAuthFlow()
                }
            }, onError: { [weak self] error in
                print("Error in auth check: \(error)")
                self?.showAuthFlow()
            })
            .disposed(by: disposeBag)
    }
    
    private func showAuthFlow() {
        print("Setting up auth flow")
        let loginViewController = AppDIContainer.shared.makeLoginViewController()
        loginViewController.title = "로그인"
        navigationController.setViewControllers([loginViewController], animated: true)
    }
    
    private func showMainFlow(for user: User) {
        print("Setting up main flow for user: \(user.email)")
        
        // MainTabBarController 생성
        let mainTabBarController = MainTabBarController()
        
        // 기존 네비게이션 스택을 모두 제거하고 MainTabBarController를 루트로 설정
        window.rootViewController = mainTabBarController
        
        // 화면 전환 애니메이션 추가
        UIView.transition(with: window,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                         animations: nil,
                         completion: nil)
        
        print("Main flow setup completed")
    }
}
