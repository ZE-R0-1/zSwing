//
//  PlaygroundMapView.swift
//  zSwing
//
//  Created by USER on 1/20/25.
//

import UIKit
import MapKit
import RxSwift
import RxRelay

final class PlaygroundMapView: UIView {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var annotations: [PlaygroundAnnotation] = []
    private var selectedAnnotation: MKAnnotation?
    private let locationManager: LocationManager
    private let visibleRegion = PublishRelay<MKCoordinateRegion>()
    let annotationSelected = PublishRelay<BottomSheetType>()

    var visibleRegionObservable: Observable<MKCoordinateRegion> {
        return visibleRegion.asObservable()
    }
    
    // MARK: - UI Components
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()
    
    private let emptyStateAlert: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "이 카테고리의 놀이터가 없습니다"
        label.textAlignment = .center
        label.textColor = .label
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var currentLocationButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 22
        button.setImage(UIImage(systemName: "location"), for: .normal)
        button.tintColor = HomeViewModel.themeColor
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        super.init(frame: .zero)
        setupUI()
        configureMap()
        setupInitialLocation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        addSubview(mapView)
        addSubview(emptyStateAlert)
        addSubview(currentLocationButton)
        emptyStateAlert.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: topAnchor),
            mapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            emptyStateAlert.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            emptyStateAlert.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyStateAlert.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.9),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateAlert.topAnchor, constant: 12),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateAlert.leadingAnchor, constant: 24),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateAlert.trailingAnchor, constant: -24),
            emptyStateLabel.bottomAnchor.constraint(equalTo: emptyStateAlert.bottomAnchor, constant: -12),
            
            currentLocationButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -24),
            currentLocationButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -126),
            currentLocationButton.widthAnchor.constraint(equalToConstant: 44),
            currentLocationButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func configureMap() {
        mapView.delegate = self
        mapView.register(
            PlaygroundAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: "PlaygroundAnnotation"
        )
        mapView.register(
            PlaygroundClusterAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: "PlaygroundCluster"
        )
    }
    
    private func setupInitialLocation() {
        locationManager.currentLocationObservable
            .compactMap { $0 }
            .take(1)
            .subscribe(onNext: { [weak self] location in
                let region = MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )
                self?.mapView.setRegion(region, animated: false)
                
                // 확대/축소 기능 비활성화
                self?.mapView.isZoomEnabled = false
            })
            .disposed(by: disposeBag)
    }

    
    // MARK: - Configuration
    func configure(with viewModel: RideCategoryViewModel) {
        // 지도 보기 모드 전환, 카테고리 변경, 지도 영역 변경시에만 확인
        Observable.merge([
            viewModel.isMapMode.filter { $0 }.map { _ in () },  // 맵뷰로 전환될 때
            viewModel.selectedIndex.map { _ in () },  // 카테고리 변경될 때
            visibleRegionObservable.map { _ in () }   // 지도 영역 변경될 때
        ])
        .withLatestFrom(viewModel.filteredPlaygrounds)
        .subscribe(onNext: { [weak self] playgrounds in
            self?.updateAnnotations(with: playgrounds)
            
            if playgrounds.isEmpty {
                self?.showEmptyStateAlert()
            } else {
                self?.hideEmptyStateAlert()
            }
        })
        .disposed(by: disposeBag)
        
        // 현재 위치 버튼 바인딩
        currentLocationButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self,
                      let userLocation = self.mapView.userLocation.location else { return }
                
                let region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )
                self.mapView.setRegion(region, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func updateAnnotations(with playgrounds: [Playground]) {
        // Remove existing annotations
        mapView.removeAnnotations(annotations)
        annotations.removeAll()
        
        // Add new annotations
        annotations = playgrounds.map { playground in
            let annotation = PlaygroundAnnotation(playground: playground)
            annotation.coordinate = playground.coordinate
            annotation.title = playground.name
            annotation.subtitle = playground.address
            return annotation
        }
        
        mapView.addAnnotations(annotations)
    }
    
    private func showEmptyStateAlert() {
        emptyStateAlert.alpha = 0
        emptyStateAlert.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.emptyStateAlert.alpha = 1
        } completion: { _ in
            // 3초 후에 자동으로 사라지게 함
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.hideEmptyStateAlert()
            }
        }
    }
    
    private func hideEmptyStateAlert() {
        UIView.animate(withDuration: 0.3) {
            self.emptyStateAlert.alpha = 0
        } completion: { _ in
            self.emptyStateAlert.isHidden = true
        }
    }
}

// MARK: - MKMapViewDelegate
extension PlaygroundMapView: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        // 클러스터 어노테이션 처리
        if let cluster = annotation as? MKClusterAnnotation {
            let identifier = "PlaygroundCluster"
            
            var annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: identifier) as? PlaygroundClusterAnnotationView
            
            if annotationView == nil {
                annotationView = PlaygroundClusterAnnotationView(
                    annotation: cluster,
                    reuseIdentifier: identifier
                )
            } else {
                annotationView?.annotation = cluster
            }
            
            annotationView?.configure(with: cluster.memberAnnotations.count)
            return annotationView
        }
        
        // 일반 어노테이션 처리
        let identifier = "PlaygroundAnnotation"
        
        var annotationView = mapView.dequeueReusableAnnotationView(
            withIdentifier: identifier) as? PlaygroundAnnotationView
        
        if annotationView == nil {
            annotationView = PlaygroundAnnotationView(
                annotation: annotation,
                reuseIdentifier: identifier
            )
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        selectedAnnotation = annotation
        if let cluster = annotation as? MKClusterAnnotation {
            let playgrounds = cluster.memberAnnotations.compactMap { annotation in
                (annotation as? PlaygroundAnnotation)?.playground
            }
            annotationSelected.accept(.cluster(playgrounds: playgrounds))
        } else if let playgroundAnnotation = annotation as? PlaygroundAnnotation {
            annotationSelected.accept(.single(playground: playgroundAnnotation.playground))
        }
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        visibleRegion.accept(mapView.region)
    }
    
    func deselectAnnotation() {
        if let annotation = selectedAnnotation {
            mapView.deselectAnnotation(annotation, animated: true)
            selectedAnnotation = nil
        }
    }
}

// MARK: - Custom Annotation
class PlaygroundAnnotation: MKPointAnnotation {
    let playground: Playground
    
    init(playground: Playground) {
        self.playground = playground
        super.init()
    }
}

// MARK: - MKCoordinateRegion Extension
extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D], latitudinalMeters: CLLocationDistance, longitudinalMeters: CLLocationDistance) {
        guard !coordinates.isEmpty else {
            self = MKCoordinateRegion()
            return
        }
        
        let minLat = coordinates.map { $0.latitude }.min()!
        let maxLat = coordinates.map { $0.latitude }.max()!
        let minLon = coordinates.map { $0.longitude }.min()!
        let maxLon = coordinates.map { $0.longitude }.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        self.init(
            center: center,
            latitudinalMeters: latitudinalMeters,
            longitudinalMeters: longitudinalMeters
        )
    }
}
