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
    private let playgroundUseCase: PlaygroundUseCase
    private let rideUseCase: RideUseCase
    private let disposeBag = DisposeBag()
    
    // MARK: - Inputs
    let viewDidLoad = PublishRelay<Void>()
    let locationButtonTapped = PublishRelay<Void>()
    let regionDidChange = PublishRelay<MKCoordinateRegion>()
    let searchButtonTapped = PublishRelay<Void>()
    let categorySelected = PublishRelay<String>()
    
    // MARK: - Outputs
    let currentLocation = BehaviorRelay<MapLocation>(value: .defaultLocation)
    let locationTitle = BehaviorRelay<String>(value: "")
    let error = PublishRelay<Error>()
    let isLoading = BehaviorRelay<Bool>(value: false)
    let playgrounds = BehaviorRelay<[Playground]>(value: [])
    let categories = BehaviorRelay<[String]>(value: [])
    let shouldShowSearchButton = BehaviorRelay<Bool>(value: false)
    let shouldShowBottomSheet = BehaviorRelay<Bool>(value: true)
    
    // Private
    private let allPlaygrounds = BehaviorRelay<[Playground]>(value: [])
    private let currentUserLocation = BehaviorRelay<CLLocation?>(value: nil)
    
    init(useCase: MapUseCase, playgroundUseCase: PlaygroundUseCase, rideUseCase: RideUseCase) {
        self.useCase = useCase
        self.playgroundUseCase = playgroundUseCase
        self.rideUseCase = rideUseCase
        setupBindings()
    }
    
    private func setupBindings() {
        // 초기 위치 설정 및 데이터 로드
        viewDidLoad
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
            })
            .flatMapLatest { [weak self] _ -> Observable<Result<Bool, Error>> in
                guard let self = self else { return .empty() }
                return self.useCase.requestLocationPermission()
            }
            .flatMapLatest { [weak self] result -> Observable<Result<MapLocation, Error>> in
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
                    self?.currentUserLocation.accept(CLLocation(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ))
                    self?.updateLocationTitle(latitude: location.latitude, longitude: location.longitude)
                }
            })
            .flatMapLatest { [weak self] result -> Observable<[Playground]> in
                guard let self = self,
                      case .success(let location) = result else { return .empty() }
                
                return self.playgroundUseCase.fetchPlaygroundsNearby(
                    coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    )
                )
                .catch { error -> Observable<[Playground]> in
                    self.error.accept(error)
                    return .just([])
                }
            }
            .do(onNext: { [weak self] playgrounds in
                self?.loadRideCategories(for: playgrounds)
                self?.isLoading.accept(false)
                self?.shouldShowBottomSheet.accept(!playgrounds.isEmpty)
            })
            .subscribe(onNext: { [weak self] playgrounds in
                self?.allPlaygrounds.accept(playgrounds)
                self?.playgrounds.accept(playgrounds)
            })
            .disposed(by: disposeBag)
        
        // 위치 버튼 탭 - 현재 위치로 이동만
        locationButtonTapped
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
            })
            .flatMapLatest { [weak self] _ -> Observable<Result<MapLocation, Error>> in
                guard let self = self else { return .empty() }
                return self.useCase.getCurrentLocation()
            }
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(false)
            })
            .subscribe(onNext: { [weak self] result in
                if case .success(let location) = result {
                    self?.currentLocation.accept(location)
                    self?.currentUserLocation.accept(CLLocation(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ))
                    self?.updateLocationTitle(
                        latitude: location.latitude,
                        longitude: location.longitude
                    )
                }
            })
            .disposed(by: disposeBag)
        
        // 카테고리 선택
        categorySelected
            .withLatestFrom(allPlaygrounds) { (category, playgrounds) -> [Playground] in
                guard category != "전체" else { return playgrounds }
                return playgrounds // TODO: 카테고리에 따른 필터링 로직 구현
            }
            .bind(to: playgrounds)
            .disposed(by: disposeBag)
        
        // 지도 영역 변경
        regionDidChange
            .skip(2)
            .do(onNext: { [weak self] region in
                self?.updateLocationTitle(
                    latitude: region.center.latitude,
                    longitude: region.center.longitude
                )
            })
            .withLatestFrom(isLoading) { (region, isLoading) in
                return !isLoading
            }
            .bind(to: shouldShowSearchButton)
            .disposed(by: disposeBag)
        
        // 검색 버튼 탭
        searchButtonTapped
            .withLatestFrom(regionDidChange)
            .do(onNext: { [weak self] _ in
                self?.isLoading.accept(true)
                self?.shouldShowSearchButton.accept(false)
            })
            .flatMapLatest { [weak self] region -> Observable<[Playground]> in
                guard let self = self else { return .empty() }
                return self.playgroundUseCase.fetchPlaygrounds(in: MapRegion(
                    center: region.center,
                    span: region.span
                ))
                .catch { error -> Observable<[Playground]> in
                    self.error.accept(error)
                    return .just([])
                }
            }
            .do(onNext: { [weak self] playgrounds in
                self?.loadRideCategories(for: playgrounds)
                self?.isLoading.accept(false)
                self?.shouldShowBottomSheet.accept(!playgrounds.isEmpty)
            })
            .subscribe(onNext: { [weak self] playgrounds in
                self?.allPlaygrounds.accept(playgrounds)
                self?.playgrounds.accept(playgrounds)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    private func loadRideCategories(for playgrounds: [Playground]) {
        let uniqueCategories = Set<String>()
        
        // 모든 놀이터의 기구 정보를 가져와서 카테고리 추출
        Observable.from(playgrounds)
            .flatMap { [weak self] playground -> Observable<[Ride]> in
                guard let self = self else { return .empty() }
                return self.rideUseCase.fetchRides(for: playground.pfctSn)
            }
            .map { rides in
                rides.map { $0.rideNm }
            }
            .reduce(uniqueCategories) { categories, rideNames in
                var newCategories = categories
                rideNames.forEach { newCategories.insert($0) }
                return newCategories
            }
            .map { Array($0).sorted() }
            .bind(to: categories)
            .disposed(by: disposeBag)
    }
    
    private func updateLocationTitle(latitude: Double, longitude: Double) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                self?.error.accept(error)
                return
            }
            
            if let placemark = placemarks?.first {
                let address = [
                    placemark.administrativeArea,
                    placemark.locality,
                    placemark.thoroughfare,
                    placemark.subThoroughfare
                ]
                .compactMap { $0 }
                .joined(separator: " ")
                
                self?.locationTitle.accept(address)
            }
        }
    }
}
