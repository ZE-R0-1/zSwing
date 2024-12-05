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
    func showPlaygroundList()
    func showSearchResult()
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
        showPlaygroundList()
    }
    
    func showMap() {
        let mapVC = makeMapViewController()
        navigationController.setViewControllers([mapVC], animated: false)
    }
    
    func showPlaygroundList() {
        guard let mapVC = navigationController.viewControllers.first as? MapViewController else { return }
        
        let playgroundListVC = diContainer.makePlaygroundListViewController()
        mapVC.addBottomSheet(playgroundListVC) // 수정된 부분
    }
    
    func showSearchResult() {
    }
    
    private func makeMapViewController() -> MapViewController {
        return diContainer.makeMapViewController()
    }
}
