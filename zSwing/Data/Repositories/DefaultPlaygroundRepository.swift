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
            let startTime = Date()  // 시작 시간 기록
            print("데이터 불러오기 시작: \(startTime)")
            
            let collection = self.db.collection("playgrounds")
            
            collection.getDocuments { snapshot, error in
                let fetchTime = Date().timeIntervalSince(startTime)  // Firestore 데이터 가져오는 시간
                print("Firestore 데이터 가져오는 시간: \(String(format: "%.3f", fetchTime))초")
                
                if let error = error {
                    print("에러 발생 시간: \(Date().timeIntervalSince(startTime))초")
                    observer.onError(error)
                    return
                }
                
                let processingStart = Date()  // 데이터 처리 시작 시간
                
                let playgrounds = snapshot?.documents.compactMap { document -> Playground? in
                    guard
                        let pfctNm = document.data()["pfctNm"] as? String,
                        let latString = document.data()["latCrtsVl"] as? String,
                        let lotString = document.data()["lotCrtsVl"] as? String,
                        let pfctSnString = document.data()["pfctSn"] as? String,
                        let latCrtsVl = Double(latString),
                        let lotCrtsVl = Double(lotString)
                    else { return nil }
                    
                    let coordinate = CLLocationCoordinate2D(
                        latitude: latCrtsVl,
                        longitude: lotCrtsVl
                    )
                    
                    let minLat = region.center.latitude - (region.span.latitudeDelta / 2)
                    let maxLat = region.center.latitude + (region.span.latitudeDelta / 2)
                    let minLon = region.center.longitude - (region.span.longitudeDelta / 2)
                    let maxLon = region.center.longitude + (region.span.longitudeDelta / 2)
                    
                    guard coordinate.latitude >= minLat &&
                          coordinate.latitude <= maxLat &&
                          coordinate.longitude >= minLon &&
                          coordinate.longitude <= maxLon
                    else { return nil }
                    
                    return Playground(
                        pfctSn: document.documentID,
                        pfctNm: pfctNm,
                        coordinate: coordinate
                    )
                } ?? []
                
                let processingTime = Date().timeIntervalSince(processingStart)  // 데이터 처리 시간
                print("데이터 처리 시간: \(String(format: "%.3f", processingTime))초")
                
                let totalTime = Date().timeIntervalSince(startTime)  // 전체 소요 시간
                print("전체 소요 시간: \(String(format: "%.3f", totalTime))초")
                print("처리된 놀이터 개수: \(playgrounds.count)개")
                
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
