////
////  PlaygroundUseCase.swift
////  zSwing
////
////  Created by USER on 11/14/24.
////
//
//import Foundation
//import CoreLocation
//import MapKit
//import RxSwift
//
//protocol PlaygroundUseCase {
//    func fetchPlaygrounds(in region: MapRegion) -> Observable<[Playground]>
//    func fetchPlaygroundsNearby(coordinate: CLLocationCoordinate2D) -> Observable<[Playground]>
//}
//
//struct MapRegion {
//    let center: CLLocationCoordinate2D
//    let span: MKCoordinateSpan
//}
//
//class DefaultPlaygroundUseCase: PlaygroundUseCase {
//    private let repository: PlaygroundRepository
//    
//    init(repository: PlaygroundRepository) {
//        self.repository = repository
//    }
//    
//    func fetchPlaygrounds(in region: MapRegion) -> Observable<[Playground]> {
//        return repository.fetchPlaygrounds(in: region)
//    }
//    
//    func fetchPlaygroundsNearby(coordinate: CLLocationCoordinate2D) -> Observable<[Playground]> {
//        return repository.fetchPlaygroundsNearby(coordinate: coordinate)
//    }
//}
