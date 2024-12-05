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
                print("Repository error fetching playgrounds in region: \(error)")
                return .empty()
            }
    }
    
    func fetchFilteredPlaygrounds(categories: Set<String>, in region: MapRegion) -> Observable<[Playground]> {
        // 놀이터 유형에 따른 필터링이 필요한 경우,
        // Playground 엔티티에 type 필드를 추가하거나
        // rides 배열의 정보를 기반으로 필터링 로직을 구현해야 합니다
        return fetchPlaygrounds(in: region)
    }
}
