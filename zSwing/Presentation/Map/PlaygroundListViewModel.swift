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
    private let locationManager = CLLocationManager()  // 위치 매니저 추가
    private let geocoder = CLGeocoder()
    private let disposeBag = DisposeBag()
    
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
        // 검색 버튼 탭과 카테고리 선택을 결합
        Observable.combineLatest(
            searchButtonTapped,
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
            
            let playgroundsObservable: Observable<[Playground]>
            if categories.contains("전체") {
                playgroundsObservable = self.playgroundUseCase.fetchPlaygrounds(in: region)
            } else {
                playgroundsObservable = self.playgroundUseCase.filterPlaygrounds(by: categories, in: region)
            }
            
            return playgroundsObservable.map { playgrounds in
                playgrounds.map { playground in
                    let distance = self.calculateDistance(
                        from: currentLocation,
                        to: playground.coordinate
                    )
                    return PlaygroundWithDistance(playground: playground, distance: distance)
                }
                .sorted { $0.distance ?? .infinity < $1.distance ?? .infinity }  // 거리순 정렬
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
        searchButtonTapped
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
    
    private func calculateDistance(from location: CLLocation, to coordinate: CLLocationCoordinate2D) -> Double {
        let playgroundLocation = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return location.distance(from: playgroundLocation) / 1000.0  // 킬로미터 단위로 변환
    }
}

struct PlaygroundWithDistance {
    let playground: Playground
    let distance: Double?
}
