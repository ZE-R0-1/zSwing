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
    weak var coordinator: MapCoordinator?
    
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
            EnhancedPlaygroundAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: EnhancedPlaygroundAnnotationView.identifier
        )
        mapView.register(
            EnhancedPlaygroundClusterAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: EnhancedPlaygroundClusterAnnotationView.identifier
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
    
    func setupBottomSheet() {
        bottomSheetView = CustomBottomSheetView(frame: .zero)
        bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.delegate = self
        view.addSubview(bottomSheetView)
        
        // 초기 콘텐츠 설정
        bottomSheetView.transition(to: .playgroundList, animated: false)
        bottomSheetView.bind(to: viewModel)  // 이 부분 추가
        
        // 놀이터 선택 노티피케이션 관찰
        NotificationCenter.default.rx.notification(.playgroundSelected)
            .subscribe(onNext: { [weak self] notification in
                guard let playground = notification.userInfo?["playground"] as? Playground else { return }
                self?.bottomSheetView.transition(to: .playgroundDetail(playground))
            })
            .disposed(by: disposeBag)
        
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
        
        // BottomSheet 바인딩
        bottomSheetView.bind(to: viewModel)
        
        // Map Annotations Binding
        viewModel.playgrounds
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
    
    // 클러스터 내 놀이터들을 모두 포함하는 지도 영역 계산
    private func calculateRegion(for playgrounds: [Playground]) -> MKCoordinateRegion {
        var minLat = Double.infinity
        var maxLat = -Double.infinity
        var minLon = Double.infinity
        var maxLon = -Double.infinity
        
        playgrounds.forEach { playground in
            minLat = min(minLat, playground.coordinate.latitude)
            maxLat = max(maxLat, playground.coordinate.latitude)
            minLon = min(minLon, playground.coordinate.longitude)
            maxLon = max(maxLon, playground.coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - MapView Delegate
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let cluster = annotation as? MKClusterAnnotation {
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: EnhancedPlaygroundClusterAnnotationView.identifier,
                for: cluster
            ) as? EnhancedPlaygroundClusterAnnotationView ?? EnhancedPlaygroundClusterAnnotationView(
                annotation: cluster,
                reuseIdentifier: EnhancedPlaygroundClusterAnnotationView.identifier
            )
            annotationView.configure(with: cluster)
            return annotationView
        } else if let playground = annotation as? PlaygroundAnnotation {
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: EnhancedPlaygroundAnnotationView.identifier,
                for: playground
            ) as? EnhancedPlaygroundAnnotationView ?? EnhancedPlaygroundAnnotationView(
                annotation: playground,
                reuseIdentifier: EnhancedPlaygroundAnnotationView.identifier
            )
            annotationView.clusteringIdentifier = "playground"
            return annotationView
        }
        return nil
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let clusterView = view as? EnhancedPlaygroundClusterAnnotationView {
            clusterView.animateSelection(selected: true)
            
            // 클러스터에 포함된 놀이터들을 가져옴
            let clusterPlaygrounds = clusterView.getPlaygrounds()
            
            // PlaygroundListContent로 전환하고 데이터를 필터링
            bottomSheetView.transition(to: .playgroundList, animated: true)
            
            // 클러스터에 포함된 놀이터만 표시하도록 필터링
            viewModel.filterPlaygrounds(clusterPlaygrounds)
            
            // 시트를 보여줌
            bottomSheetView.showSheet()
            
        } else if let annotationView = view as? EnhancedPlaygroundAnnotationView,
                  let playgroundAnnotation = annotationView.annotation as? PlaygroundAnnotation {
            annotationView.animateSelection(selected: true)
            bottomSheetView.transition(to: .playgroundDetail(playgroundAnnotation.playground))
        }
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let clusterView = view as? EnhancedPlaygroundClusterAnnotationView {
            clusterView.animateSelection(selected: false)
            // 클러스터 선택 해제시 전체 놀이터 목록으로 복원
            viewModel.resetPlaygroundFilter()
        } else if let annotationView = view as? EnhancedPlaygroundAnnotationView {
            annotationView.animateSelection(selected: false)
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

extension MapViewController: BottomSheetDelegate {
    func bottomSheet(_ sheet: CustomBottomSheetView, didSelectContent content: BottomSheetContent) {
        // 필요한 경우 콘텐츠 선택 처리
    }
    
    func bottomSheet(_ sheet: CustomBottomSheetView, heightDidChange height: CGFloat) {
        // 높이 변경에 따른 처리
        adjustMapInteraction(with: height)
    }
}
