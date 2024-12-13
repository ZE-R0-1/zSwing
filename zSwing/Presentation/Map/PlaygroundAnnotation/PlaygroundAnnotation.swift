//
//  PlaygroundAnnotation.swift
//  zSwing
//
//  Created by USER on 11/15/24.
//

import MapKit

class PlaygroundAnnotation: NSObject, MKAnnotation {
    let playground: Playground
    let coordinate: CLLocationCoordinate2D
    let title: String?
    
    override var hash: Int {
        return playground.pfctSn.hash
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PlaygroundAnnotation else { return false }
        return playground.pfctSn == other.playground.pfctSn
    }
    
    // 클러스터링 식별자를 computed property로 변경
    var clusteringIdentifier: String? {
        return "playground.cluster"
    }
    
    init(playground: Playground) {
        self.playground = playground
        self.coordinate = playground.coordinate
        self.title = playground.pfctNm
        super.init()
    }
}
