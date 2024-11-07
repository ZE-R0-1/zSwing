//
//  MainTabBarController.swift
//  zSwing
//
//  Created by USER on 10/21/24.
//

import UIKit
import RxSwift
import RxCocoa

class MainTabBarController: UITabBarController {
    private var viewModel: MainTabBarViewModel!
    private let disposeBag = DisposeBag()
    
    func configure(with viewModel: MainTabBarViewModel) {
        self.viewModel = viewModel
        setupBindings()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabBar()
        hideNavigationBars()
    }
    
    private func setupBindings() {
        viewModel.tabBarAppearance
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.applyAppearanceState(state)
            })
            .disposed(by: disposeBag)
    }
    
    private func applyAppearanceState(_ state: MainTabBarViewModel.TabBarAppearanceState) {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowImage = UIImage()
        appearance.backgroundColor = state.backgroundColor
        
        tabBar.layer.masksToBounds = false
        tabBar.layer.shadowColor = state.shadowColor
        tabBar.layer.shadowOffset = state.shadowOffset
        tabBar.layer.shadowRadius = state.shadowRadius
        tabBar.layer.shadowOpacity = state.shadowOpacity
        tabBar.layer.cornerRadius = state.cornerRadius
        tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
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
    
    private func hideNavigationBars() {
        viewControllers?.forEach { navigationController in
            (navigationController as? UINavigationController)?.navigationBar.isHidden = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tabBar.layer.shadowPath = UIBezierPath(rect: tabBar.bounds).cgPath
    }
}

