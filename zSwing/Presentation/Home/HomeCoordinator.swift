//
//  HomeCoordinator.swift
//  zSwing
//
//  Created by USER on 1/17/25.
//

import UIKit

protocol HomeCoordinator: Coordinator {
    func showRideCategory(for facility: PlaygroundFacility)
}

class DefaultHomeCoordinator: HomeCoordinator {
    let navigationController: UINavigationController
    let locationManager: LocationManager
    private let diContainer: AppDIContainer
    
    init(navigationController: UINavigationController, diContainer: AppDIContainer, locationManager: LocationManager) {
        self.navigationController = navigationController
        self.locationManager = locationManager
        self.diContainer = diContainer
    }
    
    func start() {
        let viewController = diContainer.makeHomeViewController(coordinator: self)
        navigationController.setNavigationBarHidden(true, animated: false)  // 네비게이션 바 숨기기
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func showRideCategory(for facility: PlaygroundFacility) {
        let viewModel = RideCategoryViewModel(facility: facility, locationManager: locationManager)
        let viewController = RideCategoryViewController(viewModel: viewModel)
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }
}
