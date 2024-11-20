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
    let categoriesSelected = PublishRelay<Set<String>>()
    
    // MARK: - Outputs
    let currentLocation = BehaviorRelay<MapLocation>(value: .defaultLocation)
    let locationTitle = BehaviorRelay<String>(value: "")
    let error = PublishRelay<Error>()
    let isLoading = BehaviorRelay<Bool>(value: false)
    let playgrounds = BehaviorRelay<[Playground]>(value: [])
    let categories = BehaviorRelay<[CategoryInfo]>(value: [])
    let shouldShowSearchButton = BehaviorRelay<Bool>(value: false)
    let shouldShowBottomSheet = BehaviorRelay<Bool>(value: true)
    
    // MARK: - Private Properties
    private let allPlaygrounds = BehaviorRelay<[Playground]>(value: [])
    private let ridesByPlayground = BehaviorRelay<[String: [Ride]]>(value: [:])  // 놀이터별 놀이기구 데이터 저장

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
                    // 지도 이동만 수행
                    self?.currentLocation.accept(location)
                    // 첫 로드시에만 검색 수행
                    self?.searchButtonTapped.accept(())
                }
                self?.isLoading.accept(false)
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        // 위치 버튼 탭 - 지도 이동만
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
                }
            })
            .disposed(by: disposeBag)
        
        // 검색 버튼 탭 - 데이터 로드 및 위치 정보 업데이트
        searchButtonTapped
            .withLatestFrom(regionDidChange)
            .do(onNext: { [weak self] region in
                self?.isLoading.accept(true)
                self?.shouldShowSearchButton.accept(false)
                // 검색 시에만 위치 정보 업데이트
                self?.updateLocationTitle(
                    latitude: region.center.latitude,
                    longitude: region.center.longitude
                )
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
        
        // 지도 영역 변경시 검색 버튼 표시
        regionDidChange
            .skip(2)
            .withLatestFrom(isLoading) { (region, isLoading) in
                return !isLoading
            }
            .bind(to: shouldShowSearchButton)
            .disposed(by: disposeBag)
        
        // 카테고리 선택에 따른 필터링 로직 수정
        categoriesSelected
            .withLatestFrom(Observable.combineLatest(
                allPlaygrounds,
                ridesByPlayground
            )) { (selectedCategories, combined) -> [Playground] in
                let (playgrounds, ridesByPfctSn) = combined
                
                // "전체" 카테고리가 선택된 경우 모든 놀이터 표시
                guard !selectedCategories.contains("전체") else {
                    return playgrounds
                }
                
                // 선택된 카테고리의 놀이기구가 있는 놀이터만 필터링
                return playgrounds.filter { playground in
                    guard let rides = ridesByPfctSn[playground.pfctSn] else {
                        return false
                    }
                    
                    // 놀이터가 가진 놀이기구 중 하나라도 선택된 카테고리에 포함되는지 확인
                    return rides.contains { ride in
                        selectedCategories.contains(ride.rideNm)
                    }
                }
            }
            .bind(to: playgrounds)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    private func loadRideCategories(for playgrounds: [Playground]) {
        var ridesByPlaygroundDict: [String: [Ride]] = [:]
        var categoryCountMap: [String: Int] = [:]  // 카테고리별 수량 저장
        
        Observable.from(playgrounds)
            .flatMap { [weak self] playground -> Observable<[Ride]> in
                guard let self = self else { return .empty() }
                return self.rideUseCase.fetchRides(for: playground.pfctSn)
                    .do(onNext: { rides in
                        ridesByPlaygroundDict[playground.pfctSn] = rides
                        // 각 카테고리별 수량 계산
                        rides.forEach { ride in
                            categoryCountMap[ride.rideNm, default: 0] += 1
                        }
                    })
            }
            .map { _ in categoryCountMap }
            .map { countMap -> [CategoryInfo] in
                // "전체" 카테고리 추가
                let totalCount = ridesByPlaygroundDict.values.reduce(0) { $0 + $1.count }
                var categoryInfos = [CategoryInfo(name: "전체", count: totalCount)]
                
                // 나머지 카테고리 정보 추가
                categoryInfos.append(contentsOf: countMap.map {
                    CategoryInfo(name: $0.key, count: $0.value)
                }.sorted { $0.name < $1.name })
                
                return categoryInfos
            }
            .do(onNext: { [weak self] _ in
                self?.ridesByPlayground.accept(ridesByPlaygroundDict)
            })
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
