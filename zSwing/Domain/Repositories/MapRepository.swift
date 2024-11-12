//
//  MapRepository.swift
//  zSwing
//
//  Created by USER on 11/12/24.
//

import RxSwift
import CoreLocation
import MapKit

protocol MapRepository {
    func getCurrentLocation() -> Observable<Result<MapLocation, Error>>
    func requestLocationPermission() -> Observable<Result<Bool, Error>>
}
