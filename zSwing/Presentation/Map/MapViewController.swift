//
//  MapViewController.swift
//  zSwing
//
//  Created by USER on 11/12/24.
//

import UIKit
import RxSwift
import RxCocoa
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    // MARK: - Properties
    private let viewModel: MapViewModel
    private let disposeBag = DisposeBag()
    weak var coordinator: MapCoordinator?
    private let diContainer: AppDIContainer
    private var bottomSheetVC: PlaygroundListViewController?
    private var currentAnnotations: [PlaygroundAnnotation] = []
    private var lastSearchedRegion: MKCoordinateRegion?
    
    // MARK: - UI Components
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.showsUserLocation = true
        return map
    }()
    
    private let locationButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "location.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))
        button.setImage(image, for: .normal)
        button.backgroundColor = .white
        button.tintColor = .systemBlue
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("이 지역 검색", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .white
        button.tintColor = .systemBlue
        button.layer.cornerRadius = 16
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Initialization
    init(viewModel: MapViewModel, coordinator: MapCoordinator, diContainer: AppDIContainer) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        self.diContainer = diContainer
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMapView()
        setupBindings()
        viewModel.initialRegion.accept(mapView.region)
        viewModel.viewDidLoad.accept(())
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(mapView)
        view.addSubview(locationButton)
        view.addSubview(searchButton)
        locationButton.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            locationButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            locationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            locationButton.widthAnchor.constraint(equalToConstant: 40),
            locationButton.heightAnchor.constraint(equalToConstant: 40),
            
            searchButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            searchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchButton.heightAnchor.constraint(equalToConstant: 32),
            searchButton.widthAnchor.constraint(equalToConstant: 100),
            
            activityIndicator.centerXAnchor.constraint(equalTo: locationButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: locationButton.centerYAnchor)
        ])
    }

    private func setupMapView() {
        mapView.delegate = self
        
        // 일반 어노테이션 뷰를 먼저 등록
        mapView.register(
            PlaygroundAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: PlaygroundAnnotationView.identifier
        )
        
        // 그 다음 클러스터 어노테이션 뷰 등록
        mapView.register(
            PlaygroundClusterAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier
        )
    }
    
    private func setupBindings() {
        locationButton.rx.tap
            .bind(to: viewModel.locationButtonTapped)
            .disposed(by: disposeBag)
        
        searchButton.rx.tap
            .map { [weak self] _ -> MapRegion? in
                guard let self = self else { return nil }
                let currentRegion = self.mapView.region
                
                if let lastRegion = self.lastSearchedRegion,
                   self.isRegionSimilar(lastRegion, currentRegion) {
                    return nil
                }
                
                self.lastSearchedRegion = currentRegion
                let mapRegion = MapRegion(
                    center: currentRegion.center,
                    span: currentRegion.span
                )
                
                // PlaygroundListView 업데이트는 여기서 수행
                self.bottomSheetVC?.fetchPlaygrounds(for: mapRegion)
                
                return mapRegion
            }
            .compactMap { $0 }
            .subscribe()
            .disposed(by: disposeBag)
        
        viewModel.currentLocation
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] location in
                self?.updateMapRegion(with: location)
            })
            .disposed(by: disposeBag)
        
        viewModel.isLoading
            .bind(to: activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        viewModel.error
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
                self?.showAlert(message: error.localizedDescription)
            })
            .disposed(by: disposeBag)
        
        viewModel.shouldShowSearchButton
            .map { show in !show }
            .bind(to: searchButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        // 놀이터 데이터 바인딩
        viewModel.playgroundListViewModel.playgrounds
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] playgroundsWithDistance in
                self?.updateAnnotations(with: playgroundsWithDistance.map { $0.playground })
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helper Methods
    private func updateMapRegion(with location: Location) {
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapView.setRegion(region, animated: true)
    }
    
    private func updateAnnotations(with playgrounds: [Playground]) {
        // 기존 어노테이션과 새로운 어노테이션 비교를 위한 집합 생성
        let existingAnnotations = Set(currentAnnotations)
        let newAnnotations = Set(playgrounds.map { playground -> PlaygroundAnnotation in
            let annotation = PlaygroundAnnotation(playground: playground)
            return annotation
        })
        
        // 제거해야 할 어노테이션과 추가해야 할 어노테이션 계산
        let annotationsToRemove = existingAnnotations.subtracting(newAnnotations)
        let annotationsToAdd = newAnnotations.subtracting(existingAnnotations)
        
        // 제거할 어노테이션만 제거
        mapView.removeAnnotations(Array(annotationsToRemove))
        
        // 새로운 어노테이션만 추가
        mapView.addAnnotations(Array(annotationsToAdd))
        
        // currentAnnotations 업데이트
        currentAnnotations = Array(newAnnotations)
    }

    // 두 지도 영역이 유사한지 확인하는 헬퍼 메서드
    private func isRegionSimilar(_ region1: MKCoordinateRegion, _ region2: MKCoordinateRegion) -> Bool {
        let centerThreshold = 0.01  // 약 1km
        let spanThreshold = 0.01    // 약 1km
        
        let latDiff = abs(region1.center.latitude - region2.center.latitude)
        let lonDiff = abs(region1.center.longitude - region2.center.longitude)
        let spanLatDiff = abs(region1.span.latitudeDelta - region2.span.latitudeDelta)
        let spanLonDiff = abs(region1.span.longitudeDelta - region2.span.longitudeDelta)
        
        return latDiff < centerThreshold &&
               lonDiff < centerThreshold &&
               spanLatDiff < spanThreshold &&
               spanLonDiff < spanThreshold
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: "오류",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Public Methods
    func addBottomSheet(_ bottomSheetVC: PlaygroundListViewController) {
        self.bottomSheetVC = bottomSheetVC
        addChild(bottomSheetVC)
        view.addSubview(bottomSheetVC.view)
        bottomSheetVC.didMove(toParent: self)
        
        setupBottomSheetConstraints()
    }
    
    private func setupBottomSheetConstraints() {
        guard let bottomSheetVC = bottomSheetVC else { return }
        
        bottomSheetVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bottomSheetVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheetVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheetVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomSheetVC.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.9)
        ])
    }
}

// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        if let cluster = annotation as? MKClusterAnnotation {
            let identifier = MKMapViewDefaultClusterAnnotationViewReuseIdentifier
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: identifier,
                for: annotation
            ) as! PlaygroundClusterAnnotationView
            
            annotationView.configure(with: cluster)
            return annotationView
        }
        
        if let playground = annotation as? PlaygroundAnnotation {
            let identifier = PlaygroundAnnotationView.identifier
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: identifier,
                for: annotation
            ) as! PlaygroundAnnotationView
            
            annotationView.configure(with: playground)
            return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        if let cluster = annotation as? MKClusterAnnotation,
           let clusterView = mapView.view(for: annotation) as? PlaygroundClusterAnnotationView {
            clusterView.animateSelection(selected: true)
            
            // 클러스터에 포함된 놀이터 목록 처리
            let playgrounds = clusterView.getPlaygrounds()
            // TODO: 클러스터 선택 시 처리 (예: 목록 표시)
            
        } else if let playgroundAnnotation = annotation as? PlaygroundAnnotation,
                  let annotationView = mapView.view(for: annotation) as? PlaygroundAnnotationView {
            annotationView.animateSelection(selected: true)
            // TODO: 단일 놀이터 선택 시 처리
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect annotation: MKAnnotation) {
        if let clusterView = mapView.view(for: annotation) as? PlaygroundClusterAnnotationView {
            clusterView.animateSelection(selected: false)
        } else if let annotationView = mapView.view(for: annotation) as? PlaygroundAnnotationView {
            annotationView.animateSelection(selected: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        viewModel.mapRegionDidChange.accept(mapView.region)
    }
}

extension MapViewController {
    func presentPlaygroundView(_ playgroundView: PlaygroundViewController) {
        // 기존 bottomSheet를 제거하고 새로운 playgroundView를 표시
        bottomSheetVC?.willMove(toParent: nil)
        bottomSheetVC?.view.removeFromSuperview()
        bottomSheetVC?.removeFromParent()
        
        addChild(playgroundView)
        view.addSubview(playgroundView.view)
        playgroundView.didMove(toParent: self)
        
        // constraint 설정
        playgroundView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playgroundView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playgroundView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playgroundView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            playgroundView.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.9)
        ])
    }
}
