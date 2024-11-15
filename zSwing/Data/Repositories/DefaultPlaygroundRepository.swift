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
            
            collection.getDocuments { snapshot, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                let playgrounds = snapshot?.documents.compactMap { document -> Playground? in
                    guard
                        let pfcfNm = document.data()["pfcfNm"] as? String,
                        let latString = document.data()["latCrtsVl"] as? String,
                        let lonString = document.data()["lotCrtsVl"] as? String,
                        let latCrtsVl = Double(latString),  // 문자열을 Double로 변환
                        let lotCrtsVl = Double(lonString)   // 문자열을 Double로 변환
                    else { return nil }
                    
                    // 지도 영역 내에 있는 데이터만 필터링
                    let coordinate = CLLocationCoordinate2D(
                        latitude: latCrtsVl,
                        longitude: lotCrtsVl
                    )
                    
                    // 현재 지도에 보이는 영역 계산
                    let minLat = region.center.latitude - (region.span.latitudeDelta / 2)
                    let maxLat = region.center.latitude + (region.span.latitudeDelta / 2)
                    let minLon = region.center.longitude - (region.span.longitudeDelta / 2)
                    let maxLon = region.center.longitude + (region.span.longitudeDelta / 2)
                    
                    // 영역 내에 있는지 확인
                    guard coordinate.latitude >= minLat &&
                          coordinate.latitude <= maxLat &&
                          coordinate.longitude >= minLon &&
                          coordinate.longitude <= maxLon
                    else { return nil }
                    
                    return Playground(
                        pfctSn: document.documentID,
                        pfcfNm: pfcfNm,
                        coordinate: coordinate
                    )
                } ?? []
                
                print("Found \(playgrounds.count) playgrounds in region")  // 디버깅용 프린트
                playgrounds.forEach { playground in  // 디버깅용 프린트
                    print("Playground: \(playground.pfcfNm) at \(playground.coordinate.latitude), \(playground.coordinate.longitude)")
                }
                
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
