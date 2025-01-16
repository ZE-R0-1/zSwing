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
            searchButton.widthAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func setupMapView() {
        mapView.delegate = self
        mapView.register(
            MKMarkerAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier
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
                return MapRegion(
                    center: currentRegion.center,
                    span: currentRegion.span
                )
            }
            .compactMap { $0 }
            .bind(to: viewModel.searchButtonTapped)
            .disposed(by: disposeBag)
        
        viewModel.playgroundAnnotations
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] annotations in
                self?.updateAnnotations(with: annotations)
            })
            .disposed(by: disposeBag)
        
        viewModel.playgroundsForList
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] playgrounds in
                self?.bottomSheetVC?.viewModel.playgrounds.accept(playgrounds)
            })
            .disposed(by: disposeBag)
        
        viewModel.locationTitle
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] title in
                self?.bottomSheetVC?.viewModel.locationTitle.accept(title)
            })
            .disposed(by: disposeBag)
        
        viewModel.currentLocation
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] location in
                self?.updateMapRegion(with: location)
            })
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
    }
    
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
    
    private func updateAnnotations(with newAnnotations: [PlaygroundAnnotation]) {
        let currentAnnotations = mapView.annotations.filter { $0 is PlaygroundAnnotation }
        mapView.removeAnnotations(currentAnnotations)
        mapView.addAnnotations(newAnnotations)
        
        if let firstAnnotation = newAnnotations.first {
            let region = MKCoordinateRegion(
                center: firstAnnotation.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            mapView.setRegion(region, animated: true)
        }
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
        
        if let playground = annotation as? PlaygroundAnnotation {
            let identifier = MKMapViewDefaultAnnotationViewReuseIdentifier
            let view = mapView.dequeueReusableAnnotationView(
                withIdentifier: identifier,
                for: annotation
            ) as? MKMarkerAnnotationView
            
            view?.glyphImage = UIImage(systemName: "figure.play")
            view?.markerTintColor = .systemBlue
            view?.canShowCallout = true
            
            return view
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        if let playgroundAnnotation = annotation as? PlaygroundAnnotation {
            // Handle playground selection
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
