//
//  AuthCoordinator.swift
//  zSwing
//
//  Created by USER on 12/2/24.
//

import UIKit

protocol AuthCoordinator: Coordinator {
    func showLogin()
    func showNickname()
    func showMainFlow()
}

class DefaultAuthCoordinator: AuthCoordinator {
    let navigationController: UINavigationController
    private let diContainer: AppDIContainer
    weak var delegate: CoordinatorDelegate?
    
    init(navigationController: UINavigationController, diContainer: AppDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }
    
    func start() {
        showLogin()
    }
    
    func showLogin() {
        let loginVC = diContainer.makeLoginViewController()
        loginVC.coordinator = self
        navigationController.setViewControllers([loginVC], animated: false)
    }
    
    func showNickname() {
        let nicknameVC = diContainer.makeNicknameViewController()
        nicknameVC.coordinator = self
        navigationController.pushViewController(nicknameVC, animated: true)
    }
    
    func showMainFlow() {
        print("🔄 AuthCoordinator - Starting showMainFlow")
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            print("✅ AuthCoordinator - Found window")
            let mainTabCoordinator = diContainer.makeMainTabCoordinator(
                navigationController: navigationController
            )
            print("✅ AuthCoordinator - Created mainTabCoordinator")
            mainTabCoordinator.start()
            print("📱 AuthCoordinator - Current window.rootViewController: \(String(describing: window.rootViewController))")
            window.rootViewController = mainTabCoordinator.tabBarController
            print("📱 AuthCoordinator - Set new rootViewController")
            window.makeKeyAndVisible()
            print("✅ AuthCoordinator - Completed showMainFlow")
        } else {
            print("❌ AuthCoordinator - Could not find window")
        }
    }}
