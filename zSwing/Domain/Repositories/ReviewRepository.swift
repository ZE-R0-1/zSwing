//
//  ReviewRepository.swift
//  zSwing
//
//  Created by USER on 12/16/24.
//

import RxSwift

protocol ReviewRepository {
    func getReviews(playgroundId: String) -> Observable<[PlaygroundReview]>
    func writeReview(playgroundId: String, review: PlaygroundReview) -> Observable<Void>
}
