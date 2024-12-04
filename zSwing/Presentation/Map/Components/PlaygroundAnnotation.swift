//
//  PlaygroundAnnotation.swift
//  zSwing
//
//  Created by USER on 11/15/24.
//

import MapKit

class PlaygroundAnnotation: MKPointAnnotation {
    var playground: Playground
    
    init(playground: Playground) {
        self.playground = playground
        super.init()
        self.coordinate = playground.coordinate
        self.title = playground.pfctNm
    }
}
