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

class DefaultPlaygroundRepository: PlaygroundRepository {
    private let db = Firestore.firestore()
    
    func fetchPlaygrounds(in region: MapRegion) -> Observable<[Playground]> {
        return Observable.create { observer in
            let collection = self.db.collection("playgrounds")
            
            // 지역 기반 쿼리 로직 구현 필요
            collection.getDocuments { snapshot, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                let playgrounds = snapshot?.documents.compactMap { document -> Playground? in
                    guard let pfcfNm = document.data()["pfcfNm"] as? String else { return nil }
                    
                    // 임시 좌표 설정 (실제로는 Firestore에서 가져와야 함)
                    let coordinate = CLLocationCoordinate2D(
                        latitude: 37.5665,
                        longitude: 126.9780
                    )
                    
                    return Playground(
                        pfctSn: document.documentID,
                        pfcfNm: pfcfNm,
                        coordinate: coordinate
                    )
                } ?? []
                
                observer.onNext(playgrounds)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func fetchPlaygroundsNearby(coordinate: CLLocationCoordinate2D) -> Observable<[Playground]> {
        return fetchPlaygrounds(in: MapRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))
    }
}
