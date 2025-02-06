//
//  MainTabCoordinator.swift
//  zSwing
//
//  Created by USER on 11/7/24.
//

import UIKit

protocol MainTabCoordinator: Coordinator {
    var tabBarController: UITabBarController { get }
    func showHome()
    func showMap()
//    func showProfile()
//    func switchToAuth()
}

class DefaultMainTabCoordinator: MainTabCoordinator, MapCoordinator {
    let navigationController: UINavigationController
    let tabBarController: UITabBarController
    private let diContainer: AppDIContainer
    weak var delegate: CoordinatorDelegate?
    
    // Child Coordinators
    private var homeCoordinator: Coordinator?
    private var mapCoordinator: MapCoordinator?
//    private var profileCoordinator: ProfileCoordinator?
//    private var authCoordinator: AuthCoordinator?
    
    init(navigationController: UINavigationController, diContainer: AppDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
        self.tabBarController = MainTabBarController()
        
        (tabBarController as? MainTabBarController)?.setupAppearance()
    }
    
    func start() {
        setupTabs()
        showHome()
    }
    
    func showHome() {
        tabBarController.selectedIndex = 0
    }
    
    func showMap() {
        tabBarController.selectedIndex = 1
    }
    
//    func showProfile() {
//        tabBarController.selectedIndex = 2
//    }
    
//    func switchToAuth() {
//        print("🔄 MainTab coordinator: Starting switchToAuth")
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//           let window = windowScene.windows.first {
//            print("📱 Current window hierarchy:")
//            print("- Root VC: \(String(describing: window.rootViewController))")
//            print("- Child VCs: \(String(describing: window.rootViewController?.children))")
//            
//            let navigationController = UINavigationController()
//            let authCoordinator = diContainer.makeAuthCoordinator(
//                navigationController: navigationController
//            )
//            
//            // coordinator 시작 전에 인스턴스 저장
//            self.authCoordinator = authCoordinator
//            
//            // coordinator 시작 (이 때 LoginViewController의 coordinator가 설정됨)
//            authCoordinator.start()
//            
//            UIView.transition(with: window,
//                              duration: 0.3,
//                              options: .transitionCrossDissolve,
//                              animations: {
//                window.rootViewController = navigationController
//            }) { completed in
//                print("📱 New window hierarchy:")
//                print("- Root VC: \(String(describing: window.rootViewController))")
//                print("- Child VCs: \(String(describing: window.rootViewController?.children))")
//            }
//        }
//    }
    
    private func setupTabs() {
        // Home Tab
        let homeNC = UINavigationController()
        let homeCoordinator = diContainer.makeHomeCoordinator(navigationController: homeNC)
        homeCoordinator.start()
        homeNC.tabBarItem = UITabBarItem(title: "홈", image: UIImage(systemName: "house"), tag: 0)
        
        // 나머지 탭 코드 유지
        let mapVC = diContainer.makeMapViewController(coordinator: self)
        mapVC.tabBarItem = UITabBarItem(title: "지도", image: UIImage(systemName: "map"), tag: 1)
        
        tabBarController.setViewControllers(
            [homeNC, mapVC],
            animated: false
        )
    }
}
