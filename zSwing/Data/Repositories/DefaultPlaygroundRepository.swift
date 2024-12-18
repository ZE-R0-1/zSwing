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
                return .empty()
            }
    }
    
    func fetchFilteredPlaygrounds(categories: Set<String>, in region: MapRegion) -> Observable<[Playground]> {
        return fetchPlaygrounds(in: region)
            .do(onNext: { playgrounds in
                print("📊 Total playgrounds before filtering: \(playgrounds.count)") // 디버그 로그 추가
            })
            .map { playgrounds in
                guard !categories.contains(PlaygroundType.all.rawValue) else {
                    print("👉 Returning all playgrounds: \(playgrounds.count)") // 디버그 로그 추가
                    return playgrounds
                }
                
                let filtered = playgrounds.filter { playground in
                    print("🏷 Playground type: \(playground.idrodrCdNm)") // 디버그 로그 추가
                    return categories.contains(playground.idrodrCdNm)
                }
                print("📊 Filtered playgrounds: \(filtered.count)") // 디버그 로그 추가
                return filtered
            }
    }
}
