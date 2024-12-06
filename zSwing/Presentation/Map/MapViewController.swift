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
    private var bottomSheetVC: PlaygroundListViewController?
    private var currentAnnotations: [PlaygroundAnnotation] = []
    
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
    init(viewModel: MapViewModel) {
        self.viewModel = viewModel
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
        mapView.register(
            PlaygroundAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: PlaygroundAnnotationView.identifier
        )
        mapView.register(
            PlaygroundClusterAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: PlaygroundClusterAnnotationView.identifier
        )
    }
    
    private func setupBindings() {
        locationButton.rx.tap
            .bind(to: viewModel.locationButtonTapped)
            .disposed(by: disposeBag)
        
        searchButton.rx.tap
            .map { [weak self] _ -> MapRegion in
                guard let region = self?.mapView.region else { return .defaultRegion }
                return MapRegion(
                    center: region.center,
                    span: region.span
                )
            }
            .do(onNext: { [weak self] region in
                self?.viewModel.searchButtonTapped.accept(region)
            })
            .subscribe(onNext: { [weak self] region in
                self?.bottomSheetVC?.fetchPlaygrounds(for: region)
            })
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
        // 기존 어노테이션 제거
        mapView.removeAnnotations(currentAnnotations)
        currentAnnotations.removeAll()
        
        // 새로운 어노테이션 추가
        let annotations = playgrounds.map { playground -> PlaygroundAnnotation in
            let annotation = PlaygroundAnnotation(playground: playground)
            annotation.coordinate = playground.coordinate
            annotation.title = playground.pfctNm
            // 클러스터링을 위한 식별자 설정
            annotation.clusteringIdentifier = "playground"
            return annotation
        }
        
        currentAnnotations = annotations
        mapView.addAnnotations(annotations)
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
        switch annotation {
        case is MKClusterAnnotation:
            let cluster = annotation as! MKClusterAnnotation
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: PlaygroundClusterAnnotationView.identifier,
                for: annotation
            ) as! PlaygroundClusterAnnotationView
            
            annotationView.configure(with: cluster)
            return annotationView
            
        case is PlaygroundAnnotation:
            let playground = annotation as! PlaygroundAnnotation
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: PlaygroundAnnotationView.identifier,
                for: annotation
            ) as! PlaygroundAnnotationView
            
            annotationView.configure(with: playground)
            return annotationView
            
        default:
            return nil
        }
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
