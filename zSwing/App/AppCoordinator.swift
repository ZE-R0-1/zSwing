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
    func start()
}

class AppCoordinator: Coordinator {
    let window: UIWindow
    let navigationController: UINavigationController
    private let authService: FirebaseAuthServiceProtocol
    private let disposeBag = DisposeBag()
    
    init(window: UIWindow,
         navigationController: UINavigationController = UINavigationController(),
         authService: FirebaseAuthServiceProtocol = FirebaseAuthService()) {
        self.window = window
        self.navigationController = navigationController
        self.authService = authService
    }
    
    func start() {
        // 초기 로딩 상태를 표시할 뷰 컨트롤러 설정
        let loadingVC = AppDIContainer.shared.makeLoadingViewController()
        // 초기 화면으로 로딩 화면 설정
        window.rootViewController = loadingVC
        window.makeKeyAndVisible()
        
        // 인증 상태 체크
        checkAuth()
    }
    
    private func checkAuth() {
        authService.getCurrentUser()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] user in
                if let user = user {
                    self?.showMainFlow(for: user)
                } else {
                    self?.showAuthFlow()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func showAuthFlow() {
        let loginVC = AppDIContainer.shared.makeLoginViewController()
        navigationController.setViewControllers([loginVC], animated: false)
        
        UIView.transition(with: window,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                         animations: {
            self.window.rootViewController = self.navigationController
        })
    }
    
    private func showMainFlow(for user: User) {
        let mainTabCoordinator = AppDIContainer.shared.makeMainTabCoordinator(
            navigationController: navigationController
        )
        mainTabCoordinator.start()
        
        UIView.transition(with: window,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                         animations: {
            self.window.rootViewController = mainTabCoordinator.tabBarController
        })
    }
}
