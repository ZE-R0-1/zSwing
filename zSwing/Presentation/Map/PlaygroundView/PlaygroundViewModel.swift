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
    let refreshReviewsTrigger = PublishRelay<Void>()
    
    // MARK: - Outputs
    let pfctNm = BehaviorRelay<String>(value: "?")
    let address = BehaviorRelay<String>(value: "?")
    let distance = BehaviorRelay<String>(value: "?")
    let isFavorite = BehaviorRelay<Bool>(value: false)
    let reviews = BehaviorRelay<[Review]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    let error = PublishRelay<Error>()
    let showReviewWrite = PublishRelay<Playground1>()
    
    // MARK: - Dependencies
    private let playgroundDetailUseCase: PlaygroundDetailUseCase
    private let favoriteUseCase: FavoriteUseCase
    private let reviewUseCase: ReviewUseCase
    private let disposeBag = DisposeBag()
    
    // MARK: - Properties
    private let playground: Playground1
    private let currentLocation: CLLocation?
    
    init(
        playground: Playground1,
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
        
        // 초기값 설정
        self.pfctNm.accept(playground.pfctNm)
        
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
        
        // 리뷰 작성 버튼 탭 처리
        writeReviewButtonTapped
            .map { [weak self] _ -> Playground1 in
                guard let self = self else { fatalError("Self is nil") }
                return self.playground
            }
            .bind(to: showReviewWrite)
            .disposed(by: disposeBag)
        
        // Favorite toggle
        favoriteButtonTapped
            .flatMapLatest { [weak self] _ -> Observable<Bool> in
                guard let self = self else { return .empty() }
                return self.favoriteUseCase.toggleFavorite(playgroundId: self.playground.pfctSn)
            }
            .bind(to: isFavorite)
            .disposed(by: disposeBag)
        
        // 리뷰 새로고침
        refreshReviewsTrigger
            .do(onNext: { _ in
                print("Refresh reviews triggered")
            })
            .flatMapLatest { [weak self] _ -> Observable<PlaygroundDetail> in
                guard let self = self else { return .empty() }
                print("Fetching updated playground detail for ID:", self.playground.pfctSn)
                return self.playgroundDetailUseCase.getPlaygroundDetail(id: self.playground.pfctSn)
            }
            .do(onNext: { detail in
                print("Received updated reviews count:", detail.reviews.count)
            })
            .subscribe(onNext: { [weak self] detail in
                self?.reviews.accept(detail.reviews)
            }, onError: { error in
                print("Error refreshing reviews:", error.localizedDescription)
            })
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
