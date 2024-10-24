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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocationManager()
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
        
        mapView.delegate = self
        mapView.showsUserLocation = true
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
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
        // searchInVisibleRegion 메서드 내의 Firestore 쿼리 부분 수정
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
                    "이 지역에 놀이기구가 없습니다." :
                    "이 지역에서 \(allRides.count)개의 놀이기구를 찾았습니다."
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
        let toast = UILabel()
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toast.textColor = .white
        toast.text = message
        toast.textAlignment = .center
        toast.alpha = 0
        toast.layer.cornerRadius = 20
        toast.clipsToBounds = true
        toast.numberOfLines = 0
        toast.font = .systemFont(ofSize: 14)
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toast)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        
        toast.layoutIfNeeded()
        let padding: CGFloat = 15
        toast.bounds = CGRect(x: 0, y: 0, width: toast.bounds.width + padding * 2, height: toast.bounds.height + padding)
        
        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2, options: [], animations: {
                toast.alpha = 0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
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
            annotationView?.canShowCallout = true
            annotationView?.glyphImage = UIImage(systemName: "figure.play")
            annotationView?.markerTintColor = .systemGreen
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation as? RideAnnotation else { return }
        showRideDetail(for: annotation.rideInfo)
    }
}

// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
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

// MARK: - RideDetailViewController
class RideDetailViewController: UIViewController {
    private let rideInfo: RideInfo
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    init(rideInfo: RideInfo) {
        self.rideInfo = rideInfo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // 놀이기구 이름
        let nameLabel = createLabel(text: rideInfo.rideName, font: .boldSystemFont(ofSize: 24))
        stackView.addArrangedSubview(nameLabel)
        
        // 시설 이름
        let facilityLabel = createLabel(text: rideInfo.facilityName, font: .systemFont(ofSize: 18), textColor: .gray)
        stackView.addArrangedSubview(facilityLabel)
        
        // 주소
        let addressLabel = createLabel(text: rideInfo.address, font: .systemFont(ofSize: 16), textColor: .darkGray)
        addressLabel.numberOfLines = 0
        stackView.addArrangedSubview(addressLabel)
        
        // 구분선
        let separator = UIView()
        separator.backgroundColor = .systemGray4
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stackView.addArrangedSubview(separator)
        
        // 상세 정보
        let detailsStack = UIStackView()
        detailsStack.axis = .vertical
        detailsStack.spacing = 8
        
        // 놀이기구 유형
        let typeLabel = createLabel(text: "놀이기구 유형: \(rideInfo.rideType)", font: .systemFont(ofSize: 16))
        detailsStack.addArrangedSubview(typeLabel)
        
        // 설치일
        let dateLabel = createLabel(text: "설치일: \(rideInfo.installDate)", font: .systemFont(ofSize: 16))
        detailsStack.addArrangedSubview(dateLabel)
        
        stackView.addArrangedSubview(detailsStack)
    }
    
    private func createLabel(text: String, font: UIFont, textColor: UIColor = .black) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = textColor
        return label
    }
}

// MapViewController에 추가할 메서드
extension MapViewController {
    private func showRideDetail(for rideInfo: RideInfo) {
        let detailVC = RideDetailViewController(rideInfo: rideInfo)
        
        if let sheet = detailVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        
        present(detailVC, animated: true)
    }
}
