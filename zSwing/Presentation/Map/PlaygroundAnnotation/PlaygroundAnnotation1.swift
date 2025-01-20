//
//  PlaygroundAnnotation.swift
//  zSwing
//
//  Created by USER on 11/15/24.
//

import MapKit

class PlaygroundAnnotation1: NSObject, MKAnnotation {
    let playground: Playground1
    let coordinate: CLLocationCoordinate2D
    let title: String?
    
    override var hash: Int {
        return playground.pfctSn.hash
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PlaygroundAnnotation1 else { return false }
        return playground.pfctSn == other.playground.pfctSn
    }
    
    init(playground: Playground1) {
        self.playground = playground
        self.coordinate = playground.coordinate
        self.title = playground.pfctNm
        super.init()
    }
}
