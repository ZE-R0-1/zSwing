//
//  PlaygroundAnnotation.swift
//  zSwing
//
//  Created by USER on 11/15/24.
//

import MapKit

class PlaygroundAnnotation: NSObject, MKAnnotation {
    let playground: Playground
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var clusteringIdentifier: String?
    
    init(playground: Playground) {
        self.playground = playground
        self.coordinate = playground.coordinate
        self.title = playground.pfctNm
        self.clusteringIdentifier = "playground"
        super.init()
    }
}
