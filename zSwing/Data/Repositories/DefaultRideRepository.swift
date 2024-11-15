//
//  DefaultRideRepository.swift
//  zSwing
//
//  Created by USER on 11/15/24.
//

import RxSwift
import FirebaseFirestore

class DefaultRideRepository: RideRepository {
    private let db = Firestore.firestore()
    
    func fetchRides(for playgroundId: String) -> Observable<[Ride]> {
        return Observable.create { observer in
            self.db.collection("rides")
                .whereField("pfctSn", isEqualTo: playgroundId)
                .getDocuments { snapshot, error in
                    if let error = error {
                        observer.onError(error)
                        return
                    }
                    
                    let rides = snapshot?.documents.compactMap { document -> Ride? in
                        guard
                            let pfctNm = document.data()["pfctNm"] as? String,
                            let rideNm = document.data()["rideNm"] as? String,
                            let pfctSn = document.data()["pfctSn"] as? String
                        else { return nil }
                        
                        return Ride(
                            rideSn: document.documentID,
                            pfctNm: pfctNm,
                            rideNm: rideNm,
                            pfctSn: pfctSn
                        )
                    } ?? []
                    
                    observer.onNext(rides)
                    observer.onCompleted()
                }
            
            return Disposables.create()
        }
    }
}
