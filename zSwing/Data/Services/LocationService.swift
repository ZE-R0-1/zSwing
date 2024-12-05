//
//  LocationService.swift
//  zSwing
//
//  Created by USER on 12/5/24.
//

import RxSwift
import RxCocoa
import CoreLocation

protocol LocationServiceType {
    var currentLocation: Observable<CLLocation> { get }
    var authorizationStatus: Observable<CLAuthorizationStatus> { get }
    func requestLocationAuthorization()
}

final class LocationService: NSObject, LocationServiceType {
    private let locationManager: CLLocationManager
    private let disposeBag = DisposeBag()
    
    // Subjects
    private let locationSubject = PublishSubject<CLLocation>()
    private let authorizationSubject = BehaviorSubject<CLAuthorizationStatus>(
        value: CLLocationManager().authorizationStatus
    )
    
    // Outputs as Observable
    var currentLocation: Observable<CLLocation> {
        return locationSubject.asObservable()
    }
    
    var authorizationStatus: Observable<CLAuthorizationStatus> {
        return authorizationSubject.asObservable()
    }
    
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        
        setupLocationManager()
        
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("위치 업데이트: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        locationSubject.onNext(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 에러 발생: \(error)")
        locationSubject.onError(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationSubject.onNext(status)
        
        if status == .authorizedWhenInUse {
            startUpdatingLocation()
        }
    }
}
