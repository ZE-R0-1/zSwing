//
//  PlaygroundListViewModel.swift
//  zSwing
//
//  Created by USER on 12/4/24.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

final class PlaygroundListViewModel {
    // MARK: - Properties
    private let playgroundUseCase: PlaygroundListUseCase
    private let locationManager = CLLocationManager()
    private let disposeBag = DisposeBag()
    
    // MARK: - Inputs
    let viewDidLoad = PublishRelay<Void>()
    let categorySelected = BehaviorRelay<Set<String>>(value: ["전체"])
    let refreshTrigger = PublishRelay<Void>()
    
    // MARK: - Outputs
    let playgrounds = BehaviorRelay<[Playground]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    let error = PublishRelay<Error>()
    let locationTitle = BehaviorRelay<String>(value: "")
    
    // MARK: - Initialization
    init(playgroundUseCase: PlaygroundListUseCase) {
        self.playgroundUseCase = playgroundUseCase
        bind()
    }
    
    private func bind() {
        // 초기 로딩 및 새로고침
        let loadTrigger = Observable.merge(
            viewDidLoad.asObservable(),
            refreshTrigger.asObservable()
        )
        
        loadTrigger
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
            })
            .flatMapLatest { [weak self] _ -> Observable<[Playground]> in
                guard let self = self else { return .empty() }
                return self.playgroundUseCase.fetchPlaygrounds()
                    .catch { error in
                        self.error.accept(error)
                        return .empty()
                    }
            }
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(false)
            })
            .bind(to: playgrounds)
            .disposed(by: disposeBag)
        
        // 카테고리 필터링
        categorySelected
            .skip(1) // 초기값 스킵
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
            })
            .flatMapLatest { [weak self] categories -> Observable<[Playground]> in
                guard let self = self else { return .empty() }
                return self.playgroundUseCase.filterPlaygrounds(by: categories)
                    .catch { error in
                        self.error.accept(error)
                        return .empty()
                    }
            }
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(false)
            })
            .bind(to: playgrounds)
            .disposed(by: disposeBag)
        
        // 위치 정보 업데이트
        updateLocationTitle()
    }
    
    // MARK: - Private Methods
    private func updateLocationTitle() {
        guard let location = locationManager.location else {
            locationTitle.accept("위치 정보 없음")
            return
        }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                print("Geocoding error: \(error)")
                self?.locationTitle.accept("위치 정보 오류")
                return
            }
            
            if let district = placemarks?.first?.subLocality {
                self?.locationTitle.accept(district)
            } else {
                self?.locationTitle.accept("알 수 없는 위치")
            }
        }
    }
    
    // MARK: - Public Methods
    func calculateDistance(for playground: Playground) -> Double? {
        guard let userLocation = locationManager.location else { return nil }
        
        let playgroundLocation = CLLocation(
            latitude: playground.coordinate.latitude,
            longitude: playground.coordinate.longitude
        )
        return userLocation.distance(from: playgroundLocation) / 1000.0 // km로 변환
    }
}
