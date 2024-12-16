//
//  PlaygroundViewModel.swift
//  zSwing
//
//  Created by USER on 12/13/24.
//

import RxSwift
import RxRelay
import CoreLocation

class PlaygroundViewModel {
    // MARK: - Inputs
    let viewDidLoad = PublishRelay<Void>()
    let favoriteButtonTapped = PublishRelay<Void>()
    let writeReviewButtonTapped = PublishRelay<Void>()
    let showAllReviewsButtonTapped = PublishRelay<Void>()
    
    // MARK: - Outputs
    let pfctNm = BehaviorRelay<String>(value: "?")
    let address = BehaviorRelay<String>(value: "?")
    let distance = BehaviorRelay<String>(value: "?")
    let isFavorite = BehaviorRelay<Bool>(value: false)
    let reviews = BehaviorRelay<[PlaygroundReview]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    let error = PublishRelay<Error>()
    
    // MARK: - Dependencies
    private let playgroundDetailUseCase: PlaygroundDetailUseCase
    private let favoriteUseCase: FavoriteUseCase
    private let reviewUseCase: ReviewUseCase
    private let disposeBag = DisposeBag()
    
    // MARK: - Properties
    private let playground: Playground
    private let currentLocation: CLLocation?
    
    init(
        playground: Playground,
        currentLocation: CLLocation?,
        playgroundDetailUseCase: PlaygroundDetailUseCase,
        favoriteUseCase: FavoriteUseCase,
        reviewUseCase: ReviewUseCase
    ) {
        self.playground = playground
        self.currentLocation = currentLocation
        self.playgroundDetailUseCase = playgroundDetailUseCase
        self.favoriteUseCase = favoriteUseCase
        self.reviewUseCase = reviewUseCase
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Initial data load
        viewDidLoad
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
            })
            .flatMapLatest { [weak self] _ -> Observable<PlaygroundDetail> in
                guard let self = self else { return .empty() }
                return self.playgroundDetailUseCase.getPlaygroundDetail(id: self.playground.pfctSn)
            }
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(false)
            })
            .subscribe(onNext: { [weak self] detail in
                self?.updatePlaygroundDetail(detail)
            }, onError: { [weak self] error in
                self?.error.accept(error)
            })
            .disposed(by: disposeBag)
        
        // Favorite toggle
        favoriteButtonTapped
            .flatMapLatest { [weak self] _ -> Observable<Bool> in
                guard let self = self else { return .empty() }
                return self.favoriteUseCase.toggleFavorite(playgroundId: self.playground.pfctSn)
            }
            .bind(to: isFavorite)
            .disposed(by: disposeBag)
    }
    
    private func updatePlaygroundDetail(_ detail: PlaygroundDetail) {
        pfctNm.accept(playground.pfctNm)
        address.accept(detail.address)
        
        if let currentLocation = currentLocation {
            let playgroundLocation = CLLocation(
                latitude: playground.coordinate.latitude,
                longitude: playground.coordinate.longitude
            )
            let distanceInKm = currentLocation.distance(from: playgroundLocation) / 1000.0
            distance.accept(String(format: "%.1fkm", distanceInKm))
        }
        
        isFavorite.accept(detail.isFavorite)
        reviews.accept(detail.reviews)
    }
}


// MARK: - Supporting Types
struct PlaygroundDetail {
    let address: String
    let isFavorite: Bool
    let reviews: [PlaygroundReview]
}

struct PlaygroundReview {
    let id: String
    let imageUrl: String
    let createdAt: Date
}
