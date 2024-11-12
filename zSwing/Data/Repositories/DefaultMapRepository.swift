//
//  DefaultMapRepository.swift
//  zSwing
//
//  Created by USER on 11/12/24.
//

import Foundation
import RxSwift
import MapKit
import CoreLocation

class DefaultMapRepository: NSObject, MapRepository, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let locationSubject = PublishSubject<Result<MapLocation, Error>>()
    private let permissionSubject = PublishSubject<Result<Bool, Error>>()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func getCurrentLocation() -> Observable<Result<MapLocation, Error>> {
        locationManager.startUpdatingLocation()
        return locationSubject.asObservable()
    }
    
    func requestLocationPermission() -> Observable<Result<Bool, Error>> {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            return permissionSubject.asObservable()
        case .authorizedWhenInUse, .authorizedAlways:
            return .just(.success(true))
        case .denied, .restricted:
            return .just(.success(false))
        @unknown default:
            return .just(.success(false))
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationSubject.onNext(.success(MapLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )))
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationSubject.onNext(.failure(error))
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            permissionSubject.onNext(.success(true))
        case .denied, .restricted:
            permissionSubject.onNext(.success(false))
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}
