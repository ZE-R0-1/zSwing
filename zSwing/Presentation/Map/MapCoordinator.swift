//
//  MapCoordinator.swift
//  zSwing
//
//  Created by USER on 12/2/24.
//

import UIKit
import RxSwift
import MapKit

protocol MapCoordinator: Coordinator {
    func showMap()
}

class DefaultMapCoordinator: MapCoordinator {
    let navigationController: UINavigationController
    private let diContainer: AppDIContainer
    private let disposeBag = DisposeBag()
    
    init(navigationController: UINavigationController, diContainer: AppDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }
    
    func start() {
        showMap()
    }
    
    func showMap() {
        let mapVC = makeMapViewController()
        navigationController.setViewControllers([mapVC], animated: false)
    }
    
    private func makeMapViewController() -> MapViewController {
        return diContainer.makeMapViewController(coordinator: self)
    }
}
