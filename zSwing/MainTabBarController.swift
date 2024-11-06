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
        configureTabBar()
        
        // 모든 네비게이션 컨트롤러의 네비게이션 바 숨기기
        viewControllers?.forEach { navigationController in
            (navigationController as? UINavigationController)?.navigationBar.isHidden = true
        }
    }

    private func setupViewControllers() {
        let photoVC = PhotoUploadViewController()
        photoVC.tabBarItem = UITabBarItem(title: "사진 등록", image: UIImage(systemName: "camera"), tag: 0)
        
        let mapVC = MapViewController()
        mapVC.tabBarItem = UITabBarItem(title: "지도", image: UIImage(systemName: "map"), tag: 1)
        
//        let profileVC = ProfileViewController()
//        profileVC.tabBarItem = UITabBarItem(title: "내 정보", image: UIImage(systemName: "person"), tag: 2)
//
        viewControllers = [photoVC, mapVC, ].map { UINavigationController(rootViewController: $0) }
        
        selectedIndex = 1
    }
    
    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // 기본 구분선 제거
        appearance.shadowImage = UIImage()
        
        // 배경색 설정
        appearance.backgroundColor = .systemBackground
        
        // 커스텀 그림자 설정
        tabBar.layer.masksToBounds = false
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -3)
        tabBar.layer.shadowRadius = 4
        tabBar.layer.shadowOpacity = 0.1
        
        // 탭바 모서리 처리 (선택사항)
        tabBar.layer.cornerRadius = 15
        tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // appearance 적용
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 레이아웃 변경 시에도 그림자가 유지되도록 설정
        tabBar.layer.shadowPath = UIBezierPath(rect: tabBar.bounds).cgPath
    }
}
