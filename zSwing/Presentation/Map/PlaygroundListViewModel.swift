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
    
    // MARK: - Inputs
    let viewDidLoad = PublishRelay<Void>()
    let categorySelected = BehaviorRelay<Set<String>>(value: ["전체"])
    let searchButtonTapped = PublishRelay<MapRegion>()
    
    // MARK: - Outputs
    let playgrounds = BehaviorRelay<[PlaygroundWithDistance]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    let error = PublishRelay<Error>()
    let locationTitle = BehaviorRelay<String>(value: "")
    
    init(playgroundUseCase: PlaygroundListUseCase) {
        self.playgroundUseCase = playgroundUseCase
        bind()
    }
    
    private func bind() {
        // 검색 이벤트 처리
        searchButtonTapped
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .bind(to: searchSubject)
            .disposed(by: disposeBag)
            
        // 검색과 카테고리 결합 처리
        Observable.combineLatest(
            searchSubject,
            categorySelected
        )
        .do(onNext: { [weak self] _ in
            self?.isLoading.accept(true)
        })
        .flatMapLatest { [weak self] (region, categories) -> Observable<[PlaygroundWithDistance]> in
            guard let self = self else { return .empty() }
            
            let currentLocation = CLLocation(
                latitude: region.center.latitude,
                longitude: region.center.longitude
            )
            
            return self.playgroundUseCase
                .fetchPlaygrounds(in: region)
                .map { playgrounds in
                    playgrounds
                        .filter { playground in
                            if categories.contains("전체") { return true }
                            // TODO: 카테고리 필터링 로직 구현
                            return true
                        }
                        .map { playground in
                            let distance = currentLocation.distance(
                                from: CLLocation(
                                    latitude: playground.coordinate.latitude,
                                    longitude: playground.coordinate.longitude
                                )
                            ) / 1000.0
                            return PlaygroundWithDistance(
                                playground: playground,
                                distance: distance
                            )
                        }
                        .sorted { $0.distance ?? .infinity < $1.distance ?? .infinity }
                }
                .catch { error in
                    print("Error fetching playgrounds: \(error)")
                    return .empty()
                }
        }
        .do(onNext: { [weak self] _ in
            self?.isLoading.accept(false)
        })
        .catch { [weak self] error in
            self?.error.accept(error)
            return .empty()
        }
        .bind(to: playgrounds)
        .disposed(by: disposeBag)
        
        // 위치 제목 업데이트
        searchSubject
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] region in
                self?.updateLocationTitle(for: region.center)
            })
            .disposed(by: disposeBag)
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

struct PlaygroundWithDistance {
    let playground: Playground
    let distance: Double?
}
