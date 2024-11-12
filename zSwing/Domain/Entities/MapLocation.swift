//
//  MapLocation.swift
//  zSwing
//
//  Created by USER on 11/12/24.
//

import Foundation

struct MapLocation {
    let latitude: Double
    let longitude: Double
    
    static let defaultLocation = MapLocation(
        latitude: 37.5665,
        longitude: 126.9780
    )
}
