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
        mapVC.addChild(playgroundListVC)
        mapVC.view.addSubview(playgroundListVC.view)
        playgroundListVC.didMove(toParent: mapVC)
        
        // PlaygroundListVC의 view가 화면 전체를 차지하도록 제약조건 설정
        playgroundListVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playgroundListVC.view.leadingAnchor.constraint(equalTo: mapVC.view.leadingAnchor),
            playgroundListVC.view.trailingAnchor.constraint(equalTo: mapVC.view.trailingAnchor),
            playgroundListVC.view.bottomAnchor.constraint(equalTo: mapVC.view.bottomAnchor),
            playgroundListVC.view.heightAnchor.constraint(equalTo: mapVC.view.heightAnchor)
        ])
    }
    
    func showSearchResult() {
    }
    
    private func makeMapViewController() -> MapViewController {
        return diContainer.makeMapViewController()
    }
}
