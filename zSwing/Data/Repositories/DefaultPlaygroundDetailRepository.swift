//
//  DefaultPlaygroundDetailRepository.swift
//  zSwing
//
//  Created by USER on 12/16/24.
//

import RxSwift
import Firebase

final class DefaultPlaygroundDetailRepository: PlaygroundDetailRepository {
    private let firestore: Firestore
    
    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }
    
    func getPlaygroundDetail(id: String) -> Observable<PlaygroundDetailDTO> {
        return Observable.create { observer in
            let docRef = self.firestore.collection("playgrounds").document(id)
            
            docRef.getDocument { snapshot, error in
                if let error = error {
                    print("❌ Error fetching playground detail:", error)
                    observer.onError(error)
                    return
                }
                
                let address = snapshot?.data()?["ronaAddr"] as? String ?? ""
                let detail = PlaygroundDetailDTO(address: address)
                observer.onNext(detail)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
}
