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
    private let diContainer: AppDIContainer
    
    init(navigationController: UINavigationController, diContainer: AppDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }
    
    func start() {
        let viewController = diContainer.makeHomeViewController(coordinator: self)
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func showRideCategory(for facility: PlaygroundFacility) {
        let viewController = RideCategoryViewController(facility: facility)
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }
}
