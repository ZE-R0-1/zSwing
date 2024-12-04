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
    private let disposeBag = DisposeBag()
    
    // MARK: - Inputs
    let viewDidLoad = PublishRelay<Void>()
    let locationButtonTapped = PublishRelay<Void>()
    let regionDidChange = PublishRelay<MKCoordinateRegion>()
    let searchButtonTapped = PublishRelay<Void>()
    let categoriesSelected = PublishRelay<Set<String>>()
    
    // MARK: - Outputs
    let currentLocation = BehaviorRelay<Location>(value: .defaultLocation)
    let locationTitle = BehaviorRelay<String>(value: "")
    let error = PublishRelay<Error>()
    let isLoading = BehaviorRelay<Bool>(value: false)
    let shouldShowSearchButton = BehaviorRelay<Bool>(value: false)
    let shouldShowBottomSheet = BehaviorRelay<Bool>(value: true)
    let navigationRequest = PublishRelay<MapNavigationRequest>()
    
    // 기존 playgrounds 관련 프로퍼티들 유지
    private let allPlaygrounds = BehaviorRelay<[Playground]>(value: [])
    private let filteredPlaygrounds = BehaviorRelay<[Playground]>(value: [])
    
    var playgrounds: BehaviorRelay<[Playground]> {
        return filteredPlaygrounds
    }
    
    enum MapNavigationRequest {
        case showPlaygroundDetail(Playground)
        case showPlaygroundList
        case showSearchResult
    }

    // MARK: - Initialization
    init(useCase: MapUseCase, playgroundUseCase: PlaygroundUseCase) {
        self.useCase = useCase
        self.playgroundUseCase = playgroundUseCase
        setupBindings()
    }

    // 클러스터의 놀이터들만 표시하도록 필터링
    func filterPlaygrounds(_ clusterPlaygrounds: [Playground]) {
        filteredPlaygrounds.accept(clusterPlaygrounds)
    }
    
    // 필터 초기화 (전체 놀이터 표시)
    func resetPlaygroundFilter() {
        filteredPlaygrounds.accept(allPlaygrounds.value)
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
        
        // 검색 버튼 탭 - 데이터 로드 및 위치 정보 업데이트
        searchButtonTapped
            .withLatestFrom(regionDidChange)
            .do(onNext: { [weak self] region in
                self?.isLoading.accept(true)
                self?.shouldShowSearchButton.accept(false)
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
                self?.isLoading.accept(false)
                self?.shouldShowBottomSheet.accept(!playgrounds.isEmpty)
            })
            .subscribe(onNext: { [weak self] playgrounds in
                self?.allPlaygrounds.accept(playgrounds)
                self?.filteredPlaygrounds.accept(playgrounds)
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
        
        // 카테고리 선택에 따른 필터링
        categoriesSelected
            .withLatestFrom(allPlaygrounds) { (selectedCategories, playgrounds) -> [Playground] in
                // "전체" 카테고리가 선택된 경우 모든 놀이터 표시
                guard !selectedCategories.contains("전체") else {
                    return playgrounds
                }
                return []  // 현재는 실내/실외 필터링이 구현되지 않았으므로 빈 배열 반환
            }
            .bind(to: playgrounds)
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
                let components = [
                    placemark.locality,     // 시
                    placemark.subLocality,           // 동
                    placemark.thoroughfare,          // 도로명
                ]
                
                let address = components
                    .compactMap { $0 }
                    .joined(separator: " ")
                
                self?.locationTitle.accept(address)
            }
        }
    }
}
