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
    private var bottomSheetView: CustomBottomSheetView!
    private var mapViewDelegate: MapViewDelegate?
    
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
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(PlaygroundCell.self, forCellReuseIdentifier: PlaygroundCell.identifier)
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
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
        setupBottomSheet()
        setupBindings()
        
        // 어노테이션 뷰 등록
        mapView.register(
            PlaygroundAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: PlaygroundAnnotationView.identifier
        )
        mapView.register(
            PlaygroundClusterAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: PlaygroundClusterAnnotationView.identifier
        )
        
        mapView.delegate = self
        viewModel.viewDidLoad.accept(())
    }
    
    // MARK: - UI Setup
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
    
    private func setupBottomSheet() {
        bottomSheetView = CustomBottomSheetView(frame: .zero)
        bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomSheetView)
        
        bottomSheetView.addContentView(tableView)
        bottomSheetView.bind(to: viewModel)
        
        NSLayoutConstraint.activate([
            bottomSheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        // Map Control Bindings
        locationButton.rx.tap
            .bind(to: viewModel.locationButtonTapped)
            .disposed(by: disposeBag)
        
        searchButton.rx.tap
            .bind(to: viewModel.searchButtonTapped)
            .disposed(by: disposeBag)
        
        // MKMapView delegate를 통한 region 변경 감지
        Observable.create { [weak self] observer -> Disposable in
            let delegate = MapViewDelegate { region in
                observer.onNext(region)
            }
            self?.mapView.delegate = delegate
            self?.mapViewDelegate = delegate
            
            return Disposables.create()
        }
        .bind(to: viewModel.regionDidChange)
        .disposed(by: disposeBag)
        
        // ViewModel Output Bindings
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
            .map { !$0 }
            .bind(to: searchButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        viewModel.shouldShowBottomSheet
            .subscribe(onNext: { [weak self] show in
                if show {
                    self?.bottomSheetView.showSheet()
                }
            })
            .disposed(by: disposeBag)
        
        // Shared playgrounds Observable
        let sharedPlaygrounds = viewModel.playgrounds.share()
        
        // TableView Binding
        sharedPlaygrounds
            .bind(to: tableView.rx.items(
                cellIdentifier: PlaygroundCell.identifier,
                cellType: PlaygroundCell.self
            )) { [weak self] index, playground, cell in
                let distance = self?.calculateDistance(for: playground)
                cell.configure(with: playground, distance: distance)
            }
            .disposed(by: disposeBag)
        
        // Map Annotations Binding
        sharedPlaygrounds
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] playgrounds in
                guard let self = self else { return }
                
                // 기존 어노테이션 제거
                let existingAnnotations = self.mapView.annotations.filter { $0 is PlaygroundAnnotation }
                self.mapView.removeAnnotations(existingAnnotations)
                
                // 새로운 어노테이션 추가
                let annotations = playgrounds.map { playground in
                    let annotation = PlaygroundAnnotation(playground: playground)
                    return annotation
                }
                self.mapView.addAnnotations(annotations)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helper Methods
    private func calculateDistance(for playground: Playground) -> Double? {
        guard let userLocation = mapView.userLocation.location else { return nil }
        let distance = playground.distance(from: userLocation)
        return distance / 1000.0  // 미터를 킬로미터로 변환
    }
    
    private func updateMapRegion(with location: MapLocation) {
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,    // 1000m로 변경
            longitudinalMeters: 1000     // 1000m로 변경
        )
        mapView.setRegion(region, animated: true)
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
    
    private func adjustMapInteraction(with percentage: CGFloat) {
        // 맵뷰 인터랙션은 항상 활성화
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = true
        mapView.isRotateEnabled = true
        
        // 버튼 UI 조정은 유지
        let scale = min(1.0, 1.0 - (percentage * 0.1))
        locationButton.transform = CGAffineTransform(scaleX: scale, y: scale)
        locationButton.alpha = 1.0 - (percentage * 0.5)
        
        searchButton.transform = locationButton.transform
        searchButton.alpha = locationButton.alpha
    }
}

// MARK: - MapView Delegate
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let cluster = annotation as? MKClusterAnnotation {
            // 클러스터 어노테이션 뷰
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: PlaygroundClusterAnnotationView.identifier,
                for: cluster
            ) as? PlaygroundClusterAnnotationView ?? PlaygroundClusterAnnotationView(
                annotation: cluster,
                reuseIdentifier: PlaygroundClusterAnnotationView.identifier
            )
            return annotationView
        } else if let playground = annotation as? PlaygroundAnnotation {
            // 일반 놀이터 어노테이션 뷰
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: PlaygroundAnnotationView.identifier,
                for: playground
            ) as? PlaygroundAnnotationView ?? PlaygroundAnnotationView(
                annotation: playground,
                reuseIdentifier: PlaygroundAnnotationView.identifier
            )
            // 클러스터링 활성화
            annotationView.clusteringIdentifier = "playground"
            return annotationView
        } else if annotation is MKUserLocation {
            return nil
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotationView = view as? PlaygroundAnnotationView {
            annotationView.animateSelection(selected: true)
        } else if let clusterView = view as? PlaygroundClusterAnnotationView {
            clusterView.animateSelection(selected: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let annotationView = view as? PlaygroundAnnotationView {
            annotationView.animateSelection(selected: false)
        } else if let clusterView = view as? PlaygroundClusterAnnotationView {
            clusterView.animateSelection(selected: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapViewDelegate?.mapView(mapView, regionDidChangeAnimated: animated)
    }
}

// MARK: - Map Region Delegate
private class MapViewDelegate: NSObject, MKMapViewDelegate {
    private let regionDidChange: (MKCoordinateRegion) -> Void
    
    init(regionDidChange: @escaping (MKCoordinateRegion) -> Void) {
        self.regionDidChange = regionDidChange
        super.init()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        regionDidChange(mapView.region)
    }
}
