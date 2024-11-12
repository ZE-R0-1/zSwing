//
//  FirebaseMapDataSource.swift
//  zSwing
//
//  Created by USER on 11/12/24.
//

import Foundation
import FirebaseFirestore
import RxSwift
import MapKit
import CoreLocation

protocol MapDataSource {
    func fetchRides(in region: MKCoordinateRegion) -> Observable<[RideDTO]>
    func fetchRideDetails(id: String) -> Observable<RideDTO>
}

class FirebaseMapDataSource: MapDataSource {
    private let db = Firestore.firestore()
    
    func fetchRides(in region: MKCoordinateRegion) -> Observable<[RideDTO]> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            let center = region.center
            let span = region.span
            
            let minLat = center.latitude - (span.latitudeDelta / 2.0)
            let maxLat = center.latitude + (span.latitudeDelta / 2.0)
            let minLon = center.longitude - (span.longitudeDelta / 2.0)
            let maxLon = center.longitude + (span.longitudeDelta / 2.0)
            
            // 먼저 해당 지역의 놀이터 정보를 가져옴
            self.db.collection("playgrounds")
                .getDocuments { (snapshot, error) in
                    if let error = error {
                        observer.onError(error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        observer.onNext([])
                        observer.onCompleted()
                        return
                    }
                    
                    // 지역 필터링
                    let filteredDocs = documents.filter { document in
                        let data = document.data()
                        guard let latStr = data["latCrtsVl"] as? String,
                              let lonStr = data["lotCrtsVl"] as? String,
                              let latitude = Double(latStr),
                              let longitude = Double(lonStr) else {
                            return false
                        }
                        
                        return latitude >= minLat && latitude <= maxLat &&
                        longitude >= minLon && longitude <= maxLon
                    }
                    
                    let group = DispatchGroup()
                    var allRides: [RideDTO] = []
                    
                    // 각 놀이터의 놀이기구 정보를 가져옴
                    for document in filteredDocs {
                        group.enter()
                        let data = document.data()
                        let pfctSn = data["pfctSn"] as? String ?? ""
                        
                        self.db.collection("rides")
                            .whereField("pfctSn", isEqualTo: pfctSn)
                            .getDocuments { (ridesSnapshot, error) in
                                defer { group.leave() }
                                
                                if let error = error {
                                    print("Error fetching rides: \(error)")
                                    return
                                }
                                
                                if let rides = ridesSnapshot?.documents {
                                    let rideDTOs = rides.compactMap { rideDoc -> RideDTO? in
                                        try? rideDoc.data(as: RideDTO.self)
                                    }
                                    allRides.append(contentsOf: rideDTOs)
                                }
                            }
                    }
                    
                    group.notify(queue: .main) {
                        observer.onNext(allRides)
                        observer.onCompleted()
                    }
                }
            
            return Disposables.create()
        }
    }
    
    func fetchRideDetails(id: String) -> Observable<RideDTO> {
        return Observable.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            let docRef = self.db.collection("rides").document(id)
            docRef.getDocument { (document, error) in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                if let document = document,
                   let rideDTO = try? document.data(as: RideDTO.self) {
                    observer.onNext(rideDTO)
                    observer.onCompleted()
                } else {
                    observer.onError(NSError(domain: "FirebaseMapDataSource",
                                          code: -1,
                                          userInfo: [NSLocalizedDescriptionKey: "Ride not found"]))
                }
            }
            
            return Disposables.create()
        }
    }
}
