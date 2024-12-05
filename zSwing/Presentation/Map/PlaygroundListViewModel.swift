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
    private let locationService: LocationServiceType
    private let disposeBag = DisposeBag()
    
    // MARK: - Inputs
    let viewDidLoad = PublishRelay<Void>()
    let categorySelected = BehaviorRelay<Set<String>>(value: ["전체"])
    let regionChanged = PublishRelay<MapRegion>()
    
    // MARK: - Outputs
    let playgrounds = BehaviorRelay<[PlaygroundWithDistance]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    let error = PublishRelay<Error>()
    let locationTitle = BehaviorRelay<String>(value: "")
    
    private let currentRegion = BehaviorRelay<MapRegion>(value: MapRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    ))
    
    // MARK: - Initialization
    init(
        playgroundUseCase: PlaygroundListUseCase,
        locationService: LocationServiceType = LocationService()
    ) {
        self.playgroundUseCase = playgroundUseCase
        self.locationService = locationService
        
        bind()
    }
    
    private func bind() {
        // 위치 권한 상태 감시
        locationService.authorizationStatus
            .subscribe(onNext: { [weak self] status in
                switch status {
                case .denied, .restricted:
                    self?.error.accept(NSError(
                        domain: "Location",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "위치 권한이 필요합니다."]
                    ))
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
        
        // 위치 기반 초기 데이터 로딩
        let locationBasedRegion = locationService.currentLocation
            .map { location in
                MapRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
            }
        
        Observable.merge(
            locationBasedRegion,
            regionChanged.asObservable()
        )
        .do(onNext: { [weak self] region in
            self?.isLoading.accept(true)
            self?.currentRegion.accept(region)
        })
        .withLatestFrom(locationService.currentLocation) { ($0, $1) }
        .flatMapLatest { [weak self] (region, location) -> Observable<[PlaygroundWithDistance]> in
            guard let self = self else { return .empty() }
            return self.playgroundUseCase.fetchPlaygrounds(in: region)
                .map { playgrounds in
                    // 거리 계산 및 정렬
                    playgrounds.map { playground in
                        let distance = self.calculateDistanceSync(
                            from: location,
                            to: playground.coordinate
                        )
                        return PlaygroundWithDistance(playground: playground, distance: distance)
                    }
                    .sorted { $0.distance ?? .infinity < $1.distance ?? .infinity } // 거리순 정렬 추가
                }
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
        
        // 카테고리 필터링도 정렬 로직 추가
        categorySelected
            .skip(1)
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
            })
            .withLatestFrom(Observable.combineLatest(
                categorySelected,
                currentRegion,
                locationService.currentLocation
            ))
            .flatMapLatest { [weak self] (categories, region, location) -> Observable<[PlaygroundWithDistance]> in
                guard let self = self else { return .empty() }
                return self.playgroundUseCase.filterPlaygrounds(by: categories, in: region)
                    .map { playgrounds in
                        playgrounds.map { playground in
                            let distance = self.calculateDistanceSync(
                                from: location,
                                to: playground.coordinate
                            )
                            return PlaygroundWithDistance(playground: playground, distance: distance)
                        }
                        .sorted { $0.distance ?? .infinity < $1.distance ?? .infinity } // 거리순 정렬 추가
                    }
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
        locationService.currentLocation
            .subscribe(onNext: { [weak self] location in
                self?.updateLocationTitle(for: location)
            })
            .disposed(by: disposeBag)
        
        // 초기 위치 권한 요청
        viewDidLoad
            .subscribe(onNext: { [weak self] _ in
                self?.locationService.requestLocationAuthorization()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    private func calculateDistanceSync(from location: CLLocation, to coordinate: CLLocationCoordinate2D) -> Double {
        let playgroundLocation = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return location.distance(from: playgroundLocation) / 1000.0
    }
    
    private func updateLocationTitle(for location: CLLocation) {
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
    func calculateDistance(for playground: Playground) -> Observable<Double> {
        return locationService.currentLocation
            .map { userLocation -> Double in
                let playgroundLocation = CLLocation(
                    latitude: playground.coordinate.latitude,
                    longitude: playground.coordinate.longitude
                )
                return userLocation.distance(from: playgroundLocation) / 1000.0
            }
            .take(1)
    }
}

struct PlaygroundWithDistance {
    let playground: Playground
    let distance: Double?
}
