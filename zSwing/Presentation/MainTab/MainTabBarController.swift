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
    
    private func setupAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -3)
        tabBar.layer.shadowRadius = 4
        tabBar.layer.shadowOpacity = 0.1
        tabBar.layer.cornerRadius = 15
    }
}
