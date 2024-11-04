//
//  PlaygroundItem.swift
//  zSwing
//
//  Created by USER on 11/4/24.
//

import Foundation
import CoreLocation

struct PlaygroundItem {
    let facilityName: String
    let coordinate: CLLocationCoordinate2D
    let distance: CLLocationDistance
    let rideInfo: RideInfo
    
    init(rideInfo: RideInfo, coordinate: CLLocationCoordinate2D, userLocation: CLLocation?) {
        self.facilityName = rideInfo.facilityName
        self.coordinate = coordinate
        self.rideInfo = rideInfo
        
        if let userLocation = userLocation {
            let playgroundLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            self.distance = userLocation.distance(from: playgroundLocation)
        } else {
            self.distance = 0
        }
    }
    
    var distanceText: String {
        if distance == 0 {
            return "거리 정보 없음"
        }
        if distance < 1000 {
            return "\(Int(distance))m"
        }
        return String(format: "%.1fkm", distance / 1000)
    }
}
