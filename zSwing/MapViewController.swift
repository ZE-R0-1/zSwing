//
//  MapViewController.swift
//  zSwing
//
//  Created by USER on 10/21/24.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    // MARK: - Properties
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.cameraZoomRange = MKMapView.CameraZoomRange(
            minCenterCoordinateDistance: 500,
            maxCenterCoordinateDistance: 20000
        )
        return map
    }()
    
    private let bottomSheet = BottomSheetView()
    private let rideDetailView = RideDetailView()
    
    private let currentLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "location.fill"), for: .normal)
        button.backgroundColor = .white
        button.tintColor = .systemBlue
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 2
        button.layer.shadowOpacity = 0.3
        return button
    }()
    
    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("이 지역 검색", for: .normal)
        button.backgroundColor = .white
        button.tintColor = .systemBlue
        button.layer.cornerRadius = 20
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 2
        button.layer.shadowOpacity = 0.3
        return button
    }()
    
    private let locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let firebaseService = FirebasePlaygroundService()
    private var currentAnnotations: [RideAnnotation] = []
    
    private var currentCategory: RideCategory? {
        didSet {
            updateAnnotationsForCategory()
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocationManager()
        setupMapTapGesture()
        
        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )
        mapView.setRegion(initialRegion, animated: false)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        title = "놀이기구 지도"
        
        setupMapView()
        setupButtons()
        setupLoadingIndicator()
        setupBottomSheet()
    }
    
    private func setupMapView() {
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
    }
    
    private func setupBottomSheet() {
        view.addSubview(bottomSheet)
        bottomSheet.setContent(rideDetailView)
        bottomSheet.heightConstraint = bottomSheet.heightAnchor.constraint(equalToConstant: bottomSheet.minimumHeight)
        
        NSLayoutConstraint.activate([
            bottomSheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheet.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomSheet.heightConstraint!
        ])
        
        bottomSheet.onHeightChanged = { [weak self] height in
            self?.updateMapLayoutMargins(bottomInset: height)
        }
        
        // Show default bottom sheet state
        rideDetailView.showDefaultState(
            with: currentAnnotations,
            userLocation: locationManager.location
        ) { [weak self] category in
            self?.currentCategory = category
        }
    }
    
    private func setupButtons() {
        view.addSubview(searchButton)
        view.addSubview(currentLocationButton)
        
        NSLayoutConstraint.activate([
            searchButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            searchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: 100),
            searchButton.heightAnchor.constraint(equalToConstant: 40),
            
            currentLocationButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            currentLocationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            currentLocationButton.widthAnchor.constraint(equalToConstant: 40),
            currentLocationButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        currentLocationButton.addTarget(self, action: #selector(currentLocationButtonTapped), for: .touchUpInside)
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
    }
    
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            let seoulRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            )
            mapView.setRegion(seoulRegion, animated: false)
        }
    }
    
    private func setupMapTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        tapGesture.delegate = self
        mapView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    @objc private func currentLocationButtonTapped() {
        locationManager.startUpdatingLocation()
        animateButton(currentLocationButton)
    }
    
    @objc private func searchButtonTapped() {
        animateButton(searchButton)
        searchInVisibleRegion()
    }
    
    @objc private func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        if let tappedAnnotation = mapView.annotations.first(where: { annotation in
            guard let annotationView = mapView.view(for: annotation) else { return false }
            return annotationView.frame.contains(point)
        }) {
            // 어노테이션을 탭했을 때는 아무 동작도 하지 않음
            return
        }
        
        // 어노테이션이 아닌 지도를 탭했을 때만 바텀시트를 기본 상태로 되돌림
        rideDetailView.showDefaultState(
            with: currentAnnotations,
            userLocation: locationManager.location
        ) { [weak self] category in
            self?.currentCategory = category
        }
        
        // 애니메이션과 함께 minimumHeight로 변경
        bottomSheet.animateHeight(to: bottomSheet.minimumHeight)
    }
    
    func updateMapLayoutMargins(bottomInset: CGFloat) {
        let safeAreaBottom = view.safeAreaInsets.bottom
        mapView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset - safeAreaBottom, right: 0)
    }
    
    private func animateButton(_ button: UIButton) {
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = .identity
            }
        }
    }
    
    // MARK: - Search Methods
    private func searchInVisibleRegion() {
        loadingIndicator.startAnimating()
        
        firebaseService.searchPlaygrounds(in: mapView.region) { [weak self] (annotations, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching playgrounds: \(error)")
                self.showAlert(title: "검색 실패", message: "데이터를 가져오는데 실패했습니다.")
                self.loadingIndicator.stopAnimating()
                return
            }
            
            if let annotations = annotations {
                self.updateAnnotations(with: annotations)
                
                // 현재 카테고리에 맞게 필터링된 어노테이션 생성
                let filteredAnnotations: [RideAnnotation]
                if let category = self.currentCategory {
                    filteredAnnotations = annotations.filter { annotation in
                        return annotation.rideInfo.rideType == category.rawValue
                    }
                } else {
                    filteredAnnotations = annotations
                }
                
                // Update bottom sheet with filtered annotations
                self.rideDetailView.showDefaultState(
                    with: filteredAnnotations,
                    userLocation: self.locationManager.location
                ) { [weak self] category in
                    self?.currentCategory = category
                }
                
                // 검색 완료 후 바텀시트 높이를 애니메이션과 함께 defaultHeight로 변경
                self.bottomSheet.animateHeight(to: self.bottomSheet.defaultHeight)
                
                let message = annotations.isEmpty ?
                "이 지역에 놀이기구가 없습니다" :
                "이 지역에서 \(annotations.count)개의 놀이기구를 찾았습니다"
                self.showToast(message: message)
            }
            
            self.loadingIndicator.stopAnimating()
        }
    }
    
    private func updateAnnotations(with newAnnotations: [RideAnnotation]) {
        mapView.removeAnnotations(currentAnnotations)
        currentAnnotations = newAnnotations
        updateAnnotationsForCategory()
    }
    
    private func updateAnnotationsForCategory() {
        mapView.removeAnnotations(mapView.annotations)
        
        if let category = currentCategory {
            let filteredAnnotations = currentAnnotations.compactMap { annotation -> MKAnnotation? in
                guard let rideAnnotation = annotation as? RideAnnotation else { return nil }
                return rideAnnotation.rideInfo.rideType == category.rawValue ? rideAnnotation : nil
            }
            mapView.addAnnotations(filteredAnnotations)
        } else {
            mapView.addAnnotations(currentAnnotations)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func showToast(message: String) {
        let padding: CGFloat = 8
        
        let containerView = UIView()
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        containerView.layer.cornerRadius = 10
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let toast = UILabel()
        toast.textColor = .white
        toast.text = message
        toast.textAlignment = .center
        toast.numberOfLines = 0
        toast.font = .systemFont(ofSize: 15, weight: .medium)
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(toast)
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            toast.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding),
            toast.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding),
            toast.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding),
            toast.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -padding)
        ])
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        
        containerView.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
            containerView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2, options: .curveEaseInOut, animations: {
                containerView.alpha = 0
            }) { _ in
                containerView.removeFromSuperview()
            }
        }
    }
}
// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let identifier = "RidePin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = false
            annotationView?.glyphImage = UIImage(systemName: "figure.play")
            annotationView?.markerTintColor = .systemGreen
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        if let rideAnnotation = annotation as? RideAnnotation {
            mapView.deselectAnnotation(annotation, animated: true)
            rideDetailView.showRideDetail(for: rideAnnotation.rideInfo)
            bottomSheet.animateHeight(to: bottomSheet.defaultHeight)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapView.setRegion(region, animated: true)
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 업데이트 실패: \(error.localizedDescription)")
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MapViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 바텀시트를 탭했을 때는 제스처를 무시
        if touch.view?.isDescendant(of: bottomSheet) == true {
            return false
        }
        return true
    }
}
