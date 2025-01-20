//
//  FirebasePlaygroundService.swift
//  zSwing
//
//  Created by USER on 12/4/24.
//


import RxSwift
import FirebaseFirestore
import CoreLocation

protocol FirebasePlaygroundServiceProtocol {
    func fetchPlaygrounds(in region: MapRegion) -> Observable<[Playground1]>
}

class FirebasePlaygroundService: FirebasePlaygroundServiceProtocol {
    private let db: Firestore
    
    init(firestore: Firestore = Firestore.firestore()) {
        self.db = firestore
    }
    
    func fetchPlaygrounds(in region: MapRegion) -> Observable<[Playground1]> {
        print("🔥 [Firebase Call] Starting playground fetch for region: lat \(region.center.latitude), lon \(region.center.longitude)")
        
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            // 위도, 경도 범위 계산
            let minLat = String(region.center.latitude - region.span.latitudeDelta/2)
            let maxLat = String(region.center.latitude + region.span.latitudeDelta/2)
            let minLon = String(region.center.longitude - region.span.longitudeDelta/2)
            let maxLon = String(region.center.longitude + region.span.longitudeDelta/2)
            
            print("🔥 [Firebase Query] Executing with bounds: lat(\(minLat) to \(maxLat)), lon(\(minLon) to \(maxLon))")
            
            // 위도와 경도 모두 필터링
            let query = self.db.collection("playgrounds")
                .whereField("latCrtsVl", isGreaterThanOrEqualTo: minLat)
                .whereField("latCrtsVl", isLessThanOrEqualTo: maxLat)
                .whereField("lotCrtsVl", isGreaterThanOrEqualTo: minLon)
                .whereField("lotCrtsVl", isLessThanOrEqualTo: maxLon)
            
            query.getDocuments { snapshot, error in
                if let error = error {
                    print("❌ [Firebase Error] Fetch failed:", error.localizedDescription)
                    observer.onError(error)
                    return
                }
                
                print("✅ [Firebase Success] Fetched \(snapshot?.documents.count ?? 0) documents")
                
                let playgrounds = snapshot?.documents.compactMap { document -> Playground1? in
                    let data = document.data()
                    
                    guard let pfctNm = data["pfctNm"] as? String,
                          let latString = data["latCrtsVl"] as? String,
                          let lonString = data["lotCrtsVl"] as? String,
                          let idrodrCdNm = data["idrodrCdNm"] as? String,
                          !latString.isEmpty,
                          !lonString.isEmpty,
                          let latitude = Double(latString.trimmingCharacters(in: .whitespacesAndNewlines)),
                          let longitude = Double(lonString.trimmingCharacters(in: .whitespacesAndNewlines))
                    else {
                        return nil
                    }
                    
                    return Playground1(
                        pfctSn: document.documentID,
                        pfctNm: pfctNm,
                        coordinate: CLLocationCoordinate2D(
                            latitude: latitude,
                            longitude: longitude
                        ),
                        idrodrCdNm: idrodrCdNm
                    )
                } ?? []
                
                print("📍 [Processed] Mapped \(playgrounds.count) valid playgrounds")
                observer.onNext(playgrounds)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
}
