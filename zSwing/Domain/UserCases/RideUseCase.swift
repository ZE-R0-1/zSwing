//
//  RideUseCase.swift
//  zSwing
//
//  Created by USER on 11/15/24.
//

import Foundation
import RxSwift

protocol RideUseCase {
    func fetchRides(for playgroundId: String) -> Observable<[Ride]>
}

class DefaultRideUseCase: RideUseCase {
    private let repository: RideRepository
    
    init(repository: RideRepository) {
        self.repository = repository
    }
    
    func fetchRides(for playgroundId: String) -> Observable<[Ride]> {
        return repository.fetchRides(for: playgroundId)
    }
}
