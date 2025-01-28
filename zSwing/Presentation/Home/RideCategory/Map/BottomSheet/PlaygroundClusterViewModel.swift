//
//  PlaygroundClusterViewModel.swift
//  zSwing
//
//  Created by USER on 1/28/25.
//

import Foundation
import CoreLocation

class PlaygroundClusterViewModel {
    private let playgrounds: [Playground]
    private let currentLocation: CLLocation
    let items: [(playground: Playground, distance: CLLocationDistance)]
    
    init(playgrounds: [Playground], currentLocation: CLLocation) {
        self.playgrounds = playgrounds
        self.currentLocation = currentLocation
        
        // 거리에 따라 정렬된 놀이터 목록 생성
        self.items = playgrounds.map { playground in
            let location = CLLocation(
                latitude: playground.coordinate.latitude,
                longitude: playground.coordinate.longitude
            )
            return (playground, currentLocation.distance(from: location))
        }.sorted { $0.distance < $1.distance }
    }
}
