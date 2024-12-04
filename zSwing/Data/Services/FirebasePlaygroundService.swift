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
    func fetchPlaygrounds() -> Observable<[Playground]>
    func fetchPlayground(pfctSn: String) -> Observable<Playground>
}

class FirebasePlaygroundService: FirebasePlaygroundServiceProtocol {
    private let firestore: Firestore
    
    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
        print("Initializing FirebasePlaygroundService")
    }
    
    func fetchPlaygrounds() -> Observable<[Playground]> {
        return Observable.create { [weak self] observer in
            self?.firestore.collection("playgrounds")
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Firestore Error: \(error)")
                        observer.onError(error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("No documents found")
                        observer.onNext([])
                        observer.onCompleted()
                        return
                    }
                    
                    let playgrounds = documents.compactMap { document in
                        let data = document.data()
                        
                        let playgroundDTO = PlaygroundDTO(
                            pfctSn: document.documentID,
                            pfctNm: data["pfctNm"] as? String ?? "",
                            latCrtsVl: data["latCrtsVl"] as? Double ?? 0.0,
                            lotCrtsVl: data["lotCrtsVl"] as? Double ?? 0.0
                        )
                        return playgroundDTO.toDomain()
                    }
                    
                    print("Successfully fetched \(playgrounds.count) playgrounds")
                    observer.onNext(playgrounds)
                    observer.onCompleted()
                }
            
            return Disposables.create()
        }
    }
    
    func fetchPlayground(pfctSn: String) -> Observable<Playground> {
        return Observable.create { [weak self] observer in
            self?.firestore.collection("playgrounds").document(pfctSn)
                .getDocument { document, error in
                    if let error = error {
                        print("Firestore Error: \(error)")
                        observer.onError(error)
                        return
                    }
                    
                    guard let document = document,
                          document.exists,
                          let data = document.data() else {
                        print("No playground found with pfctSn: \(pfctSn)")
                        observer.onError(NSError(
                            domain: "",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Playground not found"])
                        )
                        return
                    }
                    
                    let playgroundDTO = PlaygroundDTO(
                        pfctSn: document.documentID,
                        pfctNm: data["pfctNm"] as? String ?? "",
                        latCrtsVl: data["latCrtsVl"] as? Double ?? 0.0,
                        lotCrtsVl: data["lotCrtsVl"] as? Double ?? 0.0
                    )
                    
                    observer.onNext(playgroundDTO.toDomain())
                    observer.onCompleted()
                }
            
            return Disposables.create()
        }
    }
}
