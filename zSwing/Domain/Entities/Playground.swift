//
//  Playground.swift
//  zSwing
//
//  Created by USER on 11/14/24.
//

import Foundation
import CoreLocation

struct Playground {
    let pfctSn: String
    let pfcfNm: String
    let coordinate: CLLocationCoordinate2D
    
    // 현재 위치로부터의 거리
    func distance(from location: CLLocation) -> CLLocationDistance {
        let playgroundLocation = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return location.distance(from: playgroundLocation)
    }
}
