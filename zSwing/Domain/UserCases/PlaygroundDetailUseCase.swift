//
//  PlaygroundDetailUseCase.swift
//  zSwing
//
//  Created by USER on 12/16/24.
//

import RxSwift

protocol PlaygroundDetailUseCase {
    func getPlaygroundDetail(id: String) -> Observable<PlaygroundDetail>
}

final class DefaultPlaygroundDetailUseCase: PlaygroundDetailUseCase {
    private let playgroundRepository: PlaygroundDetailRepository
    private let favoriteRepository: FavoriteRepository
    private let reviewRepository: ReviewRepository
    
    init(
        playgroundRepository: PlaygroundDetailRepository,
        favoriteRepository: FavoriteRepository,
        reviewRepository: ReviewRepository
    ) {
        self.playgroundRepository = playgroundRepository
        self.favoriteRepository = favoriteRepository
        self.reviewRepository = reviewRepository
    }
    
    func getPlaygroundDetail(id: String) -> Observable<PlaygroundDetail> {
        // 동시에 여러 데이터를 가져와서 결합
        return Observable.combineLatest(
            playgroundRepository.getPlaygroundDetail(id: id),
            favoriteRepository.isFavorite(playgroundId: id),
            reviewRepository.getReviews(playgroundId: id)
        ).map { detail, isFavorite, reviews in
            PlaygroundDetail(
                address: detail.address,
                isFavorite: isFavorite,
                reviews: reviews
            )
        }
    }
}
