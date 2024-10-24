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
        let mapVC = MapViewController()
        mapVC.tabBarItem = UITabBarItem(title: "지도", image: UIImage(systemName: "map"), tag: 0)

        let photoVC = PhotoUploadViewController()
        photoVC.tabBarItem = UITabBarItem(title: "사진 등록", image: UIImage(systemName: "camera"), tag: 1)

        let profileVC = ProfileViewController()
        profileVC.tabBarItem = UITabBarItem(title: "내 정보", image: UIImage(systemName: "person"), tag: 2)

        viewControllers = [mapVC, photoVC, profileVC].map { UINavigationController(rootViewController: $0) }
    }
    
    private func configureTabBar() {
        // iOS 15 이상에서 탭바 배경을 불투명하게 설정
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()  // 불투명 배경 설정
            
            // 탭바 그림자 효과 제거 (선택사항)
            appearance.shadowColor = nil
            
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance  // 스크롤 시에도 동일한 모습 유지
        } else {
            // iOS 15 미만에서는 아래 방식으로 설정
            tabBar.isTranslucent = false
        }
        
        // 탭바 배경색 설정 (원하는 색상으로 변경 가능)
        tabBar.backgroundColor = .systemBackground
    }
}
