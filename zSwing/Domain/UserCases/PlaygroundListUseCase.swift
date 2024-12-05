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
    func fetchPlaygrounds(in region: MapRegion) -> Observable<[Playground]>
    func filterPlaygrounds(by categories: Set<String>, in region: MapRegion) -> Observable<[Playground]>
    func sortPlaygroundsByDistance(playgrounds: [Playground], userLocation: CLLocation?) -> [Playground]
}

final class DefaultPlaygroundListUseCase: PlaygroundListUseCase {
    private let repository: PlaygroundRepository
    private let locationManager: CLLocationManager
    
    init(repository: PlaygroundRepository, locationManager: CLLocationManager = CLLocationManager()) {
        self.repository = repository
        self.locationManager = locationManager
    }
    
    func fetchPlaygrounds(in region: MapRegion) -> Observable<[Playground]> {
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
    
    func filterPlaygrounds(by categories: Set<String>, in region: MapRegion) -> Observable<[Playground]> {
        return repository.fetchFilteredPlaygrounds(categories: categories, in: region)
            .map { playgrounds in
                guard !categories.contains("전체") else { return playgrounds }
                // 현재는 필터링 로직이 제거된 상태입니다.
                // 필터링 기준이 결정되면 여기에 구현하면 됩니다.
                return playgrounds
            }
            .catch { error in
                print("Error filtering playgrounds: \(error)")
                return .empty()
            }
    }
    
    func sortPlaygroundsByDistance(playgrounds: [Playground], userLocation: CLLocation?) -> [Playground] {
        guard let userLocation = userLocation else { return playgrounds }
        
        return playgrounds.map { playground -> (Playground, Double) in
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
