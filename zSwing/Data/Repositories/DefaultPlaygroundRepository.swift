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
    private let cache = NSCache<NSString, NSArray>()
    private let regionQueue = DispatchQueue(label: "com.app.region.queue")
    
    func fetchPlaygrounds(in region: MapRegion) -> Observable<[Playground]> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            let totalStartTime = Date()
            print("\n📍 지도 영역 정보:")
            print("- 중심 좌표: \(region.center.latitude), \(region.center.longitude)")
            print("- 범위: \(region.span.latitudeDelta), \(region.span.longitudeDelta)")
            
            // 영역 범위 계산
            let minLat = region.center.latitude - (region.span.latitudeDelta / 2)
            let maxLat = region.center.latitude + (region.span.latitudeDelta / 2)
            let minLon = region.center.longitude - (region.span.longitudeDelta / 2)
            let maxLon = region.center.longitude + (region.span.longitudeDelta / 2)
            
            let collection = self.db.collection("playgrounds")
            
            // Firestore 쿼리에서 필터링
            let query = collection
                .whereField("latCrtsVl", isGreaterThanOrEqualTo: String(minLat))
                .whereField("latCrtsVl", isLessThanOrEqualTo: String(maxLat))
            
            print("\n🚀 Firestore 요청 시작: \(totalStartTime)")
            
            query.getDocuments { snapshot, error in
                let firestoreTime = Date().timeIntervalSince(totalStartTime)
                print("⏱ Firestore 데이터 수신 완료: \(String(format: "%.3f", firestoreTime))초")
                
                if let error = error {
                    print("❌ Firestore 에러: \(error.localizedDescription)")
                    observer.onError(error)
                    return
                }
                
                let parsingStartTime = Date()
                let playgrounds = snapshot?.documents.compactMap { document -> Playground? in
                    let data = document.data()
                    
                    guard let pfctNm = data["pfctNm"] as? String,
                          let latString = data["latCrtsVl"] as? String,
                          let lonString = data["lotCrtsVl"] as? String,
                          !latString.isEmpty,
                          !lonString.isEmpty,
                          let latitude = Double(latString.trimmingCharacters(in: .whitespacesAndNewlines)),
                          let longitude = Double(lonString.trimmingCharacters(in: .whitespacesAndNewlines))
                    else {
                        return nil
                    }
                    
                    // 경도 범위 체크
                    guard longitude >= minLon && longitude <= maxLon else {
                        return nil
                    }
                    
                    return Playground(
                        pfctSn: document.documentID,
                        pfctNm: pfctNm,
                        coordinate: CLLocationCoordinate2D(
                            latitude: latitude,
                            longitude: longitude
                        )
                    )
                } ?? []
                
                let parsingTime = Date().timeIntervalSince(parsingStartTime)
                let totalTime = Date().timeIntervalSince(totalStartTime)
                
                print("\n⏱ 성능 측정 결과:")
                print("- Firestore 요청 시간: \(String(format: "%.3f", firestoreTime))초")
                print("- 데이터 파싱 시간: \(String(format: "%.3f", parsingTime))초")
                print("- 총 소요 시간: \(String(format: "%.3f", totalTime))초")
                print("\n📊 데이터 처리 결과:")
                print("- 수신된 문서 수: \(snapshot?.documents.count ?? 0)개")
                print("- 파싱된 놀이터 수: \(playgrounds.count)개")
                print("- 초당 처리량: \(String(format: "%.1f", Double(playgrounds.count)/totalTime))개/초\n")
                
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
