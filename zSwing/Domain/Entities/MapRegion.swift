//
//  MapRegion.swift
//  zSwing
//
//  Created by USER on 12/4/24.
//

import Foundation
import CoreLocation
import MapKit

struct MapRegion: Hashable {
    let center: CLLocationCoordinate2D
    let span: MKCoordinateSpan
    
    static var defaultRegion: MapRegion {
        return MapRegion(
            center: CLLocationCoordinate2D(
                latitude: 37.5665,
                longitude: 126.9780
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.1,
                longitudeDelta: 0.1
            )
        )
    }
    
    // Hashable 구현
    func hash(into hasher: inout Hasher) {
        hasher.combine(center.latitude)
        hasher.combine(center.longitude)
        hasher.combine(span.latitudeDelta)
        hasher.combine(span.longitudeDelta)
    }
    
    // Equatable 구현
    static func == (lhs: MapRegion, rhs: MapRegion) -> Bool {
        return lhs.center.latitude == rhs.center.latitude &&
        lhs.center.longitude == rhs.center.longitude &&
        lhs.span.latitudeDelta == rhs.span.latitudeDelta &&
        lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
}
