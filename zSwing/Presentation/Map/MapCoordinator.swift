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
    func showPlaygroundDetail(_ playground: Playground)
    func showPlaygroundList()
    func showSearchResult()
}

class DefaultMapCoordinator: MapCoordinator {
    let navigationController: UINavigationController
    private let diContainer: AppDIContainer
    private let disposeBag = DisposeBag()
    
    private weak var bottomSheetView: CustomBottomSheetView?
    
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
    
    func showPlaygroundDetail(_ playground: Playground) {
        bottomSheetView?.transition(to: .playgroundDetail(playground), animated: true)
    }
    
    func showPlaygroundList() {
        bottomSheetView?.transition(to: .playgroundList, animated: true)
    }
    
    func showSearchResult() {
        bottomSheetView?.showSheet()
    }
    
    private func makeMapViewController() -> MapViewController {
        let useCase = DefaultMapUseCase(repository: DefaultMapRepository())
        let playgroundUseCase = DefaultPlaygroundUseCase(repository: DefaultPlaygroundRepository())
        let viewModel = MapViewModel(useCase: useCase, playgroundUseCase: playgroundUseCase)
        let viewController = MapViewController(viewModel: viewModel)
        viewController.coordinator = self
        return viewController
    }
    
    func setBottomSheetView(_ bottomSheet: CustomBottomSheetView) {
        self.bottomSheetView = bottomSheet
    }
}
