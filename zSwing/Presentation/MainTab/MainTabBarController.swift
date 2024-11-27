//
//  MainTabBarController.swift
//  zSwing
//
//  Created by USER on 10/21/24.
//

import UIKit

class MainTabBarController: UITabBarController {
    private var viewModel: MainTabBarViewModel!
    
    func configure(with viewModel: MainTabBarViewModel) {
        self.viewModel = viewModel
        setupAppearance()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 각 뷰 컨트롤러의 레이아웃을 즉시 적용
        viewControllers?.forEach { viewController in
            viewController.view.setNeedsLayout()
            viewController.view.layoutIfNeeded()
        }
    }
    
    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.layer.cornerRadius = 15
    }
}
