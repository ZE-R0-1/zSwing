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
                    observer.onError(error)
                    return
                }
                
                guard let data = snapshot?.data(),
                      let address = data["address"] as? String else {
                    observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid data"]))
                    return
                }
                
                let detail = PlaygroundDetailDTO(address: address)
                observer.onNext(detail)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
}
