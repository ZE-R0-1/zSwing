//
//  MainTabBarController.swift
//  zSwing
//
//  Created by USER on 10/21/24.
//

import UIKit

class MainTabBarController: UITabBarController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewControllers?.forEach { viewController in
            viewController.view.setNeedsLayout()
            viewController.view.layoutIfNeeded()
        }
    }
    
    func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.layer.cornerRadius = 15
    }
}
