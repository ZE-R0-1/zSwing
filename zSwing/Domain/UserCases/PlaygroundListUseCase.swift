//
//  PlaygroundListUseCase.swift
//  zSwing
//
//  Created by USER on 12/4/24.
//

import RxSwift
import CoreLocation
import MapKit

protocol PlaygroundListUseCase {
    func fetchPlaygrounds(in region: MapRegion) -> Observable<[Playground1]>
    func fetchFilteredPlaygrounds(categories: Set<String>, in region: MapRegion) -> Observable<[Playground1]>
    func sortPlaygroundsByDistance(playgrounds: [Playground1], userLocation: CLLocation?) -> [Playground1]
}

final class DefaultPlaygroundListUseCase: PlaygroundListUseCase {
    private let repository: PlaygroundRepository
    private let locationManager: CLLocationManager
    
    init(repository: PlaygroundRepository, locationManager: CLLocationManager = CLLocationManager()) {
        self.repository = repository
        self.locationManager = locationManager
    }
    
    func fetchPlaygrounds(in region: MapRegion) -> Observable<[Playground1]> {
        return repository.fetchPlaygrounds(in: region)
            .map { [weak self] playgrounds in
                self?.sortPlaygroundsByDistance(
                    playgrounds: playgrounds,
                    userLocation: self?.locationManager.location
                ) ?? playgrounds
            }
            .catch { error in
                print("Error fetching playgrounds: \(error)")
                return .empty()
            }
    }
    
    func fetchFilteredPlaygrounds(categories: Set<String>, in region: MapRegion) -> Observable<[Playground1]> {
        return repository.fetchFilteredPlaygrounds(categories: categories, in: region)
            .map { [weak self] playgrounds in
                self?.sortPlaygroundsByDistance(
                    playgrounds: playgrounds,
                    userLocation: self?.locationManager.location
                ) ?? playgrounds
            }
            .catch { error in
                return .empty()
            }
    }
    
    func sortPlaygroundsByDistance(playgrounds: [Playground1], userLocation: CLLocation?) -> [Playground1] {
        guard let userLocation = userLocation else { return playgrounds }
        
        return playgrounds.map { playground -> (Playground1, Double) in
            let playgroundLocation = CLLocation(
                latitude: playground.coordinate.latitude,
                longitude: playground.coordinate.longitude
            )
            let distance = userLocation.distance(from: playgroundLocation)
            return (playground, distance)
        }
        .sorted { $0.1 < $1.1 }
        .map { $0.0 }
    }
}
