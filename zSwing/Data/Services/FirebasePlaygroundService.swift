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
    func fetchPlaygrounds(in region: MapRegion) -> Observable<[Playground]>
}

class FirebasePlaygroundService: FirebasePlaygroundServiceProtocol {
    private let db: Firestore
    
    init(firestore: Firestore = Firestore.firestore()) {
        self.db = firestore
    }
    
    func fetchPlaygrounds(in region: MapRegion) -> Observable<[Playground]> {
        print("🔥 [Firebase Call] Starting playground fetch for region: lat \(region.center.latitude), lon \(region.center.longitude)")
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            let query = self.db.collection("playgrounds")
                .whereField("latCrtsVl", isGreaterThanOrEqualTo: String(region.center.latitude - region.span.latitudeDelta/2))
                .whereField("latCrtsVl", isLessThanOrEqualTo: String(region.center.latitude + region.span.latitudeDelta/2))
            
            print("🔥 [Firebase Query] Executing with bounds: \(region.center.latitude - region.span.latitudeDelta/2) to \(region.center.latitude + region.span.latitudeDelta/2)")

            query.getDocuments { snapshot, error in
                if let error = error {
                    print("❌ [Firebase Error] Fetch failed:", error.localizedDescription)
                    observer.onError(error)
                    return
                }
                
                print("✅ [Firebase Success] Fetched \(snapshot?.documents.count ?? 0) documents")
                
                let playgrounds = snapshot?.documents.compactMap { document -> Playground? in
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
                    
                    let minLon = region.center.longitude - region.span.longitudeDelta/2
                    let maxLon = region.center.longitude + region.span.longitudeDelta/2
                    guard longitude >= minLon && longitude <= maxLon else {
                        return nil
                    }
                    
                    return Playground(
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
