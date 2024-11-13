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
        let homeVC = makeHomeTab()
        print("🏠 Home tab created")
        
        let mapVC = makeMapTab()
        print("🗺 Map tab created")
        
        let profileVC = makeProfileTab()
        print("👤 Profile tab created")
        
        // 탭바 컨트롤러에 뷰컨트롤러들 설정
        tabBarController.setViewControllers([homeVC, mapVC, profileVC], animated: false)  // animated: false로 설정
        tabBarController.selectedIndex = 0
        
        print("✅ Tabs setup completed")
    }
    
    private func makeHomeTab() -> UIViewController {
        let homeVC = diContainer.makeHomeViewController()
        homeVC.title = "홈"
        homeVC.tabBarItem = UITabBarItem(
            title: "홈",
            image: UIImage(systemName: "house"),
            tag: 0
        )
        return homeVC
    }
    
    private func makeMapTab() -> UIViewController {
        let mapVC = diContainer.makeMapViewController()
        mapVC.tabBarItem = UITabBarItem(
            title: "지도",
            image: UIImage(systemName: "map"),
            tag: 1
        )
        return mapVC
    }
    
    private func makeProfileTab() -> UIViewController {
        let profileVC = diContainer.makeProfileViewController()
        profileVC.title = "프로필"
        profileVC.tabBarItem = UITabBarItem(
            title: "프로필",
            image: UIImage(systemName: "person"),
            tag: 2
        )
        return profileVC
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
