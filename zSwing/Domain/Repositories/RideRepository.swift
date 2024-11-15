//
//  RideRepository.swift
//  zSwing
//
//  Created by USER on 11/15/24.
//

import RxSwift

protocol RideRepository {
    func fetchRides(for playgroundId: String) -> Observable<[Ride]>
}
