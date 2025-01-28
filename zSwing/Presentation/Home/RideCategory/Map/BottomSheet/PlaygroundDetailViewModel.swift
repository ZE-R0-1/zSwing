//
//  PlaygroundDetailViewModel.swift
//  zSwing
//
//  Created by USER on 1/28/25.
//

import Foundation
import CoreLocation

class PlaygroundDetailViewModel {
    private let playground: Playground
    private let distance: CLLocationDistance
    
    let name: String
    let address: String
    let distanceText: String
    let facilities: [PlaygroundFacility]
    let installationDate: String
    
    init(playground: Playground, distance: CLLocationDistance) {
        self.playground = playground
        self.distance = distance
        
        self.name = playground.name
        self.address = playground.address
        self.facilities = playground.facilities
        self.distanceText = Self.formatDistance(distance)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월"
        self.installationDate = dateFormatter.string(from: playground.madeAt)
    }
    
    static func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        } else {
            return String(format: "%.0fm", distance)
        }
    }
}
