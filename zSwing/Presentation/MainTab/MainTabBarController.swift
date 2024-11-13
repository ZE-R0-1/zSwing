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
    // MARK: - Properties
    private var viewModel: MainTabBarViewModel!
    private let disposeBag = DisposeBag()
    
    // MARK: - Configuration
    func configure(with viewModel: MainTabBarViewModel) {
        print("🔧 Configuring MainTabBarController")
        self.viewModel = viewModel
        setupBindings()
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📱 MainTabBarController viewDidLoad")
        configureTabBar()
        
        // 애니메이션 비활성화 설정 추가
        self.view.layer.speed = 100  // 실질적으로 애니메이션을 눈에 띄지 않게 함
        self.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("📐 MainTabBarController viewDidLayoutSubviews")
        tabBar.layer.shadowPath = UIBezierPath(rect: tabBar.bounds).cgPath
    }
    
    // MARK: - Setup Methods
    private func setupBindings() {
        guard let viewModel = viewModel else {
            print("⚠️ ViewModel not set")
            return
        }
        
        viewModel.tabBarAppearance
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                print("🎨 Applying tab bar appearance")
                self?.applyAppearanceState(state)
            })
            .disposed(by: disposeBag)
    }
    
    private func configureTabBar() {
        print("🎨 Configuring tab bar basic appearance")
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
        
        // 탭바 모서리 처리
        tabBar.layer.cornerRadius = 15
        tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // appearance 적용
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
    
    private func applyAppearanceState(_ state: MainTabBarViewModel.TabBarAppearanceState) {
        print("🎨 Applying custom tab bar appearance state")
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
}

// MARK: - UITabBarControllerDelegate
extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // 뷰 전환 시 애니메이션 제거
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // 커스텀 전환 애니메이션 제거
        return nil
    }
}
