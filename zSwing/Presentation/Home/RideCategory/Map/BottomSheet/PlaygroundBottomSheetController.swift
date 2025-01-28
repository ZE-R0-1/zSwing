//
//  PlaygroundBottomSheetController.swift
//  zSwing
//
//  Created by USER on 1/28/25.
//

import UIKit
import RxSwift
import RxRelay
import CoreLocation

enum BottomSheetType {
    case single(playground: Playground)
    case cluster(playgrounds: [Playground])
}

class PlaygroundBottomSheetController: UIViewController {
    private let disposeBag = DisposeBag()
    let dismissObservable = PublishRelay<Void>()
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dismissObservable.accept(())
    }
    
    init(type: BottomSheetType, locationManager: LocationManager) {
        super.init(nibName: nil, bundle: nil)
        
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        
        switch type {
        case .single(let playground):
            guard let location = locationManager.currentLocation else { return }
            let distance = location.distance(from: CLLocation(
                latitude: playground.coordinate.latitude,
                longitude: playground.coordinate.longitude
            ))
            let viewModel = PlaygroundDetailViewModel(playground: playground, distance: distance)
            let detailView = PlaygroundDetailView()
            detailView.configure(with: viewModel)
            view = detailView
            
        case .cluster(let playgrounds):
            guard let location = locationManager.currentLocation else { return }
            let viewModel = PlaygroundClusterViewModel(playgrounds: playgrounds, currentLocation: location)
            let clusterView = PlaygroundClusterView()
            clusterView.configure(with: viewModel)
            view = clusterView
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
