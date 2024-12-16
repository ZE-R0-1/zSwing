//
//  ReviewUseCase.swift
//  zSwing
//
//  Created by USER on 12/16/24.
//

import RxSwift

protocol ReviewUseCase {
    func getReviews(playgroundId: String) -> Observable<[PlaygroundReview]>
    func writeReview(playgroundId: String, review: PlaygroundReview) -> Observable<Void>
}

final class DefaultReviewUseCase: ReviewUseCase {
    private let reviewRepository: ReviewRepository
    
    init(reviewRepository: ReviewRepository) {
        self.reviewRepository = reviewRepository
    }
    
    func getReviews(playgroundId: String) -> Observable<[PlaygroundReview]> {
        return reviewRepository.getReviews(playgroundId: playgroundId)
    }
    
    func writeReview(playgroundId: String, review: PlaygroundReview) -> Observable<Void> {
        return reviewRepository.writeReview(playgroundId: playgroundId, review: review)
    }
}
