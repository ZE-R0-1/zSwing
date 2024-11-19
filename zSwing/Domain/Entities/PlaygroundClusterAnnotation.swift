//
//  PlaygroundClusterAnnotation.swift
//  zSwing
//
//  Created by USER on 11/19/24.
//

import MapKit

class PlaygroundClusterAnnotation: MKClusterAnnotation {
    let playgrounds: [Playground]
    
    init(playgrounds: [Playground]) {
        self.playgrounds = playgrounds
        // MKClusterAnnotation은 첫 번째 어노테이션을 대표로 사용
        let representative = PlaygroundAnnotation(playground: playgrounds[0])
        super.init(memberAnnotations: [representative])
    }
}
