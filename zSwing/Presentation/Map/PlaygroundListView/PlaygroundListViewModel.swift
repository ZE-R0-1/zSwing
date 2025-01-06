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
    
    // 캐시를 위한 properties
    private var cachedRegions: [MapRegion] = []
    private var cachedPlaygrounds: [MapRegion: [PlaygroundWithDistance]] = [:]
    
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
        bindSearchButton()
        bindCategoryChanges()
    }
    
    private func getCachedPlaygrounds(for region: MapRegion) -> [PlaygroundWithDistance]? {
        for cachedRegion in cachedRegions {
            let latDiff = abs(cachedRegion.center.latitude - region.center.latitude)
            let lonDiff = abs(cachedRegion.center.longitude - region.center.longitude)
            let spanLatDiff = abs(cachedRegion.span.latitudeDelta - region.span.latitudeDelta)
            let spanLonDiff = abs(cachedRegion.span.longitudeDelta - region.span.longitudeDelta)
            
            if latDiff < 0.01 && lonDiff < 0.01 &&
                spanLatDiff < 0.01 && spanLonDiff < 0.01 {
                print("🎯 [Cache Hit] Using cached data for region")
                return cachedPlaygrounds[cachedRegion]
            }
        }
        return nil
    }
    
    private func cachePlaygrounds(_ playgrounds: [PlaygroundWithDistance], for region: MapRegion) {
        print("💾 [Cache] Storing data for region")
        cachedRegions.append(region)
        cachedPlaygrounds[region] = playgrounds
    }
    
    private func bindSearchButton() {
        searchButtonTapped
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .do(onNext: { [weak self] region in
                print("📱 [PlaygroundList] Search initiated for region")
                self?.updateLocationTitle(for: region.center)
                self?.isLoading.accept(true)
                // 검색 시작할 때 데이터 초기화
                self?.playgrounds.accept([])
                self?.originalPlaygrounds.accept([])
            })
            .withLatestFrom(categorySelected) { (region: $0, category: $1) }
            .do(onNext: { params in
                print("🏷️ [Category] Using filter: \(params.category.rawValue)")
            })
            .flatMapLatest { [weak self] params -> Observable<[PlaygroundWithDistance]> in
                guard let self = self else { return .empty() }
                
                return self.fetchPlaygroundWithReviews(region: params.region, category: params.category)
                    .do(onNext: { playgrounds in
                        self.cachePlaygrounds(playgrounds, for: params.region)
                    })
            }
            .do(onNext: { playgrounds in
                print("✅ [Result] Received \(playgrounds.count) playgrounds")
            })
            .do(onNext: { [weak self] playgrounds in
                self?.originalPlaygrounds.accept(playgrounds)
                self?.isLoading.accept(false)
            })
            .bind(to: playgrounds)
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
        
        return playgroundUseCase
            .fetchFilteredPlaygrounds(
                categories: Set([category.rawValue]),
                in: region
            )
            .flatMap { [weak self] playgrounds -> Observable<[Playground]> in
                guard let self = self else { return .empty() }
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
            .map { [weak self] playgrounds in
                self?.calculateDistances(playgrounds: playgrounds, from: currentLocation) ?? []
            }
    }
    
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
