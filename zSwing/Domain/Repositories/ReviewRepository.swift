//
//  ReviewRepository.swift
//  zSwing
//
//  Created by USER on 12/16/24.
//

import RxSwift

enum ReviewSortOption {
    case latest
    case rating
}

protocol ReviewRepository {
    func createReview(review: Review) -> Observable<Void>
    func fetchReviews(
        playgroundId: String,
        sortBy: ReviewSortOption,
        page: Int,
        pageSize: Int
    ) -> Observable<[Review]>
    func updateReview(review: Review) -> Observable<Void>
    func deleteReview(reviewId: String) -> Observable<Void>
    func toggleLike(reviewId: String) -> Observable<Bool>
}
