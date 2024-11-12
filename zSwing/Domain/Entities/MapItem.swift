//
//  MapItem.swift
//  zSwing
//
//  Created by USER on 11/12/24.
//

import CoreLocation
import Foundation

struct MapItem: Equatable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let rideInfo: RideInfo
    let distance: CLLocationDistance?
    
    static func == (lhs: MapItem, rhs: MapItem) -> Bool {
        return lhs.id == rhs.id
    }
}
