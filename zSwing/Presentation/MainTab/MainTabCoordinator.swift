//
//  MainTabCoordinator.swift
//  zSwing
//
//  Created by USER on 11/7/24.
//

import UIKit

protocol MainTabCoordinator: Coordinator {
    var tabBarController: UITabBarController { get }
}

class DefaultMainTabCoordinator: MainTabCoordinator {
    let navigationController: UINavigationController
    let tabBarController: UITabBarController
    private let diContainer: AppDIContainer
    
    init(navigationController: UINavigationController = UINavigationController(),
         diContainer: AppDIContainer = AppDIContainer.shared) {
        self.navigationController = navigationController
        self.diContainer = diContainer
        self.tabBarController = MainTabBarController()
        
        let viewModel = MainTabBarViewModel(coordinator: self)
        (tabBarController as? MainTabBarController)?.configure(with: viewModel)
    }
    
    func start() {
        setupTabs()
    }
    
    private func setupTabs() {
        let homeVC = diContainer.makeHomeViewController()
        homeVC.tabBarItem = UITabBarItem(title: "홈", image: UIImage(systemName: "house"), tag: 0)
        
        let mapVC = diContainer.makeMapViewController()
        mapVC.tabBarItem = UITabBarItem(title: "지도", image: UIImage(systemName: "map"), tag: 1)
        
        let profileVC = diContainer.makeProfileViewController()
        profileVC.tabBarItem = UITabBarItem(title: "프로필", image: UIImage(systemName: "person"), tag: 2)
        
        tabBarController.setViewControllers([homeVC, mapVC, profileVC], animated: false)
        tabBarController.selectedIndex = 0
    }
}
