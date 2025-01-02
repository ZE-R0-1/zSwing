//
//  PlaygroundListViewModel.swift
//  zSwing
//
//  Created by USER on 12/4/24.
//

import Foundation
import RxSwift
import RxCocoa
import RxCoreLocation
import CoreLocation
import MapKit

final class PlaygroundListViewModel {
    // MARK: - Properties
    private let playgroundUseCase: PlaygroundListUseCase
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let disposeBag = DisposeBag()
    private let searchSubject = PublishSubject<MapRegion>()
    private let originalPlaygrounds = BehaviorRelay<[PlaygroundWithDistance]>(value: [])
    private let reviewRepository: ReviewRepository
    
    // MARK: - Inputs
    let viewDidLoad = PublishRelay<Void>()
    let categorySelected = BehaviorRelay<PlaygroundType>(value: .all)
    let searchButtonTapped = PublishRelay<MapRegion>()
    
    // MARK: - Outputs
    let playgrounds = BehaviorRelay<[PlaygroundWithDistance]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    let error = PublishRelay<Error>()
    let locationTitle = BehaviorRelay<String>(value: "")
    
    init(playgroundUseCase: PlaygroundListUseCase, reviewRepository: ReviewRepository = DefaultReviewRepository()) {
        self.playgroundUseCase = playgroundUseCase
        self.reviewRepository = reviewRepository
        bind()
    }
    
    private func bind() {
        // 검색 버튼 처리를 별도 메서드로 분리
        bindSearchButton()
        // 카테고리 변경 처리를 별도 메서드로 분리
        bindCategoryChanges()
    }
    
    private func bindSearchButton() {
        searchButtonTapped
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .do(onNext: { [weak self] region in
                print("📱 [PlaygroundList] Search initiated for region")
                self?.updateLocationTitle(for: region.center)
                self?.isLoading.accept(true)
            })
            .withLatestFrom(categorySelected) { (region: $0, category: $1) }
            .do(onNext: { params in
                print("🏷️ [Category] Using filter: \(params.category.rawValue)")
            })
            .flatMapLatest { [weak self] params in
                self?.fetchPlaygroundWithReviews(region: params.region, category: params.category) ?? .empty()
            }
            .do(onNext: { [weak self] playgrounds in
                print("✅ [Result] Received \(playgrounds.count) playgrounds")
                self?.isLoading.accept(false)
                // 검색 결과를 원본 데이터로 저장
                self?.originalPlaygrounds.accept(playgrounds)
                // 현재 선택된 카테고리로 필터링
                self?.filterPlaygrounds()
            })
            .catch { [weak self] error in
                self?.error.accept(error)
                return .empty()
            }
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func bindCategoryChanges() {
        categorySelected
            .skip(1)
            .do(onNext: { [weak self] category in
                print("🔄 Category changed to: \(category.rawValue)")
                self?.isLoading.accept(true)
            })
            .subscribe(onNext: { [weak self] _ in
                self?.filterPlaygrounds()
                self?.isLoading.accept(false)
            })
            .disposed(by: disposeBag)
    }

    private func filterPlaygrounds() {
        let currentCategory = categorySelected.value
        let filtered = originalPlaygrounds.value.filter { playground in
            if currentCategory == .all {
                return true
            }
            return playground.playground.idrodrCdNm == currentCategory.rawValue
        }
        playgrounds.accept(filtered)
    }
    
    private func fetchPlaygroundWithReviews(region: MapRegion, category: PlaygroundType) -> Observable<[PlaygroundWithDistance]> {
        let currentLocation = CLLocation(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        
        // 1. 먼저 필터링된 놀이터들을 가져옵니다
        return playgroundUseCase
            .fetchFilteredPlaygrounds(
                categories: Set([category.rawValue]),
                in: region
            )
            .flatMap { [weak self] playgrounds -> Observable<[Playground]> in
                guard let self = self else { return .empty() }
                // 각 놀이터의 리뷰를 가져옴
                let reviewObservables = playgrounds.map { playground -> Observable<Playground> in
                    return self.reviewRepository.fetchReviews(
                        playgroundId: playground.pfctSn,
                        sortBy: .latest,
                        page: 0,
                        pageSize: 10
                    ).map { reviews in
                        var updatedPlayground = playground
                        updatedPlayground.reviews = reviews
                        return updatedPlayground
                    }
                }
                return Observable.zip(reviewObservables)
            }
            // 2. 거리 계산과 정렬을 별도의 메서드로 분리합니다
            .map { [weak self] playgrounds in
                self?.calculateDistances(playgrounds: playgrounds, from: currentLocation) ?? []
            }
    }

    // 거리 계산과 정렬을 담당하는 별도의 메서드
    private func calculateDistances(playgrounds: [Playground], from location: CLLocation) -> [PlaygroundWithDistance] {
        return playgrounds
            .map { playground in
                let playgroundLocation = CLLocation(
                    latitude: playground.coordinate.latitude,
                    longitude: playground.coordinate.longitude
                )
                let distance = location.distance(from: playgroundLocation) / 1000.0
                return PlaygroundWithDistance(
                    playground: playground,
                    distance: distance
                )
            }
            .sorted { $0.distance ?? .infinity < $1.distance ?? .infinity }
    }
    
    private func updateLocationTitle(for coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                print("Geocoding error: \(error)")
                self?.locationTitle.accept("위치 정보 오류")
                return
            }
            
            if let locality = placemarks?.first?.locality,
               let subLocality = placemarks?.first?.subLocality {
                self?.locationTitle.accept("\(locality) \(subLocality)")
            } else if let locality = placemarks?.first?.locality {
                self?.locationTitle.accept(locality)
            } else if let subLocality = placemarks?.first?.subLocality {
                self?.locationTitle.accept(subLocality)
            } else {
                self?.locationTitle.accept("알 수 없는 위치")
            }
        }
    }
}
