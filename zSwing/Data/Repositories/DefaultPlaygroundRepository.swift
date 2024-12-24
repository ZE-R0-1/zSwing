//
//  DefaultPlaygroundRepository.swift
//  zSwing
//
//  Created by USER on 11/14/24.
//

import FirebaseFirestore
import CoreLocation
import RxSwift
import MapKit

final class DefaultPlaygroundRepository: PlaygroundRepository {
    private let firebaseService: FirebasePlaygroundServiceProtocol
    private let disposeBag = DisposeBag()
    
    init(firebaseService: FirebasePlaygroundServiceProtocol) {
        self.firebaseService = firebaseService
    }
    
    func fetchPlaygrounds(in region: MapRegion) -> Observable<[Playground]> {
        return firebaseService.fetchPlaygrounds(in: region)
            .catch { error in
                print("Error fetching playgrounds:", error)
                return .empty()
            }
    }
    
    func fetchFilteredPlaygrounds(categories: Set<String>, in region: MapRegion) -> Observable<[Playground]> {
        return fetchPlaygrounds(in: region)
            .map { playgrounds in
                guard !categories.contains(PlaygroundType.all.rawValue) else {
                    return playgrounds
                }
                
                let filtered = playgrounds.filter { playground in
                    return categories.contains(playground.idrodrCdNm)
                }
                return filtered
            }
    }
}
