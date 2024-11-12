//
//  MainTabCoordinator.swift
//  zSwing
//
//  Created by USER on 11/7/24.
//

import UIKit

protocol MainTabCoordinator: Coordinator {
    var tabBarController: UITabBarController { get }
    func showPhotoUpload()
    func showMap()
    func showProfile()
}

class DefaultMainTabCoordinator: MainTabCoordinator {
    // MARK: - Properties
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    let tabBarController: UITabBarController
    private let diContainer: AppDIContainer
    
    // MARK: - Initialization
    init(navigationController: UINavigationController = UINavigationController(),
         diContainer: AppDIContainer = AppDIContainer.shared) {
        print("🚀 Initializing MainTabCoordinator")
        self.navigationController = navigationController
        self.diContainer = diContainer
        
        // 먼저 TabBarController 인스턴스만 생성
        let tabBarController = MainTabBarController()
        self.tabBarController = tabBarController
        
        // 모든 프로퍼티가 초기화된 후에 ViewModel 설정
        print("⚙️ Setting up ViewModel")
        let viewModel = MainTabBarViewModel(coordinator: self)
        tabBarController.configure(with: viewModel)
        
        print("✅ MainTabCoordinator initialization completed")
    }
    
    // MARK: - Coordinator Methods
    func start() {
        print("▶️ Starting MainTabCoordinator")
        setupTabs()
    }
    
    // MARK: - Private Methods
    private func setupTabs() {
        print("📱 Setting up tabs")
        
        // 각 탭에 대한 ViewController 생성
        let homeNav = makeHomeTab()
        print("🏠 Home tab created")
        
        let mapNav = makeMapTab()
        print("🗺 Map tab created")
        
        let profileNav = makeProfileTab()
        print("👤 Profile tab created")
        
        // 탭바 컨트롤러에 뷰컨트롤러들 설정
        tabBarController.viewControllers = [homeNav, mapNav, profileNav]
        tabBarController.selectedIndex = 0
        
        print("✅ Tabs setup completed")
    }
    
    private func makeHomeTab() -> UINavigationController {
        let homeVC = diContainer.makeHomeViewController()
        homeVC.title = "홈"
        
        let nav = UINavigationController(rootViewController: homeVC)
        nav.tabBarItem = UITabBarItem(
            title: "홈",
            image: UIImage(systemName: "house"),
            tag: 0
        )
        return nav
    }
    
    private func makeMapTab() -> UINavigationController {
        let mapVC = diContainer.makeMapViewController()
        
        let nav = UINavigationController(rootViewController: mapVC)
        nav.isNavigationBarHidden = true  // 이 줄을 추가
        nav.tabBarItem = UITabBarItem(
            title: "지도",
            image: UIImage(systemName: "map"),
            tag: 1
        )
        return nav
    }
    
    private func makeProfileTab() -> UINavigationController {
        let profileVC = diContainer.makeProfileViewController()
        profileVC.title = "프로필"
        
        let nav = UINavigationController(rootViewController: profileVC)
        nav.tabBarItem = UITabBarItem(
            title: "프로필",
            image: UIImage(systemName: "person"),
            tag: 2
        )
        return nav
    }
    
    // MARK: - Public Navigation Methods
    func showPhotoUpload() {
        print("📸 Showing photo upload")
        tabBarController.selectedIndex = 0
    }
    
    func showMap() {
        print("🗺 Showing map")
        tabBarController.selectedIndex = 1
    }
    
    func showProfile() {
        print("👤 Showing profile")
        tabBarController.selectedIndex = 2
    }
}
