//
//  MapUseCase.swift
//  zSwing
//
//  Created by USER on 11/12/24.
//

import RxSwift
import CoreLocation
import MapKit

protocol MapUseCase {
    func getCurrentLocation() -> Observable<Result<MapLocation, Error>>
    func requestLocationPermission() -> Observable<Result<Bool, Error>>
}

class DefaultMapUseCase: MapUseCase {
    private let repository: MapRepository
    
    init(repository: MapRepository) {
        self.repository = repository
    }
    
    func getCurrentLocation() -> Observable<Result<MapLocation, Error>> {
        return repository.getCurrentLocation()
    }
    
    func requestLocationPermission() -> Observable<Result<Bool, Error>> {
        return repository.requestLocationPermission()
    }
}
