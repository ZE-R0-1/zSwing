//
//  MainTabBarController.swift
//  zSwing
//
//  Created by USER on 10/21/24.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
    }

    private func setupViewControllers() {
        let mapVC = MapViewController()
        mapVC.tabBarItem = UITabBarItem(title: "지도", image: UIImage(systemName: "map"), tag: 0)

        let photoVC = PhotoUploadViewController()
        photoVC.tabBarItem = UITabBarItem(title: "사진 등록", image: UIImage(systemName: "camera"), tag: 1)

        let profileVC = ProfileViewController()
        profileVC.tabBarItem = UITabBarItem(title: "내 정보", image: UIImage(systemName: "person"), tag: 2)

        viewControllers = [mapVC, photoVC, profileVC].map { UINavigationController(rootViewController: $0) }
    }
}
