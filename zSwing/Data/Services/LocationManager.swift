//
//  LocationManager.swift
//  zSwing
//
//  Created by USER on 1/20/25.
//

import Foundation
import CoreLocation
import RxSwift
import RxRelay

class LocationManager: NSObject {
    private let manager = CLLocationManager()
    private let locationRelay = BehaviorRelay<CLLocation?>(value: nil)
    
    var currentLocation: CLLocation? { locationRelay.value }
    var currentLocationObservable: Observable<CLLocation?> { locationRelay.asObservable() }
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationRelay.accept(location)
    }
}
