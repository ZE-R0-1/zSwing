//
//  MainTabBarViewModel.swift
//  zSwing
//
//  Created by USER on 11/7/24.
//

import UIKit
import RxSwift
import RxRelay

class MainTabBarViewModel {
    // MARK: - Properties
    private let coordinator: MainTabCoordinator
    let tabBarAppearance = BehaviorRelay<TabBarAppearanceState>(value: .default)
    
    // MARK: - Initialization
    init(coordinator: MainTabCoordinator) {
        print("🚀 Initializing MainTabBarViewModel")
        self.coordinator = coordinator
    }
    
    // MARK: - TabBar Appearance
    struct TabBarAppearanceState {
        let backgroundColor: UIColor
        let shadowColor: CGColor
        let shadowOffset: CGSize
        let shadowRadius: CGFloat
        let shadowOpacity: Float
        let cornerRadius: CGFloat
        
        static let `default` = TabBarAppearanceState(
            backgroundColor: .systemBackground,
            shadowColor: UIColor.black.cgColor,
            shadowOffset: CGSize(width: 0, height: -3),
            shadowRadius: 4,
            shadowOpacity: 0.1,
            cornerRadius: 15
        )
    }
}
