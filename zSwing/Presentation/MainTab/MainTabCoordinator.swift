//
//  MainTabCoordinator.swift
//  zSwing
//
//  Created by USER on 11/7/24.
//

import Foundation
import UIKit

protocol MainTabCoordinator: Coordinator {
    var tabBarController: UITabBarController { get }
    func showPhotoUpload()
    func showMap()
    func showProfile()
}

class DefaultMainTabCoordinator: MainTabCoordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    let tabBarController: UITabBarController
    private let diContainer: AppDIContainer
    
    init(navigationController: UINavigationController = UINavigationController(),
         diContainer: AppDIContainer = AppDIContainer.shared) {
        self.navigationController = navigationController
        self.diContainer = diContainer
        self.tabBarController = MainTabBarController()
    }
    
    func start() {
        setupTabs()
    }
    
    private func setupTabs() {
//        let photoVC = makePhotoUploadTab()
//        let mapVC = makeMapTab()
        let profileVC = makeProfileTab()
        
        tabBarController.viewControllers = [profileVC]
        tabBarController.selectedIndex = 1
    }
    
//    private func makeHomeTab() -> UINavigationController {
//        let photoVC = diContainer.makeHomeViewController()
//        let photoNav = UINavigationController(rootViewController: photoVC)
//        photoNav.tabBarItem = UITabBarItem(
//            title: "사진 등록",
//            image: UIImage(systemName: "camera"),
//            tag: 0
//        )
//        return photoNav
//    }
    
//    private func makeMapTab() -> UINavigationController {
//        let mapVC = diContainer.makeMapViewController()
//        let mapNav = UINavigationController(rootViewController: mapVC)
//        mapNav.tabBarItem = UITabBarItem(
//            title: "지도",
//            image: UIImage(systemName: "map"),
//            tag: 1
//        )
//        return mapNav
//    }
    
    private func makeProfileTab() -> UINavigationController {
        let profileVC = diContainer.makeProfileViewController()
        let profileNav = UINavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(
            title: "내 정보",
            image: UIImage(systemName: "person"),
            tag: 2
        )
        return profileNav
    }
    
    func showPhotoUpload() {
        tabBarController.selectedIndex = 0
    }
    
    func showMap() {
        tabBarController.selectedIndex = 1
    }
    
    func showProfile() {
        tabBarController.selectedIndex = 2
    }
}
