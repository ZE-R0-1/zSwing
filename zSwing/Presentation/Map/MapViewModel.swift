//
//  MapViewModel.swift
//  zSwing
//
//  Created by USER on 11/12/24.
//

import RxSwift
import RxRelay
import MapKit
import CoreLocation

class MapViewModel {
    // MARK: - Properties
    private let useCase: MapUseCase
    private let playgroundUseCase: PlaygroundListUseCase
    private let disposeBag = DisposeBag()
    private let geocoder = CLGeocoder()
    
    // MARK: - Inputs
    let viewDidLoad = PublishRelay<Void>()
    let locationButtonTapped = PublishRelay<Void>()
    let searchButtonTapped = PublishRelay<MapRegion>()
    let mapRegionDidChange = PublishRelay<MKCoordinateRegion>()
    let initialRegion = PublishRelay<MKCoordinateRegion>()
    
    // MARK: - Outputs
    let currentLocation = BehaviorRelay<Location>(value: .defaultLocation)
    let locationTitle = BehaviorRelay<String>(value: "")
    let error = PublishRelay<Error>()
    let isLoading = BehaviorRelay<Bool>(value: false)
    let shouldShowSearchButton = BehaviorRelay<Bool>(value: false)
    
    // 어노테이션과 목록을 위한 Outputs
    let playgroundAnnotations = BehaviorRelay<[PlaygroundAnnotation]>(value: [])
    let playgroundsForList = BehaviorRelay<[PlaygroundWithDistance]>(value: [])
    
    // MARK: - Initialization
    init(useCase: MapUseCase, playgroundUseCase: PlaygroundListUseCase) {
        self.useCase = useCase
        self.playgroundUseCase = playgroundUseCase
        setupBindings()
    }
    
    private func setupBindings() {
        // 초기 진입 시 위치 권한 처리만 수행
        viewDidLoad
            .take(1)
            .withLatestFrom(initialRegion)
            .flatMapLatest { [weak self] _ -> Observable<Result<Bool, Error>> in
                guard let self = self else { return .empty() }
                return self.useCase.requestLocationPermission()
            }
            .flatMapLatest { [weak self] result -> Observable<Result<Location, Error>> in
                guard let self = self else { return .empty() }
                switch result {
                case .success(true):
                    return self.useCase.getCurrentLocation()
                case .success(false):
                    return .just(.success(.defaultLocation))
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
            .do(onNext: { [weak self] result in
                if case .success(let location) = result {
                    self?.currentLocation.accept(location)
                }
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        // 현재 위치 버튼 탭 처리
        locationButtonTapped
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
            })
            .flatMapLatest { [weak self] _ -> Observable<Result<Location, Error>> in
                guard let self = self else { return .empty() }
                return self.useCase.getCurrentLocation()
            }
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(false)
            })
            .subscribe(onNext: { [weak self] result in
                if case .success(let location) = result {
                    self?.currentLocation.accept(location)
                }
            })
            .disposed(by: disposeBag)
        
        // 지도 이동 시 검색 버튼 표시/숨김 처리
        mapRegionDidChange
            .skip(1)
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged { old, new in
                let latDiff = abs(old.center.latitude - new.center.latitude)
                let lonDiff = abs(old.center.longitude - new.center.longitude)
                let spanLatDiff = abs(old.span.latitudeDelta - new.span.latitudeDelta)
                let spanLonDiff = abs(old.span.longitudeDelta - new.span.longitudeDelta)
                
                return latDiff < 0.01 && lonDiff < 0.01 &&
                spanLatDiff < 0.01 && spanLonDiff < 0.01
            }
            .map { _ in true }
            .bind(to: shouldShowSearchButton)
            .disposed(by: disposeBag)
        
        // 검색 버튼 탭 시 Firebase 데이터 조회 및 데이터 분배
        searchButtonTapped
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
            })
            .do(onNext: { [weak self] region in
                self?.updateLocationTitle(for: region.center)
            })
            .withLatestFrom(currentLocation) { ($0, $1) }
            .flatMapLatest { [weak self] (region, currentLocation) -> Observable<[Playground]> in
                guard let self = self else { return .empty() }
                return self.playgroundUseCase.fetchFilteredPlaygrounds(
                    categories: Set([PlaygroundType.all.rawValue]),
                    in: region
                )
            }
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(false)
            })
            .subscribe(onNext: { [weak self] playgrounds in
                guard let self = self else { return }
                
                // 어노테이션 업데이트
                let annotations = playgrounds.map { PlaygroundAnnotation(playground: $0) }
                self.playgroundAnnotations.accept(annotations)
                
                // 목록 업데이트 (거리 계산 포함)
                let currentLocation = self.currentLocation.value
                let playgroundsWithDistance = playgrounds.map { playground -> PlaygroundWithDistance in
                    let distance = self.calculateDistance(
                        from: currentLocation,
                        to: playground.coordinate
                    )
                    return PlaygroundWithDistance(
                        playground: playground,
                        distance: distance
                    )
                }
                self.playgroundsForList.accept(playgroundsWithDistance)
            })
            .disposed(by: disposeBag)
    }
    
    private func calculateDistance(from location: Location, to coordinate: CLLocationCoordinate2D) -> Double {
        let from = CLLocation(
            latitude: location.latitude,
            longitude: location.longitude
        )
        let to = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        return from.distance(from: to) / 1000.0 // km로 변환
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
