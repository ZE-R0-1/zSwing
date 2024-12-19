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
        print("UseCase - Getting playground detail for ID:", id)
        
        // 각 Observable에 디버깅 추가
        let detailObservable = playgroundRepository.getPlaygroundDetail(id: id)
            .do(onNext: { detail in
                print("UseCase - Received playground detail with address:", detail.address)
            })
        
        let favoriteObservable = favoriteRepository.isFavorite(playgroundId: id)
            .do(onNext: { isFavorite in
                print("UseCase - Received favorite status:", isFavorite)
            })
        
        let reviewsObservable = reviewRepository.fetchReviews(
            playgroundId: id,
            sortBy: .latest,
            page: 0,
            pageSize: 10
        ).do(onNext: { reviews in
            print("UseCase - Received reviews count:", reviews.count)
        })
        
        return Observable.combineLatest(
            detailObservable,
            favoriteObservable,
            reviewsObservable
        ).do(onNext: { detail, isFavorite, reviews in
            print("UseCase - Combined data:")
            print("- Address:", detail.address)
            print("- Is Favorite:", isFavorite)
            print("- Reviews count:", reviews.count)
        }).map { detail, isFavorite, reviews in
            PlaygroundDetail(
                address: detail.address,
                isFavorite: isFavorite,
                reviews: reviews
            )
        }
    }
}
