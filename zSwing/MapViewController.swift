//
//  MapViewController.swift
//  zSwing
//
//  Created by USER on 10/21/24.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseFirestore

class MapViewController: UIViewController {
    
    // MARK: - Properties
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()
    
    private let bottomSheetView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: -3)
        view.layer.shadowRadius = 3
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let dragIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray3
        view.layer.cornerRadius = 2.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
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
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
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
    
    private let db = Firestore.firestore()
    private var currentAnnotations: [MKAnnotation] = []
    private var bottomSheetHeightConstraint: NSLayoutConstraint?
    private let bottomSheetHeight: CGFloat = 300
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocationManager()
        
        // 초기 맵 영역 설정 (서울 중심)
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
        
        // Add MapView
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add Bottom Sheet
        view.addSubview(bottomSheetView)
        bottomSheetHeightConstraint = bottomSheetView.heightAnchor.constraint(equalToConstant: bottomSheetHeight)
        NSLayoutConstraint.activate([
            bottomSheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomSheetHeightConstraint!
        ])
        
        // Add Drag Indicator
        bottomSheetView.addSubview(dragIndicator)
        NSLayoutConstraint.activate([
            dragIndicator.widthAnchor.constraint(equalToConstant: 40),
            dragIndicator.heightAnchor.constraint(equalToConstant: 5),
            dragIndicator.centerXAnchor.constraint(equalTo: bottomSheetView.centerXAnchor),
            dragIndicator.topAnchor.constraint(equalTo: bottomSheetView.topAnchor, constant: 12)
        ])
        
        // Add Info Stack View
        bottomSheetView.addSubview(infoStackView)
        NSLayoutConstraint.activate([
            infoStackView.topAnchor.constraint(equalTo: dragIndicator.bottomAnchor, constant: 20),
            infoStackView.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 20),
            infoStackView.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -20)
        ])
        
        // Add Dismiss Button
        bottomSheetView.addSubview(dismissButton)
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: bottomSheetView.topAnchor, constant: 16),
            dismissButton.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -16),
            dismissButton.widthAnchor.constraint(equalToConstant: 24),
            dismissButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Add Buttons Stack
        let buttonsStack = UIStackView(arrangedSubviews: [searchButton, currentLocationButton])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 8
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(buttonsStack)
        NSLayoutConstraint.activate([
            buttonsStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            buttonsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchButton.widthAnchor.constraint(equalToConstant: 40),
            searchButton.heightAnchor.constraint(equalToConstant: 40),
            currentLocationButton.widthAnchor.constraint(equalToConstant: 40),
            currentLocationButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Add Loading Indicator
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Add Button Targets
        currentLocationButton.addTarget(self, action: #selector(currentLocationButtonTapped), for: .touchUpInside)
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)
        
        mapView.delegate = self
        mapView.showsUserLocation = true
    }
    
    // MARK: - Bottom Sheet Properties
    private enum BottomSheetPosition {
        case bottom
        case middle
        case top
    }

    private var bottomSheetBottomConstraint: NSLayoutConstraint!
    private var currentBottomSheetPosition: BottomSheetPosition = .bottom
    
    // MARK: - Bottom Sheet Methods
    private func showRideDetail(for rideInfo: RideInfo) {
        // Clear previous info
        infoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add new info
        let nameLabel = createLabel(text: rideInfo.rideName, font: .boldSystemFont(ofSize: 24))
        let facilityLabel = createLabel(text: rideInfo.facilityName, font: .systemFont(ofSize: 18), textColor: .gray)
        let addressLabel = createLabel(text: rideInfo.address, font: .systemFont(ofSize: 16))
        addressLabel.numberOfLines = 0
        
        let separator = createSeparator()
        
        let typeLabel = createLabel(text: "놀이기구 유형: \(rideInfo.rideType)", font: .systemFont(ofSize: 16))
        let dateLabel = createLabel(text: "설치일: \(rideInfo.installDate)", font: .systemFont(ofSize: 16))
        
        [nameLabel, facilityLabel, separator, addressLabel, typeLabel, dateLabel].forEach {
            infoStackView.addArrangedSubview($0)
        }
        
        // Show bottom sheet with animation
        bottomSheetView.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.alpha = 1
        }
    }
    
    private func hideBottomSheet() {
        UIView.animate(withDuration: 0.3) {
            self.bottomSheetView.alpha = 0
        } completion: { _ in
            self.bottomSheetView.isHidden = true
        }
    }
    
    private func createLabel(text: String, font: UIFont, textColor: UIColor = .black) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = textColor
        return label
    }
    
    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .systemGray4
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }
    
    @objc private func dismissButtonTapped() {
        hideBottomSheet()
    }
    
    // MARK: - Setup Location Manager
    private func setupLocationManager() {
        locationManager.delegate = self
        
        // 현재 권한 상태 확인
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // 이미 권한이 있으면 바로 위치 업데이트 시작
            locationManager.startUpdatingLocation()
        case .notDetermined:
            // 권한이 없으면 요청
            locationManager.requestWhenInUseAuthorization()
        default:
            // 권한이 거부된 경우 서울 중심으로 설정
            let seoulRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            )
            mapView.setRegion(seoulRegion, animated: false)
        }
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
        
        let region = mapView.region
        let center = region.center
        let span = region.span
        
        // 현재 보이는 영역의 좌표 범위 계산
        let minLat = center.latitude - (span.latitudeDelta / 2.0)
        let maxLat = center.latitude + (span.latitudeDelta / 2.0)
        let minLon = center.longitude - (span.longitudeDelta / 2.0)
        let maxLon = center.longitude + (span.longitudeDelta / 2.0)
        
        // Firestore 쿼리
        db.collection("playgrounds")
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching playgrounds: \(error)")
                    self.showAlert(title: "검색 실패", message: "데이터를 가져오는데 실패했습니다.")
                    self.loadingIndicator.stopAnimating()
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // 보이는 영역 내의 documents 필터링
                let filteredDocs = documents.filter { document in
                    let data = document.data()
                    // String을 Double로 변환
                    guard let latStr = data["latCrtsVl"] as? String,
                          let lonStr = data["lotCrtsVl"] as? String,
                          let latitude = Double(latStr),
                          let longitude = Double(lonStr) else {
                        return false
                    }
                    
                    // 현재 보이는 영역의 좌표 범위 내에 있는지 확인
                    return latitude >= minLat && latitude <= maxLat &&
                    longitude >= minLon && longitude <= maxLon
                }
                
                // 필터링된 playground들의 rides 가져오기
                let group = DispatchGroup()
                var allRides: [RideAnnotation] = []
                
                for document in filteredDocs {
                    group.enter()
                    let data = document.data()
                    let pfctSn = data["pfctSn"] as? String ?? ""
                    
                    // String을 Double로 변환
                    guard let latStr = data["latCrtsVl"] as? String,
                          let lonStr = data["lotCrtsVl"] as? String,
                          let latitude = Double(latStr),
                          let longitude = Double(lonStr) else {
                        group.leave()
                        continue
                    }
                    
                    let address = data["ronaAddr"] as? String ?? ""
                    
                    self.db.collection("rides")
                        .whereField("pfctSn", isEqualTo: pfctSn)
                        .getDocuments { (ridesSnapshot, error) in
                            defer { group.leave() }
                            
                            if let rides = ridesSnapshot?.documents {
                                let rideAnnotations = rides.compactMap { rideDoc -> RideAnnotation? in
                                    let rideData = rideDoc.data()
                                    return RideAnnotation(
                                        coordinate: CLLocationCoordinate2D(
                                            latitude: latitude,
                                            longitude: longitude
                                        ),
                                        title: rideData["rideNm"] as? String ?? "알 수 없음",
                                        subtitle: rideData["pfctNm"] as? String ?? "알 수 없음",
                                        rideInfo: RideInfo(
                                            rideSn: rideDoc.documentID,
                                            installDate: rideData["rideInstlYmd"] as? String ?? "",
                                            facilityName: rideData["pfctNm"] as? String ?? "",
                                            rideName: rideData["rideNm"] as? String ?? "",
                                            rideType: rideData["rideStylCd"] as? String ?? "",
                                            address: address
                                        )
                                    )
                                }
                                allRides.append(contentsOf: rideAnnotations)
                            }
                        }
                }
                
                group.notify(queue: .main) {
                    self.updateAnnotations(with: allRides)
                    self.loadingIndicator.stopAnimating()
                    
                    // 검색 결과 알림
                    let message = allRides.isEmpty ?
                    "이 지역에 놀이기구가 없습니다" :
                    "이 지역에서 \(allRides.count)개의 놀이기구를 찾았습니다"
                    self.showToast(message: message)
                }
            }
    }
    
    private func updateAnnotations(with newAnnotations: [MKAnnotation]) {
        // 기존 어노테이션 제거
        mapView.removeAnnotations(currentAnnotations)
        currentAnnotations = newAnnotations
        
        // 새로운 어노테이션 추가
        mapView.addAnnotations(newAnnotations)
    }
    
    private func showToast(message: String) {
        let padding: CGFloat = 8
        
        // 패딩용 UIView 생성
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
        
        // 컨테이너 내부 패딩을 위한 제약
        NSLayoutConstraint.activate([
            toast.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding),
            toast.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -padding),
            toast.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding),
            toast.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -padding)
        ])
        
        // 컨테이너의 위치 제약
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        
        // 애니메이션 처리
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
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
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
            showRideDetail(for: rideAnnotation.rideInfo)
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

// MARK: - RideAnnotation
class RideAnnotation: MKPointAnnotation {
    let rideInfo: RideInfo
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, rideInfo: RideInfo) {
        self.rideInfo = rideInfo
        super.init()
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}

// MARK: - Models
struct RideInfo {
    let rideSn: String
    let installDate: String
    let facilityName: String
    let rideName: String
    let rideType: String
    let address: String
}
