//
//  FirebasePlaygroundService.swift
//  zSwing
//
//  Created by USER on 11/1/24.
//

import FirebaseFirestore
import MapKit

class FirebasePlaygroundService {
    private let db = Firestore.firestore()
    
    func searchPlaygrounds(in region: MKCoordinateRegion, completion: @escaping ([RideAnnotation]?, Error?) -> Void) {
        let center = region.center
        let span = region.span
        
        let minLat = center.latitude - (span.latitudeDelta / 2.0)
        let maxLat = center.latitude + (span.latitudeDelta / 2.0)
        let minLon = center.longitude - (span.longitudeDelta / 2.0)
        let maxLon = center.longitude + (span.longitudeDelta / 2.0)
        
        db.collection("playgrounds")
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                
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
                var allRides: [RideAnnotation] = []
                
                for document in filteredDocs {
                    group.enter()
                    let data = document.data()
                    let pfctSn = data["pfctSn"] as? String ?? ""
                    
                    guard let latStr = data["latCrtsVl"] as? String,
                          let lonStr = data["lotCrtsVl"] as? String,
                          let latitude = Double(latStr),
                          let longitude = Double(lonStr) else {
                        group.leave()
                        continue
                    }
                    
                    let address = data["ronaAddr"] as? String ?? ""
                    
                    self.db.collection("rides")
                        .whereField("pfctSn", isEqualTo: pfctSn)
                        .getDocuments { (ridesSnapshot, error) in
                            defer { group.leave() }
                            
                            if let rides = ridesSnapshot?.documents {
                                let rideAnnotations = rides.compactMap { rideDoc -> RideAnnotation? in
                                    let rideData = rideDoc.data()
                                    return RideAnnotation(
                                        coordinate: CLLocationCoordinate2D(
                                            latitude: latitude,
                                            longitude: longitude
                                        ),
                                        title: rideData["rideNm"] as? String ?? "알 수 없음",
                                        subtitle: rideData["pfctNm"] as? String ?? "알 수 없음",
                                        rideInfo: RideInfo(
                                            rideSn: rideDoc.documentID,
                                            installDate: rideData["rideInstlYmd"] as? String ?? "",
                                            facilityName: rideData["pfctNm"] as? String ?? "",
                                            rideName: rideData["rideNm"] as? String ?? "",
                                            rideType: rideData["rideStylCd"] as? String ?? "",
                                            address: address
                                        )
                                    )
                                }
                                allRides.append(contentsOf: rideAnnotations)
                            }
                        }
                }
                
                group.notify(queue: .main) {
                    completion(allRides, nil)
                }
            }
    }
}
