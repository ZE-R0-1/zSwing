//
//  RideAnnotation.swift
//  zSwing
//
//  Created by USER on 10/29/24.
//

import MapKit

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
